import PowerModelsACDC as PMACDC 
import PowerModels
import InfrastructureModels
import JuMP
import Ipopt
import Juniper
import HiGHS
import Plots
import Gurobi

function add_fcuc_data!(data)
    frequency_parameters = Dict{String, Any}()
    frequency_parameters["fmin"] = 49.0
    frequency_parameters["fmax"] = 51.0
    frequency_parameters["f0"] = 50.0
    frequency_parameters["rocof_max"] =  0.6
    frequency_parameters["rocof_min"] = -0.6

    for (g, gen) in data["gen"]
        gen["ramp_rate"] = 1.0
        gen["ramp_rate_per_s"] = gen["pmax"] / 3600
        gen["fcr_contribution"] = true
        gen["mdt"] = 2
        gen["mut"] = 2
    end

    for (s, storage) in data["storage"]
        bus_id = storage["storage_bus"]
        if storage["status"] == 1
            storage["zone"] = data["bus"]["$bus_id"]["zone"]
            storage["area"] = data["bus"]["$bus_id"]["area"]   
            storage["inertia_constants"] = 0.0
            storage["start_up_cost"] = 1000.0
            storage["ramp_rate"] = 1.0
            storage["ramp_rate_per_s"] =   storage["ramp_rate"] / 3600  
            storage["fcr_contribution"] = true
            storage["mdt"] = 1.0
            storage["mut"] = 1.0
        else
            delete!(data["storage"], s)
        end
    end

    data["ignored_zones"] = [2]

    return data, frequency_parameters
end

	
function prepare_uc_test_data(file; contingencies = nothing)
    # This will parse the m-file using PowerModels
    data = PowerModels.parse_file(file)
    
    # This block makes the load demand flexible, by adding components that represent voluntary demand reduction, the cost associated with it, and the load curtailment cost. 
    for (l, load) in data["load"]
        data["load"][l]["pred_rel_max"] = 0.0
        data["load"][l]["cost_red"] = 100.0 * data["baseMVA"]
        data["load"][l]["cost_curt"] = 10000.0 * data["baseMVA"]
        data["load"][l]["flex"] = 1
    end

    # This function will add the necessary input for frequency constraints
    data, frequency_parameters = add_fcuc_data!(data)

    # This PMACDC function takes the input data dictionary and populates the necessary fields with frequency related data. 
    PMACDC.prepare_uc_data!(data; uc = true, frequency_parameters = frequency_parameters)

    # Define length of the time series
    number_of_hours = 2

    # define time series for RES generation,

    number_of_hours = 24

    res_series = [0.4 0.5 0.66 0.7 0.7 0.9 0.95 1.02 1.15 1.3 1.35 1.3 1.21 1.08 1.0 0.96 0.93 1.0 1.1 1.2 1.08 1.05 0.99 0.89]
    l_series = [0.6 0.7 0.75 0.78 0.85 0.88 0.9 1.0 1.12 1.25 1.2 1.08 0.99 0.92 0.8 0.73 0.8 0.9 1.03 1.2 1.11 0.99 0.8 0.69]

    # Finally create a data dictionary that includes all information
    mn_data = PMACDC.create_multinetwork_uc_model!(data, number_of_hours, res_series, l_series, contingencies = contingencies)

    return mn_data
end

solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer)

file = pkgdir(PMACDC, "test", "data", "rocof_test.m")

rocof_data = prepare_uc_test_data(file)

setting = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "relax_uc_binaries" => true, "objective_components" => ["gen", "load"])

rocof = 0.5:0.1:2.0
opex = zeros(1, length(rocof))
result = Dict([i => Dict() for i in 1: length(rocof)])
for (i, r) in enumerate(rocof)
    for (n, network) in rocof_data["nw"]
        network["frequency_parameters"]["rocof_max"] =  r
        network["frequency_parameters"]["rocof_min"] = -r
    end
    result[i] = PMACDC.solve_rocofuc(rocof_data, PowerModels.NFAPowerModel, solver, setting = setting, multinetwork = true)
    opex[i] = result[i]["objective"]
end


htot1 = zeros(1, 24)
htot3 = zeros(1, 24)
ΔPsplit1 = zeros(1, 24)
ΔPsplit3 = zeros(1, 24)
power_exchange = zeros(1, 24)
r = 16 # rocof = 1Hz/s 
for h in 1:24
    for (g, gen) in result[r]["solution"]["nw"]["$h"]["gen"] 
        if parse(Int, g) <= 5
            htot1[h] = htot1[h] + gen["alpha_g"] * rocof_data["nw"]["$h"]["gen"][g]["inertia_constants"] * rocof_data["nw"]["$h"]["gen"][g]["pmax"] 
        end
        if parse(Int, g) >= 11 && parse(Int, g) <= 15
            htot3[h] = htot3[h] + gen["alpha_g"] * rocof_data["nw"]["$h"]["gen"][g]["inertia_constants"] * rocof_data["nw"]["$h"]["gen"][g]["pmax"] 
        end
    end
   ΔPsplit1[h] = result[r]["solution"]["nw"]["$h"]["contingency"]["1"]["split_cont"]
   ΔPsplit3[h] = result[r]["solution"]["nw"]["$h"]["contingency"]["3"]["split_cont"]
   power_exchange[h] = result[r]["solution"]["nw"]["$h"]["branch"]["19"]["pf"] + result[r]["solution"]["nw"]["$h"]["branch"]["20"]["pf"]
end

rocof1 = ΔPsplit1 ./ (2 * htot1) * 50.0 
rocof3 = ΔPsplit3 ./ (2 * htot3) * 50.0

p = Plots.plot(1:24, rocof1', label = "RoCoF zone 1", xlabel = "Hour ID", ylabel = "Rocof in Hz/s",  fontfamily = "Computer Modern")
Plots.plot(p, 1:24, rocof3', label = "RoCoF zone 3")
p1 = Plots.plot(1:24, power_exchange' .* 100, xlabel = "Hour ID", ylabel = "Power Exchange in MW", fontfamily = "Computer Modern", label = "Zone 1 → Zone 3")
p2 = Plots.plot(rocof, opex' ./ 1e3, xlabel = "Allowed RoCoF in Hz/s", ylabel = "OPEX in k€", fontfamily = "Computer Modern", legend = false)