import PowerModelsACDC
const _PMACDC = PowerModelsACDC
import PowerModels
const _PM = PowerModels
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

data = _PM.parse_file(file)

_PMACDC.process_additional_data!(data)

ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)

result = _PMACDC.solve_acdcpf(file, _PM.ACRPowerModel, ipopt; setting = s)
result_droop = _PMACDC.solve_acdcpf(file_pf_droop, _PM.ACRPowerModel, ipopt; setting = s)
result = _PMACDC.solve_acdcpf(file_case3120, _PM.ACRPowerModel, ipopt; setting = s)
result = _PMACDC.solve_sacdcpf(file_case3120)

resultAC = _PMACDC.solve_acdcopf(file, _PM.ACPPowerModel, ipopt; setting = s)
resultACSOCBIM = _PM.solve_acdcopf(file, _PM.SOCWRPowerModel, ipopt; setting = s)
# resultLPAC = _PMACDC.run_acdcopf(file, _PM.LPACCPowerModel, ipopt; setting = s)

# resultQC = _PMACDC.run_acdcopf(file, _PM.QCRMPowerModel, ipopt; setting = s)

# resultSOCBIM = _PMACDC.run_acdcopf(file, _PM.SOCWRPowerModel, ipopt; setting = s)
# resultACSOCBIM = _PM.run_opf(file, _PM.SOCWRPowerModel, ipopt; setting = s)
# # #
# resultSOCBFM = _PMACDC.run_acdcopf_bf(file, _PM.SOCBFPowerModel, ipopt; setting = s)
# resultSOCBFMConic = _PMACDC.run_acdcopf_bf(file, _PM.SOCBFConicPowerModel, mosek; setting = s)
# resultSOCBFMConicSCS = _PMACDC.run_acdcopf_bf(file, _PM.SOCBFConicPowerModel, scs; setting = s)
# # #
# resultSDP = _PMACDC.run_acdcopf(file, _PM.SDPWRMPowerModel, mosek; setting = s)
# # #
# resultDC = _PMACDC.run_acdcopf(file, _PM.DCPPowerModel, gurobi; setting = s)
# resultACPF5 = _PMACDC.run_acdcpf(file_case5acdc, _PM.ACPPowerModel, ipopt; setting = s)