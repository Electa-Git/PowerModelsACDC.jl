# This file contains unit tests for various OPF (Optimal Power Flow) formulations
# in the PowerModelsACDC package. Each testset runs OPF on different test cases
# and checks solver status and objective value accuracy.

# Common solver settings used in all tests
s = Dict("conv_losses_mp" => true)

# ---------------------------------------------------------------------------
# AC Polar OPF Tests
# ---------------------------------------------------------------------------
@testset "test ac polar opf" begin
    @testset "3-bus case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.ACPPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5907; atol=1e0)
    end
    @testset "5-bus ac dc case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.ACPPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 194.14; atol=1e0)
    end

    @testset "5-bus ac dc case with DC generator" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_gendc.m"), PowerModels.ACPPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 165.7; atol=1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.ACPPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 397.36; atol=1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.ACPPowerModel, ipopt_solver; setting=s)

        @test isapprox(result["objective"], 150228.15; atol=1e0)
    end
end
# ---------------------------------------------------------------------------
# AC Rectangular OPF Tests
# ---------------------------------------------------------------------------
@testset "test ac rectangular opf" begin
    @testset "3-bus case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.ACRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5907; atol=1e0)
    end
    @testset "5-bus ac dc case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.ACRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 194.14; atol=1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.ACRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 397.36; atol=1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.ACRPowerModel, ipopt_solver; setting=s)

        @test isapprox(result["objective"], 150228.15; atol=1e0)
    end
end
# ---------------------------------------------------------------------------
# IVR OPF Tests
# ---------------------------------------------------------------------------
@testset "test IVR OPF" begin
    @testset "5-bus ac dc case" begin
        result = solve_acdcopf_iv(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.IVRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 194.16; atol=1e0)
    end

    @testset "39-bus ac dc case" begin
        result = solve_acdcopf_iv(pkgdir(PowerModelsACDC, "test", "data", "case39_acdc.m"), PowerModels.IVRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 41968.88; atol=1e0)
    end
end
# ---------------------------------------------------------------------------
# DC OPF Tests
# ---------------------------------------------------------------------------
@testset "test dc opf" begin
    @testset "3-bus case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.DCPPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5782.03; atol=1e0)
    end
    @testset "5-bus ac dc case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.DCPPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 178.314; atol=1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.DCPPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 379.842; atol=1e0)
    end

    @testset "24-bus rts ac dc case with three zones" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.DCPPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 144791.0; atol=1e0)
    end
end
# ---------------------------------------------------------------------------
# SOC (BIM) OPF Tests
# ---------------------------------------------------------------------------
@testset "test soc (BIM) opf" begin
    @testset "3-bus case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.SOCWRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5746.7; atol=1e0)
    end
    @testset "5-bus ac dc case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.SOCWRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 183.76; atol=1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.SOCWRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 363.50; atol=1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.SOCWRPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 150156.24; atol=1e0)
    end
end
# ---------------------------------------------------------------------------
# SOC DistFlow OPF_BF Tests
# ---------------------------------------------------------------------------
@testset "test soc distflow opf_bf" begin
    @testset "3-bus case" begin
        result = solve_acdcopf_bf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.SOCBFPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5746.7; atol=1e0)
    end
    @testset "5-bus ac dc case" begin
        result = solve_acdcopf_bf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.SOCBFPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 183.91; atol=1e0)
    end
    @testset "5-bus ac dc case with 2 seperate ac grids" begin
        result = solve_acdcopf_bf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.SOCBFPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 363.50; atol=1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = solve_acdcopf_bf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.SOCBFPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 150156.26; atol=1e0)
    end
end
# ---------------------------------------------------------------------------
# QC OPF Tests
# ---------------------------------------------------------------------------
@testset "test qc opf" begin
    @testset "3-bus case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.QCRMPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5780; atol=1e0)
    end
    @testset "5-bus ac dc case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.QCRMPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 183.76; atol=1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.QCRMPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 150156.25; atol=1e0)
    end
end
# ---------------------------------------------------------------------------
# QC OPF with Trilinear Convex Hull Relaxation Tests
# ---------------------------------------------------------------------------
@testset "test qc opf with trilinear convexhull relaxation" begin
    @testset "3-bus case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.QCRMPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 5780; atol=1e0)
    end
    @testset "5-bus ac dc case" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.QCRMPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 183.76; atol=1e0)
    end
    @testset "24-bus rts ac dc case with three zones" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.QCRMPowerModel, ipopt_solver; setting=s)

        @test result["termination_status"] == LOCALLY_SOLVED
        @test isapprox(result["objective"], 150156.25; atol=1e0)
    end
end
