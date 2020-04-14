import PowerModelsACDC
const _PMACDC = PowerModelsACDC
import PowerModels
const _PM = PowerModels
import Ipopt
import Memento
# import CPLEX
import SCS
import Mosek
import MosekTools
import JuMP
import Gurobi  # needs startvalues for all variables!

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
file = file_case5acdc

data = _PM.parse_file(file)

_PMACDC.process_additional_data!(data)

ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
scs = JuMP.with_optimizer(SCS.Optimizer)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer, Presolve=0)
# cplex = JuMP.with_optimizer(CPLEX.Optimizer)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)

resultAC = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt; setting = s)

resultLPAC = _PMACDC.run_acdcopf(file, _PM.LPACCPowerModel, ipopt; setting = s)

resultQC = _PMACDC.run_acdcopf(file, _PM.QCRMPowerModel, ipopt; setting = s)

resultSOCBIM = _PMACDC.run_acdcopf(file, _PM.SOCWRPowerModel, ipopt; setting = s)
resultACSOCBIM = _PM.run_opf(file, _PM.SOCWRPowerModel, ipopt; setting = s)
# #
resultSOCBFM = _PMACDC.run_acdcopf_bf(file, _PM.SOCBFPowerModel, ipopt; setting = s)
resultSOCBFMConic = _PMACDC.run_acdcopf_bf(file, _PM.SOCBFConicPowerModel, mosek; setting = s)
resultSOCBFMConicSCS = _PMACDC.run_acdcopf_bf(file, _PM.SOCBFConicPowerModel, scs; setting = s)
# #
resultSDP = _PMACDC.run_acdcopf(file, _PM.SDPWRMPowerModel, mosek; setting = s)
# #
resultDC = _PMACDC.run_acdcopf(file, _PM.DCPPowerModel, gurobi; setting = s)
resultACPF5 = _PMACDC.run_acdcpf(file_case5acdc, _PM.ACPPowerModel, ipopt; setting = s)
