@testset "Power Flow" begin
    s = Dict("conv_losses_mp" => true)
    @testset "ACPPowerModel" begin
        @testset "5-bus AC/DC case" begin
            result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 0 atol=1e-2
            @test result["solution"]["gen"]["1"]["pg"] ≈ 1.3494 atol=2e-3
            @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 atol=2e-3
            @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 atol=2e-3
            @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=2e-3
            @test result["solution"]["bus"]["2"]["vm"] ≈ 1.00 atol=2e-3
            @test result["solution"]["bus"]["3"]["vm"] ≈ 0.995 atol=2e-3
            @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.1954 atol=2e-3
            @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.36421 atol=2e-3
            @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.008 atol=2e-3
        end
        @testset "5-bus AC/DC case with 2 separate AC grids" begin
            result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 0 atol=1e-2
            @test result["solution"]["gen"]["1"]["pg"] ≈ 1.9326 atol=2e-3
            @test result["solution"]["gen"]["4"]["pg"] ≈ 0.40 atol=2e-3
            @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 atol=2e-3
            @test result["solution"]["bus"]["1"]["va"] ≈ 0.00000 atol=2e-3
            @test result["solution"]["bus"]["3"]["vm"] ≈ 0.987 atol=2e-3
            @test result["solution"]["bus"]["7"]["va"] ≈ -0.0065 atol=2e-3
            @test result["solution"]["bus"]["10"]["vm"] ≈ 0.972 atol=2e-3
            @test result["solution"]["convdc"]["1"]["pgrid"] ≈ 0.6 atol=2e-3
            @test result["solution"]["convdc"]["2"]["pdc"] ≈ 0.56872 atol=2e-3
            @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.015 atol=2e-3
        end
        # @testset "24-bus RTS AC/DC case with 3 zones" begin
        #     result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
        #     @test result["termination_status"] == LOCALLY_SOLVED
        #     @test result["objective"] ≈ 0 atol=1e-2
        #     @test result["solution"]["gen"]["65"]["pg"] ≈ 1.419 atol=2e-3
        #     @test result["solution"]["gen"]["65"]["qg"] ≈ -1.29648 atol=2e-3
        #     @test result["solution"]["bus"]["101"]["vm"] ≈ 1.035 atol=2e-3
        #     @test result["solution"]["bus"]["101"]["va"] ≈ -0.1389 atol=2e-3
        #     @test result["solution"]["bus"]["205"]["vm"] ≈ 1.0318 atol=2e-3
        #     @test result["solution"]["bus"]["301"]["vm"] ≈ 1.026266 atol=2e-3
        #     @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.753 atol=2e-3
        #     @test result["solution"]["convdc"]["3"]["pdc"] ≈ -1.37301 atol=2e-3
        #     @test result["solution"]["busdc"]["5"]["vm"] ≈ 1.012 atol=2e-3
        # end
    end
    @testset "ACRPowerModel" begin
        @testset "5-bus AC/DC case" begin
            result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.ACRPowerModel, ipopt; setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 0 atol=1e-2
            @test result["solution"]["gen"]["1"]["pg"] ≈ 1.34771 atol=2e-3
            @test result["solution"]["gen"]["2"]["pg"] ≈ 0.40 atol=2e-3
            @test result["solution"]["bus"]["1"]["vr"] ≈ 1.06 atol=2e-3
            @test result["solution"]["bus"]["1"]["vi"] ≈ 0.00000 atol=2e-3
            @test result["solution"]["bus"]["2"]["vr"] ≈ 0.999115 atol=2e-3
            @test result["solution"]["bus"]["3"]["vr"] ≈ 0.993036 atol=2e-3
            @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.00773 atol=1e-4
            @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.0 atol=1e-4
            @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.99769 atol=1e-4
        end
    end
    @testset "DCPPowerModel" begin
        @testset "5-bus AC/DC case" begin
            result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.DCPPowerModel, ipopt; setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 0 atol=1e-2
            @test result["solution"]["gen"]["1"]["pg"] ≈ 1.28313 atol=2e-3
            @test result["solution"]["bus"]["5"]["va"] ≈ -0.09668 atol=2e-3
            @test result["solution"]["bus"]["3"]["va"] ≈ -0.08918 atol=2e-3
            @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.21686 atol=2e-3
            @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.36051 atol=2e-3
        end
        @testset "24-bus RTS AC/DC case with 3 zones" begin
            result = solve_acdcpf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.DCPPowerModel, ipopt; setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 0 atol=1e-2
            @test result["solution"]["gen"]["65"]["pg"] ≈ 1.419 atol=2e-3
            @test result["solution"]["bus"]["119"]["va"] ≈ 0.17208 atol=2e-3
            @test result["solution"]["bus"]["224"]["va"] ≈ 0.07803 atol=2e-3
            @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.753 atol=2e-3
            @test result["solution"]["convdc"]["3"]["pdc"] ≈ -1.39167 atol=2e-3
        end
    end
end
