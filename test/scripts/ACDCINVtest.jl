using PowerModelsACDC
import PowerModels
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
data = PowerModels.parse_file(file)
process_additional_data!(data)

data_bf=data
scs = JuMP.optimizer_with_attributes(SCS.Optimizer, "max_iters" => 100000)
ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-4, "print_level" => 0)
cplex = JuMP.optimizer_with_attributes(CPLEX.Optimizer)
cbc = JuMP.optimizer_with_attributes(Cbc.Optimizer, "tol" => 1e-4, "print_level" => 0)
gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer)
mosek = JuMP.optimizer_with_attributes(Mosek.Optimizer)
juniper = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt, "mip_solver" => cbc, "time_limit" => 7200)
#
#
s = Dict("conv_losses_mp" => false, "process_data_internally" => false)


resultDC = solve_tnep(file, PowerModels.DCPPowerModel, gurobi, setting = s)
resultAC = solve_tnep(file, PowerModels.ACPPowerModel, juniper, setting = s)
resultSOCBF = solve_tnep(file, PowerModels.SOCBFPowerModel, gurobi, setting = s)
resultSOCWR = solve_tnep(file, PowerModels.SOCWRPowerModel, gurobi, setting = s)
resultQC     =  solve_tnep(file, PowerModels.QCRMPowerModel, gurobi; setting = s)
# resultSDP     =  solve_tnep(file, PowerModels.SDPWRMPowerModel, mosek; setting = s)
resultLPAC     =  solve_tnep(file, PowerModels.LPACCPowerModel, gurobi; setting = s)
#
display_results_tnep(resultDC)
display_results_tnep(resultAC)
display_results_tnep(resultSOCBF)
display_results_tnep(resultSOCWR)
display_results_tnep(resultLPAC)
display_results_tnep(resultQC)
## TEST ACDC TNEP
s = Dict("conv_losses_mp" => true,"process_data_internally" => false)
resultACDC_dcp = solve_tnep(file_acdc, PowerModels.DCPPowerModel, gurobi, setting = s)
resultACDC_acp = solve_tnep(file_acdc, PowerModels.ACPPowerModel, juniper, setting = s)
#resultACDC_socbf = solve_tnep(file_acdc, PowerModels.SOCBFPowerModel, gurobi, setting = s)  # BF TNEP not implemented in PowerModels.jl
resultACDC_socwr = solve_tnep(file_acdc, PowerModels.SOCWRPowerModel, gurobi, setting = s)
resultACDC_qc = solve_tnep(file_acdc, PowerModels.QCRMPowerModel, gurobi, setting = s)
resultACDC_lpac = solve_tnep(file_acdc, PowerModels.LPACCPowerModel, gurobi, setting = s)

t = 1:2
function build_mn_data(file)
    mp_data = PowerModels.parse_file(file)
    return PowerModels.replicate(mp_data, length(t); global_keys = Set{String}(["source_type", "name", "source_version", "per_unit"]))
end

data1 = build_mn_data(file)
process_additional_data!(data1)
data_acdc = build_mn_data(file_acdc)
process_additional_data!(data_acdc)

resultDC1 = solve_tnep(data1, PowerModels.DCPPowerModel, gurobi, multinetwork=true; setting = s)
resultAC1 = solve_tnep(data1, PowerModels.ACPPowerModel, juniper, multinetwork=true; setting = s)
resultBF1 = solve_tnep(data1, PowerModels.SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)
resultLPAC1 = solve_tnep(data1, PowerModels.LPACCPowerModel, juniper, multinetwork=true; setting = s)
resultSOCWR1 = solve_tnep(data1, PowerModels.SOCWRPowerModel, gurobi, multinetwork=true; setting = s)
resultSOCBF1 = solve_tnep(data1, PowerModels.SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)

mp_resultACDC_acp = solve_tnep(data_acdc, PowerModels.ACPPowerModel, juniper, multinetwork=true; setting = s)
mp_resultACDC_dcp = solve_tnep(data_acdc, PowerModels.DCPPowerModel, gurobi, multinetwork=true; setting = s)
mp_resultACDC_socwr = solve_tnep(data_acdc, PowerModels.SOCWRPowerModel, gurobi, multinetwork=true; setting = s)
mp_resultACDC_qc = solve_tnep(data_acdc, PowerModels.QCRMPowerModel, gurobi, multinetwork=true; setting = s)
# mp_resultACDC_socbf = solve_tnep(data_acdc, PowerModels.SOCBFPowerModel, gurobi, multinetwork=true; setting = s) # BF TNEP not implemented in PowerModels.jl
mp_resultACDC_lpac = solve_tnep(data_acdc, PowerModels.LPACCPowerModel, gurobi, multinetwork=true; setting = s)

data1["nw"]["2"]["load"]["2"]["pd"] = 0.5
resultDC2 = solve_tnep(data1, PowerModels.DCPPowerModel, gurobi, multinetwork=true; setting = s)
resultAC2 = solve_tnep(data1, PowerModels.ACPPowerModel, juniper, multinetwork=true; setting = s)
resultBF2 = solve_tnep(data1, PowerModels.SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)
