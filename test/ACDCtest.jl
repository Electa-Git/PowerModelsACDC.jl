using PowerModelsACDC
using PowerModels
using Ipopt
#using CPLEX
using SCS

file = "./test/data/case5_acdc.m"
file1 ="./test/data/case5_dc.m"
data = PowerModels.parse_file(file1)
PowerModelsACDC.process_additional_data!(data)
display(data)
#scs = SCSSolver(max_iters=100000, verbose=0);
scs = SCSSolver(max_iters=100000);
ipopt = IpoptSolver(tol=1e-6, print_level=0)
s = Dict("output" => Dict("branch_flows" => true))

resultAC = run_acdcopf(file, ACPPowerModel, ipopt; setting = s)
resultACPF = run_acdcpf(file, ACPPowerModel, ipopt; setting = s)

resultQC = run_acdcopf(file, QCWRPowerModel, ipopt; setting = s)
#
resultQCTri = run_acdcopf(file, QCWRTriPowerModel, ipopt; setting = s)
#
resultSOCBIM = run_acdcopf(file, SOCWRPowerModel, ipopt; setting = s)
#
resultSOCBFM = run_acdcopf(file, SOCWIPowerModel, ipopt; setting = s)
#
resultSDP = run_acdcopf(file, SDPWRMPowerModel, scs; setting = s)
#
resultDC = run_acdcopf(file, DCPPowerModel, ipopt; setting = s)
#

# other tests
resultACPF = run_acdcpf(file, ACPPowerModel, IpoptSolver(); setting = s)
#
resultAConlyAC = run_opf(file, ACPPowerModel, IpoptSolver(); setting = s)

resultSOCBFMonlyAC = run_opf(file, SOCWIPowerModel, IpoptSolver(); setting = s)

resultSOCBIMonlyAC = run_opf(file, SOCWRPowerModel, IpoptSolver(); setting = s)

# matpower style dc line
resultDCMP = run_acdcopf(file1, DCPPowerModel, ipopt; setting = s)

# implement PF problem for validation:
# (2) Converter setpoints as constraint (constraint_active_gen_setpoint, constraint_reactive_gen_setpoint)
# (3) Voltage magnitude setpoints for the DC buses
