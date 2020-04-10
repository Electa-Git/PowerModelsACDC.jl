s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
@testset "test ac polar opf" begin
    @testset "3-bus case" begin
        result = run_acdcopf("../test/data/case3.m", ACPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5907; atol = 1e0)
    end
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", ACPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 194.14; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcopf("../test/data/case5_2grids.m", ACPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 397.36; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", ACPPowerModel, ipopt_solver; setting = s)

    @test isapprox(result["objective"], 150228.15; atol = 1e0)
    end
end

@testset "test dc opf" begin
    @testset "3-bus case" begin
        result = run_acdcopf("../test/data/case3.m", DCPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5638.97; atol = 1e0)
    end
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", DCPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 171.69; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcopf("../test/data/case5_2grids.m", DCPPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 371.01; atol = 1e0)
    end

    @testset "24-bus rts ac dc case with three zones" begin
       result = run_acdcopf("../test/data/case24_3zones_acdc.m", DCPPowerModel, ipopt_solver; setting = s)

       @test result["termination_status"] == LOCALLY_SOLVED
       @test isapprox(result["objective"], 143714.75; atol = 1e0)
    end
end

@testset "test soc (BIM) opf" begin
    @testset "3-bus case" begin
        result = run_acdcopf("../test/data/case3.m", SOCWRPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5746.7; atol = 1e0)
    end
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", SOCWRPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 183.76; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcopf("../test/data/case5_2grids.m", SOCWRPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 363.50; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", SOCWRPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 150156.24; atol = 1e0)
    end
end

@testset "test soc distflow opf_bf" begin
    @testset "3-bus case" begin
        result = run_acdcopf_bf("../test/data/case3.m", SOCBFPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5746.7; atol = 1e0)
    end
    @testset "5-bus ac dc case" begin
        result = run_acdcopf_bf("../test/data/case5_acdc.m", SOCBFPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 183.91; atol = 1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = run_acdcopf_bf("../test/data/case5_2grids.m", SOCBFPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 363.50; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf_bf("../test/data/case24_3zones_acdc.m", SOCBFPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 150156.26; atol = 1e0)
    end
end

@testset "test qc opf" begin
    @testset "3-bus case" begin
        result = run_acdcopf("../test/data/case3.m", QCRMPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5780; atol = 1e0)
    end
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", QCRMPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 183.76; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", QCRMPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 150156.25; atol = 1e0)
    end
end

@testset "test qc opf with trilinear convexhull relaxation" begin
    @testset "3-bus case" begin
        result = run_acdcopf("../test/data/case3.m", QCRMPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5780; atol = 1e0)
    end
    @testset "5-bus ac dc case" begin
        result = run_acdcopf("../test/data/case5_acdc.m", QCRMPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 183.76; atol = 1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = run_acdcopf("../test/data/case24_3zones_acdc.m", QCRMPowerModel, ipopt_solver; setting = s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"],  150156.25; atol = 1e0)
    end
end
