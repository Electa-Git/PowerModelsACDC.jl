# A test script for running a simple preventive SCOPF model considering DC network contingencies, and optimising HVDC Converter droop gains

import PowerModelsACDC
const _PMACDC = PowerModelsACDC
import PowerModels
const _PM = PowerModels
import InfrastructureModels
const _IM = InfrastructureModels
import Ipopt
import JuMP
import Plots

path = _PMACDC.BASE_DIR

## Use first one for MA27, check the local path for your HSL library
ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer)


###### Load your test file
case_name = "case67"
kmax = 100
#######################

if case_name == "case5"
    file = joinpath(path, "test", "data", "case5acdc_droop.m")
elseif case_name == "case39"
    file = joinpath(path, "test", "data", "case39acdc_droop.m")
elseif case_name == "case67"
    file = joinpath(path, "test", "data", "case67acdc_droop.m")
end

data = _PM.parse_file(file)

for (c, conv) in data["convdc"]
    conv["kmax"] = kmax
end

for (g, gen) in data["gen"]
    gen["gen_slack"] = 0.0
end


# OPF settings
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "optimize_converter_droop" => true, "objective_components" => ["gen"])
# Reference droop
kref = 1/100

# Random generation and demand time series, later replace with something more representative
g_series = [1.0  0.7  0.75  0.78  0.85  0.88  0.9  1.0  1.12  1.25  1.2  1.08  0.99  0.92  0.8  0.73  0.8  0.9  1.03  1.2  1.11  0.99  0.8  0.69]
l_series = [1.0  0.7  0.75  0.78  0.85  0.88  0.9  1.0  1.12  1.25  1.2  1.08  0.99  0.92  0.8  0.73  0.8  0.9  1.03  1.2  1.11  0.99  0.8  0.69]
# Select the nunmber of hours for which you want to run the optimisation
number_of_hours = 24
# get the number of contingencies from the data dictionary
number_of_contingencies = length(data["contingencies"])

# violations = HVDCdroop.find_binding_contingencies(data, ipopt, l_series, g_series, s, kref)
data_all = _PMACDC.create_scopf_data(data,  number_of_hours, g_series, l_series)

# Solve OPF
result = _PMACDC.solve_scopf(data_all, _PM.ACPPowerModel, ipopt; multinetwork = true, setting = s)




############ PRINT droop coefficient for converters ###################
k_droop = zeros(length(result["solution"]["nw"]["1"]["convdc"]))
for (c, conv) in result["solution"]["nw"]["1"]["convdc"]
    k_droop[parse(Int, c)] = conv["k_droop"]
end

Plots.scatter(k_droop)
Plots.xlabel!("Converter ID")
Plots.ylabel!("k in MW / kV")

########## PRINT Converter dc side & generator setpoints for all hours and contingencies

pconv = zeros(number_of_hours * number_of_contingencies, length(result["solution"]["nw"]["1"]["convdc"]))
pg = zeros(number_of_hours * number_of_contingencies, length(result["solution"]["nw"]["1"]["gen"]))

for (n, network) in result["solution"]["nw"]
    for (g, gen) in network["gen"]
        pg[parse(Int, n), parse(Int, g)] = gen["pg"] * data_all["nw"]["1"]["baseMVA"]
    end
    for (c, conv) in network["convdc"]
        pconv[parse(Int, n), parse(Int, c)] = conv["pdc"] * data_all["nw"]["1"]["baseMVA"]
    end
end

Plots.scatter(pg[:, 1])
for idx in 2:length(result["solution"]["nw"]["1"]["gen"])
    Plots.scatter!(pg[:, idx])
end
Plots.xlabel!("contingency ID")
Plots.ylabel!("Pg in MW")

Plots.scatter(pconv[:, 1])
for idx in 2:length(result["solution"]["nw"]["1"]["convdc"])
    Plots.scatter!(pconv[:, idx])
end
Plots.xlabel!("contingency ID")
Plots.ylabel!("Pdc in MW")


for (n, network) in result["solution"]["nw"]
    if parse(Int, n) < 10
        pd = result["solution"]["nw"]["1"]["convdc"]["1"]["pdc"] + (result["solution"]["nw"]["1"]["convdc"]["1"]["k_droop"] * (network["busdc"]["1"]["vm"]- result["solution"]["nw"]["1"]["busdc"]["1"]["vm"]))
        println("Contingency ID: ", n, " Pdc calc: ", pd, " Pdc: ", network["convdc"]["1"]["pdc"])
    end
end

