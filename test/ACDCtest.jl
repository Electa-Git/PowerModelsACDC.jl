using PowerModelsACDC
using PowerModels
using Ipopt
#using CPLEX
#using SCS

data = PowerModels.parse_file("./test/data/case5_acdc.m")
PowerModelsACDC.process_additional_data!(data)
result = run_acdcopf(data, ACPPowerModel, IpoptSolver(); setting = Dict("output" => Dict("branch_flows" => true)))


# implement PF problem for validation:
# (2) Converter setpoints as constraint (constraint_active_gen_setpoint, constraint_reactive_gen_setpoint)
# (3) Voltage magnitude setpoints for the DC buses
