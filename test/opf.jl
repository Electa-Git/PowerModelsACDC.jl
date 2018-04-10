@testset "test ac polar opf" begin
    @testset "5-bus ac dc case" begin
        result = run_acdc_opf("../test/data/case5_acdc.m", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5907; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_ac_opf("../test/data/case5_2grids.m", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 18269; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_opf("../test/data/case24_3zones_acdc.m", ACPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 79805; atol = 1e0)
    end
end

@testset "test dc opf" begin
    @testset "5-bus ac dc case" begin
        result = run_dc_opf("../test/data/case5_acdc.m", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5782; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_opf("../test/data/case5_2grids.m", DCPPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 15051; atol = 1e0)
    end

    @testset "24-bus rts ac dc case with three zones" begin
       result = run_opf("../test/data/case24_3zones_acdc.m", DCPPowerModel, ipopt_solver)

       @test result["status"] == :LocalOptimal
       @test isapprox(result["objective"], 79804; atol = 1e0)
    end
end

@testset "test soc (BIM) opf" begin
    @testset "5-bus ac dc case" begin
        result = run_opf("../test/data/case5_acdc.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5746.7; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_opf("../test/data/case5_2grids.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 15051; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_opf("../test/data/case24_3zones_acdc.m", SOCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 70690.7; atol = 1e0)
    end
end

@testset "test soc distflow opf_bf" begin
    @testset "5-bus ac dc case" begin
        result = run_opf_bf("../test/data/case5_acdc.m", SOCDFPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5746.7; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_opf_bf("../test/data/case5_2grids.m", SOCDFPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 15051; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_opf_bf("../test/data/case24_3zones_acdc.m", SOCDFPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 70690.7; atol = 1e0)
    end
end

@testset "test qc opf" begin
    @testset "5-bus ac dc case" begin
        result = run_opf("../test/data/case5_acdc.m", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5780; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_opf("../test/data/case24_3zones_acdc.m", QCWRPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 76599.9; atol = 1e0)
    end
end

@testset "test qc opf with trilinear convexhull relaxation" begin
    @testset "5-bus ac dc case" begin
        result = run_opf("../test/data/case5_acdc.m", QCWRTriPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5817.58; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_opf("../test/data/case24_3zones_acdc.m", QCWRTriPowerModel, ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 76752.3; atol = 1e0)
    end
end


@testset "test sdp opf" begin
    @testset "5-bus ac dc case" begin
        result = run_opf("../test/data/case5_acdc.m", SDPWRMPowerModel, scs_solver)

        @test result["status"] == :Optimal
        @test isapprox(result["objective"], 5851.3; atol = 1e0)
    end
    # TODO replace this with smaller case, way too slow for unit testing
    #@testset "24-bus rts ac dc case with three zones" begin
    #    result = run_opf("../test/data/case24_3zones_acdc.m", SDPWRMPowerModel, scs_solver)

    #    @test result["status"] == :Optimal
    #    @test isapprox(result["objective"], 75153; atol = 1e0)
    #end
end
