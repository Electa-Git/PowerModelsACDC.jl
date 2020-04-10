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



file = "./test/data/tnep/case4_original.m"
data = _PM.parse_file(file)
_PMACDC.process_additional_data!(data)

data_bf=data
scs = JuMP.with_optimizer(SCS.Optimizer, max_iters=100000)
ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0)
# cplex = JuMP.with_optimizer(CPLEX.Optimizer)
cbc = JuMP.with_optimizer(Cbc.Optimizer, tol=1e-4, print_level=0)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
juniper = JuMP.with_optimizer(Juniper.Optimizer, nl_solver = ipopt, mip_solver= cbc, time_limit= 7200)


s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false, "process_data_internally" => false)


resultDC = _PMACDC.run_tnepopf(file, _PM.DCPPowerModel, gurobi, setting = s)
resultAC = _PMACDC.run_tnepopf(file, _PM.ACPPowerModel, juniper, setting = s)
resultSOCBF = _PMACDC.run_tnepopf_bf(file, _PM.SOCBFPowerModel, gurobi, setting = s)
resultSOCWR = _PMACDC.run_tnepopf(file, _PM.SOCWRPowerModel, gurobi, setting = s)
resultQC     =  _PMACDC.run_tnepopf(file, _PM.QCRMPowerModel, gurobi; setting = s)
# resultSDP     =  _PMACDC.run_tnepopf(file, _PM.SDPWRMPowerModel, gurobi; setting = s)
resultLPAC     =  _PMACDC.run_tnepopf(file, _PM.LPACCPowerModel, gurobi; setting = s)

_PMACDC.display_results_tnep(resultDC)
_PMACDC.display_results_tnep(resultAC)
_PMACDC.display_results_tnep(resultSOCBF)
_PMACDC.display_results_tnep(resultSOCWR)
_PMACDC.display_results_tnep(resultLPAC)
_PMACDC.display_results_tnep(resultQC)
##

t = 1:2
function build_mn_data(file)
    mp_data = _PM.parse_file(file)
    return _IM.replicate(mp_data, length(t), Set{String}(["source_type", "name", "source_version", "per_unit"]))
end

data1 = build_mn_data(file)
_PMACDC.process_additional_data!(data1)

resultDC1 = _PMACDC.run_mp_tnepopf(data1, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
resultAC1 = _PMACDC.run_mp_tnepopf(data1, _PM.ACPPowerModel, juniper, multinetwork=true; setting = s)
resultBF1 = _PMACDC.run_mp_tnepopf_bf(data1, _PM.SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)

data1["nw"]["2"]["load"]["2"]["pd"] = 0.5
resultDC2 = _PMACDC.run_mp_tnepopf(data1, _PM.DCPPowerModel, gurobi, multinetwork=true; setting = s)
resultAC2 = _PMACDC.run_mp_tnepopf(data1, _PM.ACPPowerModel, juniper, multinetwork=true; setting = s)
resultBF2 = _PMACDC.run_mp_tnepopf_bf(data1, _PM.SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)
