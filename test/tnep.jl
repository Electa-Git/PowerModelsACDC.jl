@testset "Transmission Network Expansion Planning" begin
    s = Dict("conv_losses_mp" => true)
    case4 = parse_file(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"))
    case9 = parse_file(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case9_test.m"); tnep=true)
    @testset "solve_tnep(file, ...)" begin
        result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"), PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
    end
    @testset "Single network" begin
        @testset "ACPPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(case4, PowerModels.ACPPowerModel, juniper; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 348.0219 rtol=1e-3
                @test result["solution"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-3
                @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -0.631 rtol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["pconv"] ≈ -0.6189 rtol=1e-3
            end
            @testset "9-bus case" begin
                result = solve_tnep(case9, PowerModels.ACPPowerModel, juniper; setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 10.7 rtol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0.8325 rtol=1e-3
                @test result["solution"]["busdc_ne"]["2"]["vm"] ≈ 0.9966 rtol=1e-3
            end
        end
        @testset "DCPPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(case4, PowerModels.DCPPowerModel, highs; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 329.95456 rtol=1e-3
                @test result["solution"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-3
                @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -1.009 rtol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["pconv"] ≈ -1 rtol=1e-3
            end
            @testset "9-bus case" begin
                result = solve_tnep(case9, PowerModels.DCPPowerModel, highs; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 10.7 rtol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0.4104 rtol=1e-3
            end
        end
        @testset "LPACCPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(case4, PowerModels.LPACCPowerModel, scip; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 333.095 rtol=1e-3
                @test result["solution"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-3
                @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -1.0110 rtol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["pconv"] ≈ -1 rtol=1e-3
            end
            @testset "9-bus case" begin
                result = solve_tnep(case9, PowerModels.LPACCPowerModel, scip; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 10.7 rtol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0.8693 rtol=1e-3
                @test result["solution"]["busdc_ne"]["2"]["phivdcm_ne"] ≈ -0.003694 rtol=1e-3
            end
        end
        @testset "QCRMPowerModel" begin
            @test_throws(
                "variable_ne_branch_voltage is not yet supported for QC formulations",
                solve_tnep(case9, PowerModels.QCRMPowerModel, scip; setting=s)
            )
        end
        @testset "SOCBFPowerModel" begin
            @testset "4-bus case" begin
                @test_throws(
                    "Candidate AC branches are not yet implemented in TNEP for BF formulations.",
                    solve_tnep(case4, PowerModels.SOCBFPowerModel, scip; setting=s)
                )
            end
            @testset "9-bus case" begin
                result = solve_tnep(case9, PowerModels.SOCBFPowerModel, scip; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 10.7 rtol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 1.064 rtol=1e-3
                @test result["solution"]["busdc_ne"]["2"]["wdc_ne"] ≈ 1.012 rtol=1e-3
            end
        end
        @testset "SOCWRPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(case4, PowerModels.SOCWRPowerModel, scip; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 348.0 rtol=1e-3
                @test result["solution"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-3
                @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -0.6275 rtol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["pconv"] ≈ -0.6153 rtol=1e-3
            end
            @testset "9-bus case" begin
                result = solve_tnep(case9, PowerModels.SOCWRPowerModel, scip; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 10.7 rtol=1e-3
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
            end
        end
    end
    @testset "Multinetwork" begin
        case4 = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"))
        case6 = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case6_strg.m"))
        case9 = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case9_test.m"))
        @testset "ACPPowerModel" begin
            @testset "9-bus case" begin
                result = solve_tnep(case9, PowerModels.ACPPowerModel, juniper; multinetwork=true, setting=s)
                @test result["termination_status"] == LOCALLY_SOLVED
                @test result["objective"] ≈ 21.4 rtol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["pf"] ≈ 0.8325 rtol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"] ≈ 0.8325 rtol=1e-3
                @test result["solution"]["nw"]["1"]["busdc_ne"]["2"]["vm"] ≈ 0.9966 rtol=1e-3
                @test result["solution"]["nw"]["2"]["busdc_ne"]["2"]["vm"] ≈ 0.9966 rtol=1e-3
            end
        end
        @testset "DCPPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(case4, PowerModels.DCPPowerModel, highs, multinetwork=true; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 659.9 rtol=1e-3
                @test result["solution"]["nw"]["1"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"] ≈ -1.009 rtol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["3"]["pf"] ≈ -1.009 rtol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["pconv"] ≈ -1 rtol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["pconv"] ≈ -1 rtol=1e-3
            end
            @testset "6-bus case" begin
                result = solve_tnep(case6, PowerModels.DCPPowerModel, highs; multinetwork=true, setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 52.67 rtol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["2"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["pf"] ≈ 1.3 rtol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"] ≈ 1.3 rtol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["pt"] ≈ -1.3 rtol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pt"] ≈ -1.3 rtol=1e-3
            end
        end
        @testset "LPACCPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(case4, PowerModels.LPACCPowerModel, scip, multinetwork=true; setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 666.2 rtol=1e-3
                @test result["solution"]["nw"]["1"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"] ≈ -1.011 rtol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["3"]["pf"] ≈ -1.011 rtol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["pconv"] ≈ -1 rtol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["pconv"] ≈ -1 rtol=1e-3
            end
        end
        @testset "QCRMPowerModel" begin
            @test_throws(
                "variable_ne_branch_voltage is not yet supported for QC formulations",
                solve_tnep(case4, PowerModels.QCRMPowerModel, scip; multinetwork=true, setting=s)
            )
        end
        @testset "SOCBFPowerModel" begin
            @testset "4-bus case" begin
                @test_throws(
                    "Candidate AC branches are not yet implemented in TNEP for BF formulations.",
                    solve_tnep(case4, PowerModels.SOCBFPowerModel, scip; multinetwork=true, setting=s)
                )
            end
            @testset "9-bus case" begin
                result = solve_tnep(case9, PowerModels.SOCBFPowerModel, scip; multinetwork=true, setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 21.4 rtol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["pf"] ≈ 1.064 rtol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"] ≈ 1.064 rtol=1e-3
                @test result["solution"]["nw"]["1"]["busdc_ne"]["2"]["wdc_ne"] ≈ 1.012 rtol=1e-3
                @test result["solution"]["nw"]["2"]["busdc_ne"]["2"]["wdc_ne"] ≈ 1.012 rtol=1e-3
            end
        end
        @testset "SOCWRPowerModel" begin
            @testset "9-bus case" begin
                result = solve_tnep(case9, PowerModels.SOCWRPowerModel, scip; multinetwork=true, setting=s)
                @test result["termination_status"] == OPTIMAL
                @test result["objective"] ≈ 21.4 rtol=1e-3
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
                @test result["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-3
            end
        end
    end
end
