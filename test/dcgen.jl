@testset "DC generator" begin
    s = Dict("conv_losses_mp" => true)
    @testset "Model" begin
        @testset "ACPPowerModel" begin
            @testset "5-bus AC/DC case with DC generator" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_gendc.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.55552 atol=2e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 atol=2e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 atol=2e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=2e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 atol=2e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 0.990603 atol=2e-3
                @test result["solution"]["convdc"]["2"]["pgrid"] ≈ 0.0 atol=2e-3
                @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.364213 atol=2e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.00772 atol=2e-3
            end
        end
    end
    @testset "Droop" begin
        @testset "ACPPowerModel" begin
            @testset "5-bus AC/DC droop case with DC generator" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_gendc_droop.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.35016 atol=2e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 atol=2e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 atol=2e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=2e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 atol=2e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 1.00 atol=2e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.00789 atol=1e-4
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 0.999996 atol=1e-4
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.997813 atol=1e-4
            end
        end
    end
    @testset "Variable power" begin
        @testset "ACPPowerModel" begin
            @testset "5-bus AC/DC case with DC generator" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_gendc.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 165.7 atol=1e0
            end
        end
    end
end
