@testset "Phase Shifting Transformer" begin
    data = PowerModels.parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_pst_3_grids.m"))
    process_additional_data!(data)
    s = Dict("conv_losses_mp" => true, "objective_components" => ["gen", "demand"])
    @testset "DCPPowerModel" begin
        result = solve_acdcopf(data, PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 24021.7 atol=1
        @test result["solution"]["gen"]["3"]["pg"] ≈ 0.955232 atol=1e-1
        @test result["solution"]["branch"]["2"]["pt"] ≈ -1.20165 atol=1e-2
        @test result["solution"]["convdc"]["4"]["ptf_to"] ≈ 0.977907 atol=1e-2
    end
end
