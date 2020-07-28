import PowerModelsACDC; const _PMACDC = PowerModelsACDC
import PowerModels; const _PM = PowerModels
import InfrastructureModels; const _IM = InfrastructureModels
import Ipopt
# using CPLEX
import SCS
import Juniper
import Mosek
import MosekTools
import JuMP
import Gurobi
import Cbc
import CPLEX



file = "./test/data/tnep/case4_original.m"
file_acdc = "./test/data/tnep/case4_acdc.m"
data = _PM.parse_file(file)
_PMACDC.process_additional_data!(data)

data_bf=data
scs = JuMP.with_optimizer(SCS.Optimizer, max_iters=100000)
ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0)
cplex = JuMP.with_optimizer(CPLEX.Optimizer)
cbc = JuMP.with_optimizer(Cbc.Optimizer, tol=1e-4, print_level=0)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
juniper = JuMP.with_optimizer(Juniper.Optimizer, nl_solver = ipopt, mip_solver= cbc, time_limit= 7200)
#
#
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false, "process_data_internally" => false)


resultDC = _PMACDC.run_tnepopf(file, _PM.DCPPowerModel, gurobi, setting = s)
resultAC = _PMACDC.run_tnepopf(file, _PM.ACPPowerModel, juniper, setting = s)
resultSOCBF = _PMACDC.run_tnepopf_bf(file, _PM.SOCBFPowerModel, gurobi, setting = s)
resultSOCWR = _PMACDC.run_tnepopf(file, _PM.SOCWRPowerModel, gurobi, setting = s)
resultQC     =  _PMACDC.run_tnepopf(file, _PM.QCRMPowerModel, gurobi; setting = s)
# resultSDP     =  _PMACDC.run_tnepopf(file, _PM.SDPWRMPowerModel, mosek; setting = s)
resultLPAC     =  _PMACDC.run_tnepopf(file, _PM.LPACCPowerModel, gurobi; setting = s)
#
_PMACDC.display_results_tnep(resultDC)
_PMACDC.display_results_tnep(resultAC)
_PMACDC.display_results_tnep(resultSOCBF)
_PMACDC.display_results_tnep(resultSOCWR)
_PMACDC.display_results_tnep(resultLPAC)
_PMACDC.display_results_tnep(resultQC)
## TEST ACDC TNEP
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true,"process_data_internally" => false)
resultACDC_dcp = _PMACDC.run_acdctnepopf(file_acdc, _PM.DCPPowerModel, gurobi, setting = s)
resultACDC_acp = _PMACDC.run_acdctnepopf(file_acdc, _PM.ACPPowerModel, juniper, setting = s)
#resultACDC_socbf = _PMACDC.run_acdctnepopf_bf(file_acdc, _PM.SOCBFPowerModel, gurobi, setting = s)  # BF TNEP not implemented in PowerModels.jl
resultACDC_socwr = _PMACDC.run_acdctnepopf(file_acdc, _PM.SOCWRPowerModel, gurobi, setting = s)
resultACDC_qc = _PMACDC.run_acdctnepopf(file_acdc, _PM.QCRMPowerModel, gurobi, setting = s)
resultACDC_lpac = _PMACDC.run_acdctnepopf(file_acdc, _PM.LPACCPowerModel, gurobi, setting = s)

t = 1:2
function build_mn_data(file)
    mp_data = _PM.parse_file(file)
    return _IM.replicate(mp_data, length(t), Set{String}(["source_type", "name", "source_version", "per_unit"]))
end

data1 = build_mn_data(file)
_PMACDC.process_additional_data!(data1)
data_acdc = build_mn_data(file_acdc)
_PMACDC.process_additional_data!(data_acdc)

resultDC1 = _PMACDC.run_mp_tnepopf(data1, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
resultAC1 = _PMACDC.run_mp_tnepopf(data1, _PM.ACPPowerModel, juniper, multinetwork=true; setting = s)
resultBF1 = _PMACDC.run_mp_tnepopf_bf(data1, _PM.SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)
resultLPAC1 = _PMACDC.run_mp_tnepopf(data1, _PM.LPACCPowerModel, juniper, multinetwork=true; setting = s)
resultSOCWR1 = _PMACDC.run_mp_tnepopf(data1, _PM.SOCWRPowerModel, gurobi, multinetwork=true; setting = s)
resultSOCBF1 = _PMACDC.run_mp_tnepopf_bf(data1, _PM.SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)

mp_resultACDC_acp = _PMACDC.run_mp_acdctnepopf(data_acdc, _PM.ACPPowerModel, juniper, multinetwork=true; setting = s)
mp_resultACDC_dcp = _PMACDC.run_mp_acdctnepopf(data_acdc, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
mp_resultACDC_socwr = _PMACDC.run_mp_acdctnepopf(data_acdc, _PM.SOCWRPowerModel, gurobi, multinetwork=true; setting = s)
mp_resultACDC_qc = _PMACDC.run_mp_acdctnepopf(data_acdc, _PM.QCRMPowerModel, gurobi, multinetwork=true; setting = s)
# mp_resultACDC_socbf = _PMACDC.run_mp_acdctnepopf_bf(data_acdc, _PM.SOCBFPowerModel, gurobi, multinetwork=true; setting = s) # BF TNEP not implemented in PowerModels.jl
mp_resultACDC_lpac = _PMACDC.run_mp_acdctnepopf(data_acdc, _PM.LPACCPowerModel, gurobi, multinetwork=true; setting = s)

data1["nw"]["2"]["load"]["2"]["pd"] = 0.5
resultDC2 = _PMACDC.run_mp_tnepopf(data1, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
resultAC2 = _PMACDC.run_mp_tnepopf(data1, _PM.ACPPowerModel, juniper, multinetwork=true; setting = s)
resultBF2 = _PMACDC.run_mp_tnepopf_bf(data1, _PM.SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)
