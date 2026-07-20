@testset "DC generator" begin
    @testset "Model" begin
        @testset "ACPPowerModel" begin
            @testset "5-bus AC/DC case with DC generator" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_gendc.m"), PowerModels.ACPPowerModel, ipopt)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.556 rtol=1e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 rtol=1e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.000 atol=1e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 rtol=1e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 0.9906 rtol=1e-3
                @test result["solution"]["convdc"]["2"]["pgrid"] ≈ 0.000 atol=1e-3
                @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.3642 rtol=1e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0077 rtol=1e-3
            end
        end
    end
    @testset "Droop" begin
        @testset "ACPPowerModel" begin
            @testset "5-bus AC/DC droop case with DC generator" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_gendc_droop.m"), PowerModels.ACPPowerModel, ipopt)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.3502 rtol=1e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 rtol=1e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.000 atol=1e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 rtol=1e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 1.00 rtol=1e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0079 rtol=1e-3
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.0000 rtol=1e-3
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.9978 rtol=1e-3
            end
        end
    end
    @testset "Variable power" begin
        @testset "ACPPowerModel" begin
            @testset "5-bus AC/DC case with DC generator" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_gendc.m"), PowerModels.ACPPowerModel, ipopt)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 165.7 rtol=1e-3
            end
        end
    end
end
