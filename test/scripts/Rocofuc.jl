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
    res_series = [1.0  1.0] #  0.66  0.7   0.7   0.9   0.95 1.02  1.15  1.3   1.35 1.3   1.21  1.08  1.0  0.96  0.93 1.0  1.1   1.2  1.08  1.05  0.99 0.89]

    # define time series for demand
    l_series = [1.0  1.0]#  0.75  0.78  0.85  0.88  0.9  1.0   1.12  1.25  1.2  1.08  0.99  0.92  0.8  0.73  0.8  0.9  1.03  1.2  1.11  0.99  0.8  0.69]

    # Finally create a data dictionary that includes all information
    mn_data = PMACDC.create_multinetwork_uc_model!(data, number_of_hours, res_series, l_series, contingencies = contingencies)

    return mn_data
end

solver = JuMP.optimizer_with_attributes(Gurobi.Optimizer)

file = pkgdir(PMACDC, "test", "data", "rocof_test.m")

rocof_data = prepare_uc_test_data(file)

setting = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "relax_uc_binaries" => true, "objective_components" => ["gen", "load"])
	
result = PMACDC.solve_rocofuc(rocof_data, PowerModels.NFAPowerModel, solver, setting = setting, multinetwork = true)




sum([gen["pmax"] * gen["inertia_constants"] for (g, gen) in rocof_data["nw"]["1"]["gen"] if parse(Int, g) <= 5] )

# To Do's:

# - Make sure it can ingore splits / zones that are asynchronous (i.e. connected via hvdc) and not include them in the rocof constraints.

global htot1 = 0
global htot3 = 0
for (g, gen) in result["solution"]["nw"]["1"]["gen"] 
    if parse(Int, g) <= 5
    global htot1 = htot1 + gen["alpha_g"] * rocof_data["nw"]["1"]["gen"][g]["inertia_constants"] * rocof_data["nw"]["1"]["gen"][g]["pmax"] 
    end
    if parse(Int, g) >= 11 && parse(Int, g) <= 15
    global htot3 = htot3 + gen["alpha_g"] * rocof_data["nw"]["1"]["gen"][g]["inertia_constants"] * rocof_data["nw"]["1"]["gen"][g]["pmax"] 
    end
end

rocof1 = result["solution"]["nw"]["1"]["contingency"]["1"]["split_cont"] / (2 * htot1) * 50.0
rocof3 = result["solution"]["nw"]["1"]["contingency"]["3"]["split_cont"] / (2 * htot1) * 50.0

sum([gen["alpha_g"] * gen["pg"] for (g, gen) in result["solution"]["nw"]["1"]["gen"]])
sum([load["pflex"]  for (l, load) in result["solution"]["nw"]["1"]["load"]])
sum([load["pcurt"]  for (l, load) in result["solution"]["nw"]["1"]["load"]])
