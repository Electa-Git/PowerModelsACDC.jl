@testset "Optimal Power Flow" begin
    s = Dict("conv_losses_mp" => true)
    @testset "Single network" begin
        @testset "ACPPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5907 atol=1e0
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 194.14 atol=1e0
            end
            @testset "5-bus AC/DC case with 2 separate AC grids" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 397.36 atol=1e0
            end
            @testset "24-bus RTS AC/DC case with 3 zones" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["objective"] ≈ 150228.15 atol=1e0
            end
        end
        @testset "ACRPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.ACRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5907 atol=1e0
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.ACRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 194.14 atol=1e0
            end
            @testset "5-bus AC/DC case with 2 separate AC grids" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.ACRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 397.36 atol=1e0
            end
            @testset "24-bus RTS AC/DC case with 3 zones" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.ACRPowerModel, ipopt; setting=s)
                @test result["objective"] ≈ 150228.15 atol=1e0
            end
        end
        @testset "IVRPowerModel" begin
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf_iv(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.IVRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 194.16 atol=1e0
            end
            @testset "39-bus AC/DC case" begin
                result = solve_acdcopf_iv(pkgdir(PowerModelsACDC, "test", "data", "case39_acdc.m"), PowerModels.IVRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 41968.88 atol=1e0
            end
        end
        @testset "DCPPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.DCPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5782.03 atol=1e0
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.DCPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 178.314 atol=1e0
            end
            @testset "5-bus AC/DC case with 2 separate AC grids" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.DCPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 379.842 atol=1e0
            end
            @testset "24-bus RTS AC/DC case with 3 zones" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.DCPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 144791.0 atol=1e0
            end
        end
        @testset "SOCWRPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.SOCWRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5746.7 atol=1e0
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.SOCWRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 183.76 atol=1e0
            end
            @testset "5-bus AC/DC case with 2 separate AC grids" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.SOCWRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 363.50 atol=1e0
            end
            @testset "24-bus RTS AC/DC case with 3 zones" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.SOCWRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 150156.24 atol=1e0
            end
        end
        @testset "SOCBFPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf_bf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.SOCBFPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5746.7 atol=1e0
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf_bf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.SOCBFPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 183.91 atol=1e0
            end
            @testset "5-bus AC/DC case with 2 separate AC grids" begin
                result = solve_acdcopf_bf(pkgdir(PowerModelsACDC, "test", "data", "case5_2grids.m"), PowerModels.SOCBFPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 363.50 atol=1e0
            end
            @testset "24-bus RTS AC/DC case with 3 zones" begin
                result = solve_acdcopf_bf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.SOCBFPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 150156.26 atol=1e0
            end
        end
        @testset "QCRMPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.QCRMPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5780 atol=1e0
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"), PowerModels.QCRMPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 183.76 atol=1e0
            end
            @testset "24-bus RTS AC/DC case with 3 zones" begin
                result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case24_3zones_acdc.m"), PowerModels.QCRMPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 150156.25 atol=1e0
            end
        end
    end
    @testset "Multinetwork" begin
        @testset "DCPPowerModel" begin
            file = pkgdir(PowerModelsACDC, "test", "data", "case5_2grids_uc_hvdc_strg.m")
            mn_data = prepare_storage_opf_data(file)
            s = Dict("conv_losses_mp" => true, "objective_components" => ["gen", "demand"])
            result = solve_acdcopf(mn_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
            @test result["objective"] ≈ 5.41642e6 atol=1e2
        end
    end
end
