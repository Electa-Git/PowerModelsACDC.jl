using PowerModelsACDC
import PowerModels
import Ipopt

# ------------------------------------------------------------
# 1. Load the test cases and configure the solver
# ------------------------------------------------------------

# Five-bus AC/DC network, with and without a DC PFC
file = pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m")
file_pfc = pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_pfc.m")

data = parse_file(file)
data_pfc = parse_file(file_pfc)

ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)

s = Dict("conv_losses_mp" => true)

# ------------------------------------------------------------
# 2. Uncongested network
# ------------------------------------------------------------

# Solve the AC/DC OPF without and with the PFC
# In this case, the PFC is expected to remain inactive

resultIVR = solve_acdcopf_iv(file, PowerModels.IVRPowerModel, ipopt; setting=s)
resultIVR_pfc = solve_acdcopf_iv(file_pfc, PowerModels.IVRPowerModel, ipopt; setting=s)

println("------------------------------------------")
println("OPF RESULTS - UNCONGESTED NETWORK")
println("------------------------------------------")

println("NO PFC status: ", resultIVR["termination_status"])
println("PFC status: ", resultIVR_pfc["termination_status"])
println("NO PFC objective: ", resultIVR["objective"])
println("PFC objective: ", resultIVR_pfc["objective"])

savings = 100 * (resultIVR["objective"] - resultIVR_pfc["objective"]) / resultIVR["objective"]

println("Cost reduction (%): ", round(savings, digits=3))

# PFC operating variables
println("PFC operating variables:")
println("Duty cycle: ", resultIVR_pfc["solution"]["pfc"]["1"]["duty_cycle"])
println("Capacitor voltage: ", resultIVR_pfc["solution"]["pfc"]["1"]["c_voltage"])

# PFC currents
println("PFC currents:")
println("I_12_fr: ", resultIVR_pfc["solution"]["pfc"]["1"]["pfc_current_12_fr"])
println("I_12_to: ", resultIVR_pfc["solution"]["pfc"]["1"]["pfc_current_12_to"])
println("I_13_fr: ", resultIVR_pfc["solution"]["pfc"]["1"]["pfc_current_13_fr"])
println("I_13_to: ", resultIVR_pfc["solution"]["pfc"]["1"]["pfc_current_13_to"])

println("------------------------------------------")

# ------------------------------------------------------------
# 3. Congested network
# ------------------------------------------------------------

# Create copies of the original data
data_cong = deepcopy(data)
data_pfc_cong = deepcopy(data_pfc)

# Reduce the capacity of DC branch 1 from 1.0 to 0.1 p.u.
red = 0.1

data_cong["branchdc"]["1"]["rateA"] = red
data_pfc_cong["branchdc"]["1"]["rateA"] = red

# Solve the modified network without and with the PFC
resultIVR_cong = solve_acdcopf_iv(data_cong, PowerModels.IVRPowerModel, ipopt; setting=s)
resultIVR_pfc_cong = solve_acdcopf_iv(data_pfc_cong, PowerModels.IVRPowerModel, ipopt; setting=s)

println("------------------------------------------")
println("OPF RESULTS - REDUCED DC BRANCH CAPACITY")
println("------------------------------------------")

println("NO PFC status: ", resultIVR_cong["termination_status"])
println("PFC status: ", resultIVR_pfc_cong["termination_status"])
println("NO PFC objective: ", resultIVR_cong["objective"])
println("PFC objective: ", resultIVR_pfc_cong["objective"])

savings_cong = 100 * (resultIVR_cong["objective"] - resultIVR_pfc_cong["objective"]) / resultIVR_cong["objective"]

println("Cost reduction (%): ", round(savings_cong, digits=3))

# PFC operating variables
println("PFC operating variables:")
println("Duty cycle: ", resultIVR_pfc_cong["solution"]["pfc"]["1"]["duty_cycle"])
println("Capacitor voltage: ", resultIVR_pfc_cong["solution"]["pfc"]["1"]["c_voltage"])

# PFC currents
println("PFC currents:")
println("I_12_fr: ", resultIVR_pfc_cong["solution"]["pfc"]["1"]["pfc_current_12_fr"])
println("I_12_to: ", resultIVR_pfc_cong["solution"]["pfc"]["1"]["pfc_current_12_to"])
println("I_13_fr: ", resultIVR_pfc_cong["solution"]["pfc"]["1"]["pfc_current_13_fr"])
println("I_13_to: ", resultIVR_pfc_cong["solution"]["pfc"]["1"]["pfc_current_13_to"])

# ------------------------------------------------------------
# 4. Verify the PFC duty-cycle relationship
# ------------------------------------------------------------

# The PFC constraint is:
# Vc * ((1-d)*I13 - d*I12) = 0
#
# For active operation (Vc != 0), the expression inside
# the parentheses should be approximately zero

d = resultIVR_pfc_cong["solution"]["pfc"]["1"]["duty_cycle"]
Vc = resultIVR_pfc_cong["solution"]["pfc"]["1"]["c_voltage"]
I12 = resultIVR_pfc_cong["solution"]["pfc"]["1"]["pfc_current_12_fr"]
I13 = resultIVR_pfc_cong["solution"]["pfc"]["1"]["pfc_current_13_fr"]

residual = (1 - d) * I13 - d * I12

println("PFC duty-cycle constraint:")
println("Inner residual: ", residual)
println("Full constraint residual: ", Vc * residual)
println("------------------------------------------")