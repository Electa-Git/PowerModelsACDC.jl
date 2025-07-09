@testset "test sacdc pf" begin
    @testset "5-bus ac dc case" begin
        result = solve_sacdcpf("../test/data/case5_acdc.m")

        @test result["termination_status"] == "Converged"
        @test isapprox(result["objective"], 0.0; atol = 1e-2)

        @test isapprox(result["solution"]["gen"]["1"]["pg"], 1.32323; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["5"]["va"], -0.07172; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["3"]["va"], -0.06676; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["2"]["pgrid"], 0.22012; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["3"]["pdc"], 0.36422; atol = 2e-3)
    end
    @testset "39-bus ac dc case" begin
        result = solve_sacdcpf("../test/data/case39_acdc.m")

        @test result["termination_status"] == "Converged"
        @test isapprox(result["objective"], 0.0; atol = 1e-2)

        @test isapprox(result["solution"]["gen"]["7"]["pg"], 5.60000; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["20"]["va"], -0.39552; atol = 2e-3)
        @test isapprox(result["solution"]["bus"]["27"]["va"], -0.48778; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["2"]["pgrid"], -0.60000; atol = 2e-3)
        @test isapprox(result["solution"]["convdc"]["3"]["pdc"], -0.58734; atol = 2e-3)
    end
end