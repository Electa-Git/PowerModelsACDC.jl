import PowerModelsACDC
const _PMACDC = PowerModelsACDC
import PowerModels
const _PM = PowerModels
import Ipopt
import Memento
import JuMP


file = "./test/data/case3120sp_acdc.m"


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
    ploss_tot = conv["pgrid"] + conv["pdc"]
    print("Pac: ", conv["pconv"], " Pdc: ", conv["pdc"], " Ploss: ", ploss, " Plosstot: ", ploss_tot, "\n")
end

print("IVR RESULTS")
print("Objective:", resultIVR["objective"],"\n")
for (c, conv) in resultIVR["solution"]["convdc"]
    ploss = conv["pconv"] + conv["pdc"]
    bus =  data["convdc"][c]["busac_i"]
    ploss_tot = (conv["iik_r"] * resultIVR["solution"]["bus"]["$bus"]["vr"] + conv["iik_i"] * resultIVR["solution"]["bus"]["$bus"]["vi"]) + conv["pdc"]
    print("Pac: ", conv["pconv"], " Pdc: ", conv["pdc"], " Ploss: ", ploss, " Plosstot: ", ploss_tot, "\n")
end

# il = (data["load"]["1"]["pd"] * resultIVR["solution"]["bus"]["2"]["vr"]+data["load"]["1"]["qd"] * resultIVR["solution"]["bus"]["2"]["vi"]) / (resultIVR["solution"]["bus"]["2"]["vr"]^2 + resultIVR["solution"]["bus"]["2"]["vi"]^2)


# so = resultIVR["solution"]
# ir_balance = (so["gen"]["2"]["crg"] - il) - (so["convdc"]["1"]["iik_r"] + so["branch"]["1"]["cr_to"] + so["branch"]["3"]["cr_fr"] + so["branch"]["4"]["cr_fr"] + so["branch"]["5"]["cr_fr"]) 


# for (b, bus) in resultIVR["solution"]["bus"]
#     vm = sqrt(bus["vi"]^2 + bus["vr"]^2)
#     print(b, ": ", vm, "\n")
# end

# for (c, conv) in resultIVR["solution"]["convdc"]
#     iik = sqrt(conv["iik_r"]^2 + conv["iik_i"]^2)
#     ikc = sqrt(conv["ikc_r"]^2 + conv["ikc_i"]^2)
#     ic = sqrt(conv["ic_r"]^2 + conv["ic_i"]^2)
#     print(c, "-iik: ", iik, "\n")
#     print(c, "-ikc: ", ikc, "\n")
#     print(c, "-ic: ", ic, "\n")

#     vk = sqrt(conv["vk_r"]^2 + conv["vk_i"]^2)
#     vc = sqrt(conv["vc_r"]^2 + conv["vc_i"]^2)
#     print(c, "-vk: ", vk, "\n")
#     print(c, "-vc: ", vc, "\n")
# end
# pg_acp = resultAC["solution"]["gen"]["1"]["pg"] + resultAC["solution"]["gen"]["2"]["pg"] 
# pg_ivr = resultIVR["solution"]["gen"]["1"]["pg"] + resultIVR["solution"]["gen"]["2"]["pg"] 

# print("pac: ", pg_acp, "\n")
# print("pivr: ", pg_ivr, "\n")



