s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
@testset "test ac polar pf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcpf("../test/data/case5_acdc.m", ACPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 0; atol = 1e-2)

        @test isapprox(result["solution"]["gen"]["1"]["pg"], 1.3494; atol = 2e-3)
        @test isapprox(result["solution"]["gen"]["2"]["pg"], 0.40; atol = 2e-3)

        @test isapprox(result["solution"]["bus"]["1"]["vm"], 1.06; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["1"]["va"], 0.00000; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["2"]["vm"], 1.00; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["3"]["vm"], 0.995; atol = 2e-3)

        @test isapprox(result["solution"]["convdc"]["2"]["pgrid"], -0.1954; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["3"]["pdc"], 0.36421; atol = 2e-3)
        @test isapprox(result["solution"]["busdc"]["1"]["vm"], 1.008; atol = 2e-3)

    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcpf("../test/data/case5_2grids.m", ACPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 0; atol = 1e-2)

        @test isapprox(result["solution"]["gen"]["1"]["pg"], 1.9326; atol = 2e-3)
        @test isapprox(result["solution"]["gen"]["4"]["pg"], 0.40; atol = 2e-3)

        @test isapprox(result["solution"]["bus"]["1"]["vm"], 1.06; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["1"]["va"], 0.00000; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["3"]["vm"], 0.987; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["7"]["va"], -0.0065; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["10"]["vm"], 0.972; atol = 2e-3)

        @test isapprox(result["solution"]["convdc"]["1"]["pgrid"], 0.6; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["2"]["pdc"], 0.56872; atol = 2e-3)
        @test isapprox(result["solution"]["busdc"]["1"]["vm"], 1.015; atol = 2e-3)
    end
    # REMOVED for TRAVIS, otherwise case ok
    # @testset "24-bus rts ac dc case with three zones" begin
    #     result = run_acdcpf("../test/data/case24_3zones_acdc.m", ACPPowerModel, ipopt_solver; setting = s)
    #
    #     @test result["termination_status"] == LOCALLY_SOLVED
    #     @test isapprox(result["objective"], 0; atol = 1e-2)
    #
    #     @test isapprox(result["solution"]["gen"]["65"]["pg"], 1.419; atol = 2e-3)
    #     @test isapprox(result["solution"]["gen"]["65"]["qg"], -1.29648; atol = 2e-3)
    #
    #
    #     @test isapprox(result["solution"]["bus"]["101"]["vm"], 1.035; atol = 2e-3)
    #     @test isapprox(result["solution"]["bus"]["101"]["va"], -0.1389; atol = 2e-3)
    #     @test isapprox(result["solution"]["bus"]["205"]["vm"], 1.0318; atol = 2e-3)
    #     @test isapprox(result["solution"]["bus"]["301"]["vm"], 1.026266; atol = 2e-3)
    #
    #     @test isapprox(result["solution"]["convdc"]["2"]["pgrid"], -0.753; atol = 2e-3)
    #     @test isapprox(result["solution"]["convdc"]["3"]["pdc"], -1.37301; atol = 2e-3)
    #     @test isapprox(result["solution"]["busdc"]["5"]["vm"], 1.01731; atol = 2e-3)
    # end
end


@testset "test dc pf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcpf("../test/data/case5_acdc.m", DCPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 0; atol = 1e-2)

        @test isapprox(result["solution"]["gen"]["1"]["pg"], 1.2169; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["5"]["va"], -0.09289; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["3"]["va"], -0.0826; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["2"]["pgrid"], -0.2831; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["3"]["pdc"], -0.3385; atol = 2e-3)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcpf("../test/data/case24_3zones_acdc.m", DCPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 0; atol = 1e-2)
        @test isapprox(result["solution"]["gen"]["65"]["pg"], 1.419; atol = 2e-3)

        @test isapprox(result["solution"]["bus"]["119"]["va"], 0.17208; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["224"]["va"], 0.07803; atol = 2e-3)

        @test isapprox(result["solution"]["convdc"]["2"]["pgrid"], -0.753; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["3"]["pdc"], 1.43579; atol = 2e-3)
    end
end
