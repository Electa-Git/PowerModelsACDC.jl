@testset "test ac polar opf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 194.14; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcopf("../test/data/case5_2grids.m", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 397.36; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalInfeasible
        #@test isapprox(result["objective"], 79805; atol = 1e0)
    end
end

@testset "test dc opf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", DCPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 178.31; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcopf("../test/data/case5_2grids.m", DCPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 379.84; atol = 1e0)
    end

    @testset "24-bus rts ac dc case with three zones" begin
       result = run_acdcopf("../test/data/case24_3zones_acdc.m", DCPPowerModel, ipopt_solver)

       @test result["status"] == :LocalOptimal
       @test isapprox(result["objective"], 144791.39; atol = 1e0)
    end
end

@testset "test soc (BIM) opf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 183.76; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcopf("../test/data/case5_2grids.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 363.50; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 150580.80; atol = 1e0)
    end
end

@testset "test soc distflow opf_bf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", SOCDFPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 183.91; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcopf("../test/data/case5_2grids.m", SOCDFPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 363.50; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", SOCDFPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 151208.37; atol = 1e0)
    end
end

@testset "test qc opf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 183.76; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 150580.81; atol = 1e0)
    end
end

@testset "test qc opf with trilinear convexhull relaxation" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", QCWRTriPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 183.76; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", QCWRTriPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"],  150591; atol = 1e0)
    end
end


@testset "test sdp opf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", SDPWRMPowerModel, scs_solver)

        @test result["status"] == :Optimal
        @test isapprox(result["objective"], 194.12; atol = 1e0)
    end
    # TODO replace this with smaller case, way too slow for unit testing
    # @testset "24-bus rts ac dc case with three zones" begin
    #    result = run_acdcopf("../test/data/case24_3zones_acdc.m", SDPWRMPowerModel, scs_solver)
    #
    #    @test result["status"] == :Optimal
    #    @test isapprox(result["objective"], 151574.34; atol = 1e0)
    # end
end
