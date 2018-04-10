@testset "test ac polar pf" begin
    @testset "5-bus ac dc case" begin
        result = run_ac_pf("../test/data/case5_acdc.m", ipopt_solver, setting = Dict("output" => Dict("branch_flows" => true)))

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)

        @test isapprox(result["solution"]["gen"]["2"]["pg"], 1.600063; atol = 1e-3)
        @test isapprox(result["solution"]["gen"]["3"]["pg"], 0.0; atol = 1e-3)

        @test isapprox(result["solution"]["bus"]["1"]["vm"], 1.10000; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["1"]["va"], 0.00000; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["2"]["vm"], 0.92617; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["3"]["vm"], 0.90000; atol = 1e-3)

        @test isapprox(result["solution"]["dcline"]["1"]["pf"],  0.10; atol = 1e-5)
        @test isapprox(result["solution"]["dcline"]["1"]["pt"], -0.10; atol = 1e-5)
        @test isapprox(result["solution"]["dcline"]["1"]["qf"], -0.403045; atol = 1e-5)
        @test isapprox(result["solution"]["dcline"]["1"]["qt"],  0.0647562; atol = 1e-5)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_pf("../test/data/case5_2grids.m", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_pf("../test/data/case24_3zones_acdc.m", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)
    end
end


@testset "test dc pf" begin
    @testset "5-bus ac dc case" begin
        result = run_dc_pf("../test/data/case5_acdc.m", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)

        @test isapprox(result["solution"]["gen"]["1"]["pg"], 1.54994; atol = 1e-3)

        @test isapprox(result["solution"]["bus"]["1"]["va"],  0.00000; atol = 1e-5)
        @test isapprox(result["solution"]["bus"]["2"]["va"],  0.09147654582; atol = 1e-5)
        @test isapprox(result["solution"]["bus"]["3"]["va"], -0.28291891895; atol = 1e-5)
    end
    @testset "5-bus asymmetric case" begin
        result = run_dc_pf("../test/data/matpower/case5_asym.m", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)
    end
    @testset "6-bus case" begin
        result = run_dc_pf("../test/data/matpower/case6.m", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)
        @test isapprox(result["solution"]["bus"]["1"]["va"], 0.00000; atol = 1e-5)
        @test isapprox(result["solution"]["bus"]["4"]["va"], 0.00000; atol = 1e-5)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_pf("../test/data/case24_3zones_acdc.m", DCPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)
    end
end


@testset "test soc pf" begin
    @testset "5-bus ac dc case" begin
        result = run_pf("../test/data/case5_acdc.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)

        @test result["solution"]["gen"]["1"]["pg"] >= 1.480

        @test isapprox(result["solution"]["gen"]["2"]["pg"], 1.600063; atol = 1e-3)
        @test isapprox(result["solution"]["gen"]["3"]["pg"], 0.0; atol = 1e-3)

        @test isapprox(result["solution"]["bus"]["1"]["vm"], 1.09999; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["2"]["vm"], 0.92616; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["3"]["vm"], 0.89999; atol = 1e-3)

        @test isapprox(result["solution"]["dcline"]["1"]["pf"],  0.10; atol = 1e-4)
        @test isapprox(result["solution"]["dcline"]["1"]["pt"], -0.10; atol = 1e-4)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_pf("../test/data/case24_3zones_acdc.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)
    end
end



@testset "test soc distflow pf_bf" begin
    @testset "5-bus ac dc case" begin
        result = run_pf_bf("../test/data/case5_acdc.m", SOCDFPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)

        @test result["solution"]["gen"]["1"]["pg"] >= 1.480

        @test isapprox(result["solution"]["gen"]["2"]["pg"], 1.600063; atol = 1e-3)
        @test isapprox(result["solution"]["gen"]["3"]["pg"], 0.0; atol = 1e-3)

        @test isapprox(result["solution"]["bus"]["1"]["vm"], 1.09999; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["2"]["vm"], 0.92616; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["3"]["vm"], 0.89999; atol = 1e-3)

        @test isapprox(result["solution"]["dcline"]["1"]["pf"],  0.10; atol = 1e-4)
        @test isapprox(result["solution"]["dcline"]["1"]["pt"], -0.10; atol = 1e-4)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_pf_bf("../test/data/case24_3zones_acdc.m", SOCDFPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 0; atol = 1e-2)
    end
end


@testset "test sdp pf" begin
    #=
    #seems to be having an issue on linux (04/02/18)
    @testset "5-bus ac dc case" begin
        result = run_pf("../test/data/case5_acdc.m", SDPWRMPowerModel, scs_solver)

        @test result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-2)

        @test result["solution"]["gen"]["1"]["pg"] >= 1.480

        @test isapprox(result["solution"]["gen"]["2"]["pg"], 1.600063; atol = 1e-3)
        @test isapprox(result["solution"]["gen"]["3"]["pg"], 0.0; atol = 1e-3)

        @test isapprox(result["solution"]["bus"]["1"]["vm"], 1.09999; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["2"]["vm"], 0.92616; atol = 1e-3)
        @test isapprox(result["solution"]["bus"]["3"]["vm"], 0.89999; atol = 1e-3)

        @test isapprox(result["solution"]["dcline"]["1"]["pf"],  0.10; atol = 1e-4)
        @test isapprox(result["solution"]["dcline"]["1"]["pt"], -0.10; atol = 1e-4)
    end
    =#
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_pf("../test/data/case24_3zones_acdc.m", SDPWRMPowerModel, scs_solver)

        @test result["status"] == :Optimal
        @test isapprox(result["objective"], 0; atol = 1e-2)
    end
end
