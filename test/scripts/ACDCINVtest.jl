using PowerModelsACDC
using PowerModels
using InfrastructureModels
using Ipopt
# using CPLEX
using SCS
using Juniper
using Mosek
using MosekTools
using JuMP
using Gurobi
using Cbc



file = "./test/data/case4_original.m"

data = _PM.parse_file(file)
PowerModelsACDC.process_additional_data!(data)
PowerModelsACDCInv.process_additional_data!(data)

data_bf=data
scs = JuMP.with_optimizer(SCS.Optimizer, max_iters=100000)
ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-4, print_level=0)

# cplex = JuMP.with_optimizer(CPLEX.Optimizer)
cbc = JuMP.with_optimizer(Cbc.Optimizer, tol=1e-4, print_level=0)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer)
mosek = JuMP.with_optimizer(Mosek.Optimizer)


juniper = JuMP.with_optimizer(Juniper.Optimizer, nl_solver = ipopt, mip_solver= cbc, time_limit= 7200)
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false, "process_data_internally" => false)


resultDC = run_tnepopf(file, DCPPowerModel, gurobi, setting = s)
resultAC = run_tnepopf(file, ACPPowerModel, juniper, setting = s)
resultSOCBF = run_tnepopf_bf(file, SOCBFPowerModel, gurobi, setting = s)
resultSOCWR = run_tnepopf(file, SOCWRPowerModel, gurobi, setting = s)
resultQC     =  run_tnepopf(file, QCRMPowerModel, gurobi; setting = s)
resultSDP     =  run_tnepopf(file, SDPWRMPowerModel, gurobi; setting = s)
resultLPAC     =  run_tnepopf(file, LPACCPowerModel, gurobi; setting = s)

PowerModelsACDCInv.display_results(resultDC)
PowerModelsACDCInv.display_results(resultAC)
PowerModelsACDCInv.display_results(resultSOCBF)
PowerModelsACDCInv.display_results(resultSOCWR)
PowerModelsACDCInv.display_results(resultLPAC)
PowerModelsACDCInv.display_results(resultQC)
##

t = 1:2
function build_mn_data(file)
    mp_data = _PM.parse_file(file)
    return InfrastructureModels.replicate(mp_data, length(t), Set{String}(["source_type", "name", "source_version", "per_unit"]))
end

data1 = build_mn_data(file)
PowerModelsACDC.process_additional_data!(data1)
PowerModelsACDCInv.process_additional_data!(data1)

resultDC1 = run_mp_tnepopf(data1, DCPPowerModel, gurobi, multinetwork=true; setting = s)
resultAC1 = run_mp_tnepopf(data1, ACPPowerModel, juniper, multinetwork=true; setting = s)
resultBF1 = run_mp_tnepopf_bf(data1, SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)

data1["nw"]["2"]["load"]["2"]["pd"] = 0.5
resultDC2 = run_mp_tnepopf(data1, DCPPowerModel, gurobi, multinetwork=true; setting = s)
resultAC2 = run_mp_tnepopf(data1, ACPPowerModel, juniper, multinetwork=true; setting = s)
resultBF2 = run_mp_tnepopf_bf(data1, SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)
