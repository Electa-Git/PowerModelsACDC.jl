using PowerModelsACDC
using PowerModels
using CPLEX
using Ipopt
#using SCS

data = PowerModels.parse_file("./test/data/case5_acdc.m")
PowerModelsACDC.process_additional_data!(data)
result = run_acdcopf(data, ACPPowerModel, IpoptSolver(); setting = Dict("output" => Dict("line_flows" => true)))
