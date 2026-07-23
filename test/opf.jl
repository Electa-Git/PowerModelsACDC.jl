@testset "Optimal Power Flow" begin
    s = Dict("conv_losses_mp" => true)
    case3 = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case3.m"))
    case5 = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"))
    @testset "solve_acdcopf(file, ...)" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
    end
    @testset "Single network" begin
        @testset "ACPPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(case3, PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5907 rtol=1e-3
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(case5, PowerModels.ACPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 194.14 rtol=1e-3
            end
        end
        @testset "ACRPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(case3, PowerModels.ACRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5907 rtol=1e-3
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(case5, PowerModels.ACRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 194.14 rtol=1e-3
            end
        end
        @testset "DCPPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(case3, PowerModels.DCPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5782.03 rtol=1e-3
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(case5, PowerModels.DCPPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 178.314 rtol=1e-3
            end
        end
        @testset "IVRPowerModel" begin
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf_iv(case5, PowerModels.IVRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 194.16 rtol=1e-3
            end
        end
        @testset "QCRMPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(case3, PowerModels.QCRMPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5780 rtol=1e-3
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(case5, PowerModels.QCRMPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 183.76 rtol=1e-3
            end
        end
        @testset "SOCBFPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf_bf(case3, PowerModels.SOCBFPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5746.7 rtol=1e-3
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf_bf(case5, PowerModels.SOCBFPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 183.91 rtol=1e-3
            end
        end
        @testset "SOCWRPowerModel" begin
            @testset "3-bus case" begin
                result = solve_acdcopf(case3, PowerModels.SOCWRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 5746.7 rtol=1e-3
            end
            @testset "5-bus AC/DC case" begin
                result = solve_acdcopf(case5, PowerModels.SOCWRPowerModel, ipopt; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 183.76 rtol=1e-3
            end
        end
    end
    @testset "Multinetwork" begin
        file = pkgdir(PowerModelsACDC, "test", "data", "case5_2grids_uc_hvdc_strg.m")
        data = prepare_storage_opf_data(file)
        @testset "DCPPowerModel" begin
            s = Dict("conv_losses_mp" => true, "objective_components" => ["gen", "demand"])
            result = solve_acdcopf(data, PowerModels.DCPPowerModel, highs; multinetwork=true, setting=s)
            @test result["termination_status"] == OPTIMAL
            @test result["objective"] ≈ 5.416e6 rtol=1e-3
        end
        @testset "SOCBFPowerModel" begin
            s = Dict("objective_components" => ["gen", "demand"])
            result = solve_acdcopf_bf(data, PowerModels.SOCBFPowerModel, ipopt; multinetwork=true, setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 4.861e6 rtol=1e-3
        end
    end
end
