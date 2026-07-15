@testset "Static Synchronous Series Compensator" begin
    data = PowerModels.parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_sssc.m"))
    process_additional_data!(data)
    s = Dict("conv_losses_mp" => true, "objective_components" => ["gen"])
    @testset "ACPPowerModel" begin
        result = solve_acdcopf(data, PowerModels.ACPPowerModel, ipopt; setting=s)
        @test result["objective"] ≈ 16702.0 atol=1
        @test result["solution"]["sssc"]["1"]["pf"] ≈ -1.50085 atol=1e-2
    end
    @testset "ACRPowerModel" begin
        result = solve_acdcopf(data, PowerModels.ACRPowerModel, ipopt; setting=s)
        @test result["objective"] ≈ 16702.0 atol=1
        @test result["solution"]["sssc"]["1"]["pf"] ≈ -1.50085 atol=1e-2
    end
    @testset "DCPPowerModel" begin
        result = solve_acdcopf(data, PowerModels.DCPPowerModel, highs; setting=s)
        @test result["objective"] ≈ 16565.1 atol=1
        @test result["solution"]["sssc"]["1"]["pf"] ≈ -1.57465 atol=1e-2
    end
end
