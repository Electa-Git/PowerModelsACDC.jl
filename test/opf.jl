@testset "Optimal Power Flow" begin
    s = Dict("conv_losses_mp" => true)
    case3 = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case3.m"))
    case5 = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"))
    @testset "solve_acdcopf(file, ...)" begin
        result = solve_acdcopf(pkgdir(PowerModelsACDC, "test", "data", "case3.m"), PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
    end
    @testset "Bus shunt: ACR and W-space balances scale with |V|^2" begin
        # regression for a nonzero bus shunt at bus 3 of case5: compare the ACP and ACR objectives, pin the SOCWR objective
        case5_shunt = deepcopy(case5)
        case5_shunt["shunt"] = Dict("1" => Dict("index" => 1, "shunt_bus" => 3, "gs" => 0.05, "bs" => 0.5, "status" => 1, "source_id" => Any["bus", 3]))
        acp = solve_acdcopf(case5_shunt, PowerModels.ACPPowerModel, ipopt; setting=s)
        acr = solve_acdcopf(case5_shunt, PowerModels.ACRPowerModel, ipopt; setting=s)
        soc = solve_acdcopf(case5_shunt, PowerModels.SOCWRPowerModel, ipopt; setting=s)
        @test acp["termination_status"] == LOCALLY_SOLVED
        @test acr["termination_status"] == LOCALLY_SOLVED
        @test soc["termination_status"] == LOCALLY_SOLVED
        @test acp["objective"] ≈ 204.42 rtol=1e-3
        @test acr["objective"] ≈ acp["objective"] rtol=1e-4   # 205.43 with the |V|^4 term
        @test soc["objective"] ≈ 190.27 rtol=1e-3            # 189.82 with the w^2 term
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
