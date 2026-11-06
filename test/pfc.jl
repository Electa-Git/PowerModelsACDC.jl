@testset "Power Flow Controller" begin
    data = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"))
    data_pfc = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_pfc.m"))
    s = Dict("conv_losses_mp" => true)
    @testset "IVRPowerModel - Uncongested" begin
        result = solve_acdcopf_iv(data, PowerModels.IVRPowerModel, ipopt; setting=s)
        result_pfc = solve_acdcopf_iv(data_pfc, PowerModels.IVRPowerModel, ipopt; setting=s)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test result_pfc["termination_status"] == LOCALLY_SOLVED
        @test result["objective"] ≈ 194.16 rtol=1e-3
        @test result_pfc["objective"] ≈ result["objective"] rtol=1e-3
        @test result_pfc["solution"]["pfc"]["1"]["c_voltage"] ≈ 0.0 atol=1e-6
        @test result_pfc["solution"]["pfc"]["1"]["pfc_current_12_fr"] ≈ -result_pfc["solution"]["pfc"]["1"]["pfc_current_12_to"] atol=1e-6
        @test result_pfc["solution"]["pfc"]["1"]["pfc_current_13_fr"] ≈ -result_pfc["solution"]["pfc"]["1"]["pfc_current_13_to"] atol=1e-6
    end
    @testset "IVRPowerModel - Congested" begin
        data_cong = deepcopy(data)
        data_pfc_cong = deepcopy(data_pfc)
        data_cong["branchdc"]["1"]["rateA"] = 0.1
        data_pfc_cong["branchdc"]["1"]["rateA"] = 0.1
        result = solve_acdcopf_iv(data_cong, PowerModels.IVRPowerModel, ipopt; setting=s)
        result_pfc = solve_acdcopf_iv(data_pfc_cong, PowerModels.IVRPowerModel, ipopt; setting=s)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test result_pfc["termination_status"] == LOCALLY_SOLVED
        @test result["objective"] ≈ 197.62 rtol=1e-3
        @test result_pfc["objective"] ≈ 195.65 rtol=1e-3
        @test result_pfc["objective"] < result["objective"]
        @test result_pfc["solution"]["pfc"]["1"]["c_voltage"] ≈ -0.01159421 rtol=1e-3
        @test result_pfc["solution"]["pfc"]["1"]["duty_cycle"] ≈ 0.16891517 rtol=1e-3
        @test result_pfc["solution"]["pfc"]["1"]["pfc_current_12_fr"] ≈ -result_pfc["solution"]["pfc"]["1"]["pfc_current_12_to"] atol=1e-6
        @test result_pfc["solution"]["pfc"]["1"]["pfc_current_13_fr"] ≈ -result_pfc["solution"]["pfc"]["1"]["pfc_current_13_to"] atol=1e-6
        @test ((1 - result_pfc["solution"]["pfc"]["1"]["duty_cycle"]) * result_pfc["solution"]["pfc"]["1"]["pfc_current_13_fr"] - result_pfc["solution"]["pfc"]["1"]["duty_cycle"] * result_pfc["solution"]["pfc"]["1"]["pfc_current_12_fr"]) ≈ 0.0 atol=1e-6
    end
end