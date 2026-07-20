# A test script for running a simple preventive SCOPF model considering DC network contingencies, and optimising HVDC Converter droop gains

using PowerModelsACDC
import PowerModels
import JuMP
import Ipopt
import Plots

## Use first one for MA27, check the local path for your HSL library
#ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer)
ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "hsllib" => "/Users/hergun/IpoptMA/lib/libhsl.dylib", "tol" => 1e-4, "linear_solver" => "ma27", "max_iter" => 3000)


file = pkgdir(PowerModelsACDC, "test", "data", "case3_dcr.m")


function build_mn_data(file, number_of_hours)
    t = 1:number_of_hours
    mp_data = parse_file(file)
    return PowerModels.replicate(mp_data, length(t); global_keys=Set{String}(["source_type", "name", "source_version", "per_unit"]))
end

function build_dcr_data(file, number_of_hours::Int, time_interval::Int)
    data = parse_file(file)
    t = 1:number_of_hours * time_interval
    dcr_data = PowerModels.replicate(data, length(t); global_keys=Set{String}(["source_type", "name", "source_version", "per_unit"]))
    for (nw, network) in dcr_data["nw"]
        for (br, branchdc) in network["branchdc"]
            branchdc["surf_temp_min"] = -273.0
            branchdc["surf_temp_max"] = 70.0
            branchdc["delta_surf_temp_min"] = - 2 * 273.0
            branchdc["delta_surf_temp_max"] =   2 * 273.0

            branchdc["cond_temp_min"] = -273.0
            branchdc["cond_temp_max"] = 70.0
            branchdc["delta_cond_temp_min"] = - 2 * 273.0
            branchdc["delta_cond_temp_max"] =   2 * 273.0

            branchdc["time_interval"] = 3600.0 / time_interval  # seconds
            branchdc["thermal_resistance_a"] = 0.4 * data["baseMVA"]*1e6 # pu of Km/W
            branchdc["thermal_resistance_b"] = 1.12 * data["baseMVA"]*1e6 # pu of Km /W
            branchdc["thermal_capacitance_a"] = 18000 / (data["baseMVA"]*1e6) # pu of 18000 # J/mK
            branchdc["thermal_capacitance_b"] = 150e3 / (data["baseMVA"]*1e6) # pu of 150e3 # J/mK
            branchdc["ambient_temperature"] = 12 # °C
            branchdc["temperature_coefficient"] = 0.00393 # 1/K

            branchdc["initial_conductor_temperature"] = 12 # °C
            branchdc["initial_cable_surface_temperature"] = 12 # °C

            branchdc["dcr"] = 1
            if parse(Int, br) == 1
                branchdc["length"] = 300e3 # in meters
            elseif parse(Int, br) == 2
                branchdc["length"] = 250e3 # in meters
            else
                branchdc["length"] = 150e3 # in meters
            end
        end
    end

    return dcr_data
end

function add_gen_profile!(data, profile; gen = 1)
    for (nw, network) in data["nw"]
        network["gen"]["$gen"]["pmax"] = network["gen"]["$gen"]["pmax"] * profile[parse(Int, nw)]
    end
end

function add_price_profile!(data, profile; gen = 1)
    for (nw, network) in data["nw"]
        network["gen"]["$gen"]["cost"][1] = profile[parse(Int, nw)]
    end
end
# OPF settings
s = Dict("conv_losses_mp" => true, "objective_components" => ["gen", "load"])

# Number of hours
number_of_hours = 168 # one week
price_profile_2_ = [1.5, 2.0, 1.5, 1.0, 2.5, 1.5, 1.5] .* 100
price_profile_3_ = [2.0, 5.0, 1.5, 1.5, 4.5, 3.5, 1.5] .* 100

# time_interval
time_interval = 2 # the fraction of an hour to model thermal behaviour time step: 2 => half hour steps, 4 => quarter hour steps etc....

data = build_mn_data(file, number_of_hours)
price_profile_2 = repeat(price_profile_2_, inner = Int(number_of_hours / length(price_profile_2_)))
price_profile_3 = repeat(price_profile_3_, inner = Int(number_of_hours / length(price_profile_3_)))
add_price_profile!(data, price_profile_2, gen = 2)
add_price_profile!(data, price_profile_3, gen = 3)

# profile = rand(length(data["nw"]))
# add_gen_profile!(data, profile, gen = 1)

# Solve OPF
result_base = solve_acdcopf_iv(data, PowerModels.IVRPowerModel, ipopt; multinetwork=true, setting=s)

# Add DCR data
dcr_data = build_dcr_data(file, number_of_hours, time_interval)
price_profile_2 = repeat(price_profile_2_, inner = Int(number_of_hours / length(price_profile_2_) * time_interval))
price_profile_3 = repeat(price_profile_3_, inner = Int(number_of_hours / length(price_profile_3_) * time_interval))
add_price_profile!(dcr_data, price_profile_2, gen = 2)
add_price_profile!(dcr_data, price_profile_3, gen = 3)
# dcr_profile = repeat(profile, inner = time_interval)
# add_gen_profile!(dcr_data, dcr_profile, gen = 1)

# Solve DCR OPF
result_dcr = solve_acdcopf_iv(dcr_data, PowerModels.IVRPowerModel, ipopt; multinetwork=true, setting=s)

println("Objective base: ", result_base["objective"])
println("Objective DCR: ", result_dcr["objective"] / time_interval)


power_base = zeros(length(result_base["solution"]["nw"]))

for (n, network) in result_base["solution"]["nw"]
    power_base[parse(Int, n)] = network["branchdc"]["1"]["pf"]
end


power_dcr  = zeros(length(result_dcr["solution"]["nw"]), length(result_dcr["solution"]["nw"]["1"]["branchdc"]))
cond_temp = zeros(length(result_dcr["solution"]["nw"]), length(result_dcr["solution"]["nw"]["1"]["branchdc"]))
for (n, network) in result_dcr["solution"]["nw"]
    for (br, branch) in network["branchdc"]
        cond_temp[parse(Int, n), parse(Int, br)] = branch["cable_cond_temp"]
        power_dcr[parse(Int, n), parse(Int, br)] = branch["pf"]
    end
end

p = Plots.plot(power_base)
p1 = Plots.plot(power_dcr)
p2 = Plots.plot(cond_temp)
