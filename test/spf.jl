@testset "Sequential Power Flow" begin
    @testset "5-bus AC/DC case" begin
        result = solve_sacdcpf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"))
        @test result["termination_status"] == "Converged"
        @test result["objective"] ≈ 0.0 atol=1e-3
        @test result["solution"]["gen"]["1"]["pg"] ≈ 1.32323 rtol=1e-3
        @test result["solution"]["bus"]["5"]["va"] ≈ -0.07172 rtol=1e-3
        @test result["solution"]["bus"]["3"]["va"] ≈ -0.06676 rtol=1e-3
        @test result["solution"]["convdc"]["2"]["pgrid"] ≈ 0.22012 rtol=1e-3
        @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.36422 rtol=1e-3
    end
    @testset "39-bus AC/DC case" begin
        result = solve_sacdcpf(pkgdir(PowerModelsACDC, "test", "data", "case39_acdc.m"))
        @test result["termination_status"] == "Converged"
        @test result["objective"] ≈ 0.0 rtol=1e-3
        @test result["solution"]["gen"]["7"]["pg"] ≈ 5.60000 rtol=1e-3
        @test result["solution"]["bus"]["20"]["va"] ≈ -0.39552 rtol=1e-3
        @test result["solution"]["bus"]["27"]["va"] ≈ -0.48778 rtol=1e-3
        @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.60000 rtol=1e-3
        @test result["solution"]["convdc"]["3"]["pdc"] ≈ -0.58734 rtol=1e-3
    end
end
