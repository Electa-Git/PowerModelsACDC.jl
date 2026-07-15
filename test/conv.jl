@testset "Converter" begin
    s = Dict("conv_losses_mp" => true)
    @testset "Droop" begin
        @testset "ACPPowerModel" begin
            @testset "5-bus AC/DC droop case" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_droop.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.35 atol=2e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 atol=2e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 atol=2e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=2e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 atol=2e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 1.00 atol=2e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0079 atol=1e-4
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 0.999987 atol=1e-4
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.997813 atol=1e-4
            end
            @testset "5-bus AC/DC droop case with AC-side reference power" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_droop_acside.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.3450 atol=2e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 atol=2e-3
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 atol=2e-3
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=2e-3
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 atol=2e-3
                @test result["solution"]["bus"]["3"]["vm"] ≈ 1.00 atol=2e-3
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.003738 atol=1e-4
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.00062 atol=1e-4
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 1.000096 atol=1e-4
            end
            @testset "4-bus AC/DC case with AC voltage droop" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case4_acdroop.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED || result["termination_status"] == SLOW_PROGRESS
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.24 atol=1e-2
                @test result["solution"]["gen"]["2"]["pg"] ≈ -1.142 atol=1e-2
                @test result["solution"]["gen"]["1"]["qg"] ≈ -0.057 atol=1e-2
                @test result["solution"]["gen"]["2"]["qg"] ≈ 0.352 atol=1e-2
                @test result["solution"]["bus"]["1"]["vm"] ≈ 1.0 atol=1e-2
                @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=1e-2
                @test result["solution"]["bus"]["2"]["vm"] ≈ 1.0 atol=1e-2
                @test result["solution"]["bus"]["2"]["va"] ≈ 0.00000 atol=1e-2
                @test result["solution"]["bus"]["3"]["vm"] ≈ 0.995 atol=1e-2
                @test result["solution"]["bus"]["3"]["va"] ≈ -0.095 atol=1e-2
                @test result["solution"]["bus"]["4"]["vm"] ≈ 1.0 atol=1e-2
                @test result["solution"]["bus"]["4"]["va"] ≈ 0.332 atol=1e-2
                @test result["solution"]["convdc"]["1"]["pgrid"] ≈ 0.6067 atol=1e-2
                @test result["solution"]["convdc"]["1"]["qgrid"] ≈ -0.2081 atol=1e-2
                @test result["solution"]["convdc"]["3"]["pgrid"] ≈ 0.6067 atol=1e-2
                @test result["solution"]["convdc"]["3"]["qgrid"] ≈ 0.0459 atol=1e-2
                @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.6 atol=1e-2
                @test result["solution"]["convdc"]["2"]["qgrid"] ≈ 0.0932 atol=1e-2
                @test result["solution"]["convdc"]["4"]["pgrid"] ≈ -0.6 atol=1e-2
                @test result["solution"]["convdc"]["4"]["qgrid"] ≈ -0.1 atol=1e-2
            end
        end
        @testset "ACRPowerModel" begin
            @testset "5-bus AC/DC droop case" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_droop.m"), PowerModels.ACRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.34795 atol=2e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 atol=2e-3
                @test result["solution"]["bus"]["1"]["vr"] ≈ 1.06 atol=2e-3
                @test result["solution"]["bus"]["1"]["vi"] ≈ 0.00000 atol=2e-3
                @test result["solution"]["bus"]["2"]["vr"] ≈ 0.999108 atol=1e-2
                @test result["solution"]["bus"]["3"]["vr"] ≈ 0.993324 atol=1e-2
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0079 atol=1e-4
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 0.999987 atol=1e-4
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.997813 atol=1e-4
            end
            @testset "5-bus AC/DC droop case with AC side reference power" begin
                result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_droop_acside.m"), PowerModels.ACRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 0 atol=1e-3
                @test result["solution"]["gen"]["1"]["pg"] ≈ 1.3450847 atol=2e-3
                @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 atol=2e-3
                @test result["solution"]["bus"]["1"]["vr"] ≈ 1.06 atol=2e-3
                @test result["solution"]["bus"]["1"]["vi"] ≈ 0.00000 atol=2e-3
                @test result["solution"]["bus"]["2"]["vr"] ≈ 0.999108 atol=1e-2
                @test result["solution"]["bus"]["3"]["vr"] ≈ 0.993324 atol=1e-2
                @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.003738 atol=1e-4
                @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.0006219 atol=1e-4
                @test result["solution"]["busdc"]["3"]["vm"] ≈ 1.000096 atol=1e-4
            end
        end
    end
end
