@testset "Phase Shifting Transformer" begin
    data = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_pst_3_grids.m"))
    s = Dict("conv_losses_mp" => true, "objective_components" => ["gen", "demand"])
    @testset "DCPPowerModel" begin
        result = solve_acdcopf(data, PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 24022 rtol=1e-3
        @test result["solution"]["gen"]["3"]["pg"] ≈ 0.9552 rtol=1e-3
        @test result["solution"]["branch"]["2"]["pt"] ≈ -1.2017 rtol=1e-3
        @test result["solution"]["convdc"]["4"]["ptf_to"] ≈ 0.9779 rtol=1e-3
    end
end
