# A test script for running a simple preventive SCOPF model considering DC network contingencies, and optimising HVDC Converter droop gains

import PowerModelsACDC as PMACDC
import PowerModels
import JuMP
import Ipopt
import Plots

## Use first one for MA27, check the local path for your HSL library
#ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer)
ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "hsllib" => "/Users/hergun/IpoptMA/lib/libhsl.dylib", "tol" => 1e-4, "linear_solver" => "ma27", "max_iter" => 3000)


file = pkgdir(PMACDC, "test", "data", "case2_dcr.m")


function build_mn_data(file)
    t = 1:168*4
    mp_data = PowerModels.parse_file(file)
    return PowerModels.replicate(mp_data, length(t); global_keys=Set{String}(["source_type", "name", "source_version", "per_unit"]))
end
data = build_mn_data(file)
PMACDC.process_additional_data!(data)

# OPF settings
s = Dict("conv_losses_mp" => true, "objective_components" => ["gen", "load"])


# # Process demand reduction and curtailment data
for (nw, network) in data["nw"]
    for (br, branchdc) in network["branchdc"]
        branchdc["surf_temp_min"] = -273.0
        branchdc["surf_temp_max"] = 70.0
        branchdc["delta_surf_temp_min"] = - 2 * 273.0
        branchdc["delta_surf_temp_max"] =   2 * 273.0

        branchdc["cond_temp_min"] = -273.0
        branchdc["cond_temp_max"] = 70.0
        branchdc["delta_cond_temp_min"] = - 2 * 273.0
        branchdc["delta_cond_temp_max"] =   2 * 273.0

        branchdc["dcr"] = 1 # if zero, this branch does not have DCR!!!!
        branchdc["time_interval"] = 1800.0  # seconds
        branchdc["thermal_resistance_a"] = 0.4 * data["nw"]["1"]["baseMVA"]*1e6 # pu of Km/W
        branchdc["thermal_resistance_b"] = 1.12 * data["nw"]["1"]["baseMVA"]*1e6 # pu of Km /W
        branchdc["thermal_capacitance_a"] = 18000 / (data["nw"]["1"]["baseMVA"]*1e6) # pu of 18000 # J/mK
        branchdc["thermal_capacitance_b"] = 150e3 / (data["nw"]["1"]["baseMVA"]*1e6) # pu of 150e3 # J/mK
        branchdc["ambient_temperature"] = 12 # °C
        branchdc["temperature_coefficient"] = 0.00393 # 1/K
        branchdc["length"] = 300e3 # in meters
        branchdc["initial_conductor_temperature"] = 12 # °C
        branchdc["initial_cable_surface_temperature"] = 12 # °C
    end

    # if parse(Int, nw) > length(data["nw"])/ (4/3)
     network["load"]["1"]["pd"] =  network["load"]["1"]["pd"] * 1.2
    # end
end

# Solve OPF
result = PMACDC.solve_acdcopf_iv(data, PowerModels.IVRPowerModel, ipopt; multinetwork=true, setting=s)


cond_temp = zeros(length(result["solution"]["nw"]))
surf_temp = zeros(length(result["solution"]["nw"]))
power = zeros(length(result["solution"]["nw"]))
for (n, network) in result["solution"]["nw"]
    cond_temp[parse(Int, n)] = network["branchdc"]["1"]["cable_cond_temp"] 
    surf_temp[parse(Int, n)] = network["branchdc"]["1"]["cable_surface_temp"] 
    power[parse(Int, n)] = network["branchdc"]["1"]["pf"] 
end

p = Plots.plot(cond_temp)
Plots.plot!(p, surf_temp)
Plots.plot!(p, power)





# W = 17.5^2 * 0.00078367 / 300e3
# Δt = 3600 

#        Ta = 0.4 * data["nw"]["1"]["baseMVA"]*1e6 # Km/W
#        Tb =  1.12 * data["nw"]["1"]["baseMVA"]*1e6 # Km /W
#        Ca=18000 / (data["nw"]["1"]["baseMVA"]*1e6) # pu of 18000 # J/mK
#        Cb= 150e3 / (data["nw"]["1"]["baseMVA"]*1e6) # pu of 150e3 # J/mK


#  Δ_cond_temp = 0 + Δt / Ca * (W - (12 - 12) / Ta) 
#  Δ_surf_temp = 0 + Δt / Cb * ((0 - 0) / Ta) - 0 / Tb 


# using JuMP, Ipopt
 
# function add_thermal_constraints!(m::Model, I, T;
#                                    TA, CA, TB, CB, Δt,
#                                    R20, α,
#                                    θamb, θc_max,
#                                    Δθ0 = (0.0, 0.0))
#     # I : Vector of decision variables (current, A), length T
#     # Returns Δθ1, Δθ2, Wc for downstream use
 
#     Δθmax = θc_max - θamb
 
#     @variable(m, Δθ1[1:T])
#     @variable(m, Δθ2[1:T])
#     @variable(m, Wc[1:T]  >= 0)
 
#     # Initial conditions
#     @constraint(m, Δθ1[1] == Δθ0[1])
#     @constraint(m, Δθ2[1] == Δθ0[2])
 
#     # Loss coupling  W_c = I² · R20 · [1 + α · Δθ1]
#     # (θc - 20) rewritten as Δθ1 + (θamb - 20) so it stays in rise variables
#     @NLconstraint(m, [k = 1:T],
#         Wc[k] == R20 * I[k]^2 *
#                  (1 + α * (Δθ1[k] + θamb - 20)))
 
#     # Forward Euler (linear in Δθ, linear in Wc)
#     for k in 1:T-1
#         @constraint(m, Δθ1[k+1] ==
#             Δθ1[k] + (Δt/CA) * (Wc[k] - (Δθ1[k] - Δθ2[k]) / TA))
#         @constraint(m, Δθ2[k+1] ==
#             Δθ2[k] + (Δt/CB) * ((Δθ1[k] - Δθ2[k]) / TA - Δθ2[k] / TB))
#     end
 
#     # Rating constraint — enforced on the rise variable directly
#     @constraint(m, [k = 1:T], Δθ1[k] <= Δθmax)
 
#     return Δθ1, Δθ2, Wc
# end
 
# # --- Problem setup ---
# T   = 288                                   # 24 h at Δt = 5 min
# Δt  = 300.0
# Imax = 2500.0
 
# m = Model(Ipopt.Optimizer)
# set_silent(m)
 
# @variable(m, 0 <= I[1:T] <= Imax)
# # ... any additional constraints on I (dispatchable, wind envelope, ramping, etc.)
 
# Δθ1, Δθ2, Wc = add_thermal_constraints!(m, I, T;
#     TA = 0.4, CA = 5000.0,
#     TB = 1.0, CB = 200_000.0,
#     Δt = Δt,
#     R20 = 7.2e-6, α = 0.00393,
#     θamb = 15.0, θc_max = 70.0,
#     Δθ0 = (0.0, 0.0))
 
# @objective(m, Max, sum(I))                  # or e.g. sum(V*I) for energy
 
# optimize!(m)
 
# println("Peak Δθ1 = ", maximum(value.(Δθ1)), " K")
# println("Objective = ", objective_value(m))