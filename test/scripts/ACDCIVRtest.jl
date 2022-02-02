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
resultACPM = _PM.run_opf(file, _PM.ACPPowerModel, ipopt; setting = s)
resultIVR = _PMACDC.run_acdcopf_iv(file, _PM.IVRPowerModel, ipopt; setting = s)

print("ACP RESULTS")
print("Objective:", resultAC["objective"],"\n")
for (c, conv) in resultAC["solution"]["convdc"]
    ploss = conv["pconv"] + conv["pdc"]
    print("Pac: ", conv["pconv"], " Pdc: ", conv["pdc"], " Ploss: ", ploss, "\n")
end

print("IVR RESULTS")
print("Objective:", resultIVR["objective"],"\n")
for (c, conv) in resultIVR["solution"]["convdc"]
    ploss = conv["pconv"] + conv["pdc"]
    print("Pac: ", conv["pconv"], " Pdc: ", conv["pdc"], " Ploss: ", ploss, "\n")
end

il = (data["load"]["1"]["pd"] * resultIVR["solution"]["bus"]["2"]["vr"]+data["load"]["1"]["qd"] * resultIVR["solution"]["bus"]["2"]["vi"]) / (resultIVR["solution"]["bus"]["2"]["vr"]^2 + resultIVR["solution"]["bus"]["2"]["vi"]^2)


so = resultIVR["solution"]
ir_balance = (so["gen"]["2"]["crg"] - il) - (so["convdc"]["1"]["iik_r"] + so["branch"]["1"]["cr_to"] + so["branch"]["3"]["cr_fr"] + so["branch"]["4"]["cr_fr"] + so["branch"]["5"]["cr_fr"]) 

print(ir_balance)