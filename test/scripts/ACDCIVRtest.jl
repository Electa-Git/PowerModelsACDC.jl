import PowerModelsACDC
const _PMACDC = PowerModelsACDC
import PowerModels
const _PM = PowerModels
import Ipopt
import Memento
import JuMP


file_case5acdc = "./test/data/case5_acdc.m"
file = file_case5acdc

data = _PM.parse_file(file)

_PMACDC.process_additional_data!(data)

ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)

resultAC = _PMACDC.run_acdcopf(file, _PM.ACPPowerModel, ipopt; setting = s)
resultIVR = _PMACDC.run_acdcopf_iv(file, _PM.IVRPowerModel, ipopt; setting = s)