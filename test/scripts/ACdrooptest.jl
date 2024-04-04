using PowerModels, JuMP, Ipopt

casename = "case4_acdroop"

file = "./test/data/$casename.m"
data = PowerModels.parse_file(file)
PowerModelsACDC.process_additional_data!(data)

ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false)
result = run_acdcpf(data, ACPPowerModel, ipopt; setting = s)
println(result["termination_status"])