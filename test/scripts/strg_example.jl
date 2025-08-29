# This test file will run a multi-period OPF where we can give fixed starting values for the energy content of the storage units for selected hours.

import PowerModelsACDC
const _PMACDC = PowerModelsACDC
import PowerModels
const _PM = PowerModels
import InfrastructureModels
const _IM = InfrastructureModels
import Ipopt
import JuMP
import Plots
import HiGHS

solver = HiGHS.Optimizer

path = _PMACDC.BASE_DIR

# test case file
file = joinpath(path, "test", "data", "case5_2grids_uc_hvdc_strg.m")

# Parse file using PowerModels
data = PowerModels.parse_file(file)
# Process demand reduction and curtailment data
for (l, load) in data["load"]
    data["load"][l]["pred_rel_max"] = 0.3
    data["load"][l]["cost_red"] = 100.0 * data["baseMVA"]
    data["load"][l]["cost_curt"] = 10000.0 * data["baseMVA"]
    data["load"][l]["flex"] = 1
end

# indeicate which generators are renewable
for (g, gen) in data["gen"]
   if g == "2" || g == "8"
        data["gen"][g]["res"] = true
   else
        data["gen"][g]["res"] = false
   end
end     

# create a matrix with time points where storage should have a fixed content (column 1), and the fixed energy content in p.u. (column 2)
for (s, strg) in data["storage"]
    data["storage"][s]["fixed_energy"] = [25 0.5
                                          49 0.4
                                          73 0.3
                                          97 0.6]
end

# We are going to consider 3 typical days which will make up in total five days. The sequence is [day1 day2 day1 day3 day1]
number_of_hours = 120

# this is an arbutary generation and demand series, later replace with something more representative
g_series = [0.4  0.5  0.66  0.7   0.7   0.9   0.95 1.02  1.15  1.3   1.35 1.3   1.21  1.08  1.0  0.96  0.93 1.0  1.1   1.2  1.08  1.05  0.99 0.89]
l_series = [0.6  0.7  0.75  0.78  0.85  0.88  0.9  1.0   1.12  1.25  1.2  1.08  0.99  0.92  0.8  0.73  0.8  0.9  1.03  1.2  1.11  0.99  0.8  0.69]

# just define demand and generation time series for each representative day
day1g = g_series
day1l = l_series
day2g = 0.5 * day1g
day2l = 1.2 * day1l
day3g = 0.7 * day1g
day3l = 1.5 * day1l

# put all days to
timeseries_g = hcat(day1g, day2g, day1g, day3g, day1g)
timeseries_l = hcat(day1l, day2l, day1l, day3l, day1l)

# create multinetwork data structure
mn_data = _PMACDC.create_multinetwork_uc_model!(data, number_of_hours, timeseries_g, timeseries_l)

# optimisation settings
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true,  "objective_components" => ["gen", "demand"])

# run a DC OPF
resultopf = _PMACDC.solve_acdcopf(mn_data, _PM.DCPPowerModel, solver, setting = s, multinetwork = true)

# Get storage energy content for each hour and plot

se1 = [resultopf["solution"]["nw"]["$n"]["storage"]["1"]["se"] for n in 1:120]
se2 = [resultopf["solution"]["nw"]["$n"]["storage"]["2"]["se"] for n in 1:120]

ps = Plots.plot(se1, xlabel = "Hour", ylabel = "Energy stored in unit x (MWh)", label = "Unit 1")    
Plots.plot!(ps, se2, xlabel = "Hour", ylabel = "Energy stored in unit x (MWh)", label = "Unit 2")