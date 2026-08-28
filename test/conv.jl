@testset "Converter" begin
    @testset "Droop" begin
        @testset "ACPPowerModel" begin
            @testset "5-bus AC/DC droop case" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_droop.m"), PowerModels.ACPPowerModel, ipopt)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 rtol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.35 rtol=1e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 rtol=1e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=1e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 rtol=1e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 1.00 rtol=1e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0079 rtol=1e-3
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 0.999987 rtol=1e-3
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.997813 rtol=1e-3
            end
            @testset "5-bus AC/DC droop case with AC-side reference power" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_droop_acside.m"), PowerModels.ACPPowerModel, ipopt)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 rtol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.346 rtol=1e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 rtol=1e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=1e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 rtol=1e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 1.00 rtol=1e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.003738 rtol=1e-3
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.00062 rtol=1e-3
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 1.000096 rtol=1e-3
            end
            @testset "4-bus AC/DC case with AC voltage droop" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case4_acdroop.m"), PowerModels.ACPPowerModel, ipopt)
                @test result["termination_status"] ∈ (LOCALLY_SOLVED, SLOW_PROGRESS)
                @test result["objective"] ≈ 0 rtol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.2476 rtol=1e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ -1.142 rtol=1e-3
                @test result["solution"]["gen"]["1"]["qg"] ≈ -0.05605 rtol=1e-3
                @test result["solution"]["gen"]["2"]["qg"] ≈ 0.352 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.0 rtol=1e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.0000 atol=1e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.0 rtol=1e-3
                @test result["solution"]["bus"]["2"]["va"] ≈ 0.0000 atol=1e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 0.995 rtol=1e-3
                @test result["solution"]["bus"]["3"]["va"] ≈ -0.09583 rtol=1e-3
                @test result["solution"]["bus"]["4"]["vm"] ≈ 1.0 rtol=1e-3
                @test result["solution"]["bus"]["4"]["va"] ≈ 0.332 rtol=1e-3
                @test result["solution"]["convdc"]["1"]["pgrid"] ≈ 0.6152 rtol=1e-3
                @test result["solution"]["convdc"]["1"]["qgrid"] ≈ -0.2099 rtol=1e-3
                @test result["solution"]["convdc"]["3"]["pgrid"] ≈ 0.6149 rtol=1e-3
                @test result["solution"]["convdc"]["3"]["qgrid"] ≈ 0.04505 rtol=1e-3
                @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.6 rtol=1e-3
                @test result["solution"]["convdc"]["2"]["qgrid"] ≈ 0.0932 rtol=1e-3
                @test result["solution"]["convdc"]["4"]["pgrid"] ≈ -0.6 rtol=1e-3
                @test result["solution"]["convdc"]["4"]["qgrid"] ≈ -0.1 rtol=1e-3
            end
        end
        @testset "ACRPowerModel" begin
            @testset "5-bus AC/DC droop case" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_droop.m"), PowerModels.ACRPowerModel, ipopt)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 rtol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.348 rtol=1e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vr"] ≈ 1.06 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vi"] ≈ 0.0000 atol=1e-3
                @test result["solution"]["bus"]["2"]["vr"] ≈ 0.9991 rtol=1e-3
                @test result["solution"]["bus"]["3"]["vr"] ≈ 0.9977 rtol=1e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0079 rtol=1e-3
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.0000 rtol=1e-3
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.9978 rtol=1e-3
            end
            @testset "5-bus AC/DC droop case with AC side reference power" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_droop_acside.m"), PowerModels.ACRPowerModel, ipopt)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 rtol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.3451 rtol=1e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vr"] ≈ 1.06 rtol=1e-3
                @test result["solution"]["bus"]["1"]["vi"] ≈ 0.0000 atol=1e-3
                @test result["solution"]["bus"]["2"]["vr"] ≈ 0.9991 rtol=1e-3
                @test result["solution"]["bus"]["3"]["vr"] ≈ 0.9969 rtol=1e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0038 rtol=1e-3
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.0006 rtol=1e-3
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 1.0001 rtol=1e-3
            end
        end
    end
end
