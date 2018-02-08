using PowerModelsACDC
using PowerModels
using CPLEX
using Ipopt
#using SCS

data = PowerModels.parse_file("./test/data/case5_acdc.m")
PowerModelsACDC.process_additional_data!(data)
result = run_acdcopf(data, ACPPowerModel, IpoptSolver(); setting = Dict("output" => Dict("line_flows" => true)))
#PowerModelsADriaN.process_additional_data!(data) # processing UB OPF specific data

# solve NLP AC OPF
#resultAC = run_ac_ubopf(data, IpoptSolver(), setting = Dict("output" => Dict("line_flows" => true, "line_series_flows" => true)))

# solve linearized unbalanced distflow
#resultLin = run_lin_ubopf(data, MosekSolver(), setting = Dict("output" => Dict("line_flows" => true, "line_series_flows" => true)))
# solve SDP convex unbalanced distflow
# use mosek or SCS
#resultSDP = run_sdp_ubopf(data, MosekSolver(), setting = Dict("output" => Dict("line_flows" => true, "line_series_flows" => true, "rank_elements" => true)))
#PowerModelsADriaN.ub_post_process!(data, resultSDP, rank_accuracy = 1e-4)


#resultACPF = run_ac_ubpf(data, IpoptSolver())
