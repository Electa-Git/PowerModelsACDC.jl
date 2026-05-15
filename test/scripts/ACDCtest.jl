using PowerModelsACDC
import PowerModels
import Ipopt
import Memento
import JuMP

file_pf_droop = "./test/data/case5_acdc_droop.m"

file_case5acdc = "./test/data/case5_acdc.m"
file_case5dc ="./test/data/case5_dc.m"
file_case5dcgrid ="./test/data/case5_dcgrid.m"
file_case5dcgridb0 ="./test/data/case5_dcgrid_b0.m"
file_case24 = "./test/data/case24_3zones_acdc.m"
file_case39 = "./test/data/case39_acdc.m"
file_case3120 = "./test/data/case3120sp_acdc.m"
file_case5dcgrid = "./test/data/case5_dcgrid.m"
file_case5_b2bdc = "./test/data/case5_b2bdc.m"
file_lcc = "./test/data/lcc_test.m"
file_588sdet_acdc = "./test/data/pglib_opf_case588_sdet_acdc.m"
file = file_case3120

data = PowerModels.parse_file(file)

process_additional_data!(data)

ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

s = Dict("conv_losses_mp" => true)

result = solve_acdcpf(file, PowerModels.ACRPowerModel, ipopt; setting = s)
result_droop = solve_acdcpf(file_pf_droop, PowerModels.ACRPowerModel, ipopt; setting = s)
result = solve_acdcpf(file_case3120, PowerModels.ACRPowerModel, ipopt; setting = s)
result = solve_sacdcpf(file_case3120)

resultAC = solve_acdcopf(file, PowerModels.ACPPowerModel, ipopt; setting = s)
resultACSOCBIM = PowerModels.solve_acdcopf(file, PowerModels.SOCWRPowerModel, ipopt; setting = s)
# resultLPAC = solve_acdcopf(file, PowerModels.LPACCPowerModel, ipopt; setting = s)

# resultQC = solve_acdcopf(file, PowerModels.QCRMPowerModel, ipopt; setting = s)

# resultSOCBIM = solve_acdcopf(file, PowerModels.SOCWRPowerModel, ipopt; setting = s)
# resultACSOCBIM = PowerModels.solve_opf(file, PowerModels.SOCWRPowerModel, ipopt; setting = s)
# # #
# resultSOCBFM = solve_acdcopf_bf(file, PowerModels.SOCBFPowerModel, ipopt; setting = s)
# resultSOCBFMConic = solve_acdcopf_bf(file, PowerModels.SOCBFConicPowerModel, mosek; setting = s)
# resultSOCBFMConicSCS = solve_acdcopf_bf(file, PowerModels.SOCBFConicPowerModel, scs; setting = s)
# # #
# resultSDP = solve_acdcopf(file, PowerModels.SDPWRMPowerModel, mosek; setting = s)
# # #
# resultDC = solve_acdcopf(file, PowerModels.DCPPowerModel, gurobi; setting = s)
# resultACPF5 = solve_acdcpf(file_case5acdc, PowerModels.ACPPowerModel, ipopt; setting = s)
