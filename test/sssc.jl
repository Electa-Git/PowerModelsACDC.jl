@testset "Static Synchronous Series Compensator" begin
    data = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_sssc.m"))
    s = Dict("conv_losses_mp" => true, "objective_components" => ["gen"])
    @testset "ACPPowerModel" begin
        result = solve_acdcopf(data, PowerModels.ACPPowerModel, ipopt; setting=s)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test result["objective"] ≈ 16702 rtol=1e-3
        @test result["solution"]["sssc"]["1"]["pf"] ≈ -1.5009 rtol=1e-3
    end
    @testset "ACRPowerModel" begin
        result = solve_acdcopf(data, PowerModels.ACRPowerModel, ipopt; setting=s)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test result["objective"] ≈ 16702 rtol=1e-3
        @test result["solution"]["sssc"]["1"]["pf"] ≈ -1.5009 rtol=1e-3
    end
    @testset "DCPPowerModel" begin
        result = solve_acdcopf(data, PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 16565 rtol=1e-3
        @test result["solution"]["sssc"]["1"]["pf"] ≈ -1.5747 rtol=1e-3
    end
end
