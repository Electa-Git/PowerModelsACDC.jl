using PowerModelsACDC
using PowerModels
using Ipopt
#using CPLEX
using SCS

file_case5acdc = "./test/data/case5_acdc.m"
file_case5dc ="./test/data/case5_dc.m"
file_case9 = "./test/data/t_case9_dcline.m"
file_case24 = "./test/data/case24_3zones_acdc.m"
data = PowerModels.parse_file(file_case9)
PowerModelsACDC.process_additional_data!(data)
#display(data)
#scs = SCSSolver(max_iters=100000, verbose=0);
scs = SCSSolver(max_iters=100000);
ipopt = IpoptSolver(tol=1e-6, print_level=0)
s = Dict("output" => Dict("branch_flows" => true))

resultAC = run_acdcopf(file_case5acdc, ACPPowerModel, ipopt; setting = s)
#
resultQC = run_acdcopf(file_case5acdc, QCWRPowerModel, ipopt; setting = s)
# #
resultQCTri = run_acdcopf(file_case5acdc, QCWRTriPowerModel, ipopt; setting = s)
# #
resultSOCBIM = run_acdcopf(file_case5acdc, SOCWRPowerModel, ipopt; setting = s)
# #
resultSOCBFM = run_acdcopf(file_case5acdc, SOCDFPowerModel, ipopt; setting = s)
# #
resultSDP = run_acdcopf(file_case5acdc, SDPWRMPowerModel, scs; setting = s)
# #
resultDC = run_acdcopf(file_case5acdc, DCPPowerModel, ipopt; setting = s)
#
# other tests
<<<<<<< HEAD
resultACPF_24 = run_acdcpf(file_case24, ACPPowerModel, IpoptSolver(); setting = s)
resultACPF_9 = run_acdcopf(file_case9, ACPPowerModel, IpoptSolver(); setting = s)

resultAConlyAC = run_opf(file_case5acdc, ACPPowerModel, IpoptSolver(); setting = s)

resultSOCBIMonlyAC = run_opf(file_case5acdc, SOCWRPowerModel, IpoptSolver(); setting = s)
=======
resultACPF = run_acdcpf(file2, ACPPowerModel, ipopt; setting = s)

resultAConlyAC = run_opf(file, ACPPowerModel, ipopt; setting = s)

resultSOCBIMonlyAC = run_opf(file, SOCWRPowerModel, ipopt; setting = s)
>>>>>>> 4291f9ea559301132b245ad5dec7975492f79f1d

# matpower style dc line
resultDCMP = run_acdcopf(file_case5dc, DCPPowerModel, ipopt; setting = s)

# implement PF problem for validation:
# (2) Converter setpoints as constraint (constraint_active_gen_setpoint, constraint_reactive_gen_setpoint)
# (3) Voltage magnitude setpoints for the DC buses
