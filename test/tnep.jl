@testset "Transmission Network Expansion Planning" begin
    s = Dict("conv_losses_mp" => true)
    @testset "Single network, <:AbstractPowerModel" begin
        @testset "ACPPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"), PowerModels.ACPPowerModel, juniper; setting=s)
                @test result["objective"] ≈ 348.0219 atol=1e-1
                @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -0.631 atol=1e-2
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-2
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["convdc_ne"]["1"]["pconv"] ≈ -0.618 atol=1e-2
                @test result["solution"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-2
            end
            @testset "9-bus case" begin
                result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case9_test.m"), PowerModels.ACPPowerModel, juniper; setting=s)
                @test result["objective"] ≈ 10.7 atol=1e-1
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0.841 atol=1e-1 #0.838 0.8360707133374305
                @test result["solution"]["busdc_ne"]["2"]["vm"] ≈ 0.99 atol=1e-2
            end
        end
        @testset "LPACCPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"), PowerModels.LPACCPowerModel, juniper; setting=s)
                @test result["objective"] ≈ 333.095 atol=1e-1
                @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -1.009 atol=1e-2
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-2
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["convdc_ne"]["1"]["pconv"] ≈ -1 atol=1e-2
                @test result["solution"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-2
            end
            @testset "9-bus case" begin
                result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case9_test.m"), PowerModels.LPACCPowerModel, juniper; setting=s)
                @test result["objective"] ≈ 10.7 atol=1e-1
                @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0.814 atol=1e-2
                @test result["solution"]["busdc_ne"]["2"]["phivdcm_ne"] ≈ -0.00345834 atol=1e-2
            end
        end
        @testset "DCPPowerModel" begin
            @testset "4-bus case" begin
                result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"), PowerModels.DCPPowerModel, highs; setting=s)
                @test result["objective"] ≈ 329.95456 atol=1e-1
                @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -1.009 atol=1e-2
                @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-2
                @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["convdc_ne"]["1"]["pconv"] ≈ -1 atol=1e-2
                @test result["solution"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-2
            end
            @testset "6-bus case" begin
                result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case6acdc_dc_tnep.m"), PowerModels.DCPPowerModel, highs; setting=s)
                @test result["objective"] ≈ 22.8442 atol=1e-1
                @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -4 atol=1e-1
                @test result["solution"]["branchdc_ne"]["3"]["pt"] ≈ 4 atol=1e-1
                @test result["solution"]["convdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["convdc_ne"]["6"]["pconv"] ≈ 4 atol=1e-1
            end
            @testset "9-bus case" begin
                result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case9_test.m"), PowerModels.DCPPowerModel, highs; setting=s)
                @test result["objective"] ≈ 10.7 atol=1e-1
                @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
            end
        end
        if use_commercial_solvers
            @testset "SOCWRPowerModel" begin
                @testset "4-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"), PowerModels.SOCWRPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 348.021 atol=1e-1
                    @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -0.631 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-2
                    @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["1"]["pconv"] ≈ -0.618 atol=1e-2
                    @test result["solution"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-2
                end
                @testset "6-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case6_test.m"), PowerModels.SOCWRPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 31.63 atol=1e-1
                    @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 0 atol=1e-2
                    @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["4"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["10"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -2.29067 atol=1e-1
                    @test result["solution"]["busdc_ne"]["2"]["wdc_ne"] ≈ 1.18695 atol=1e-2
                end
                @testset "9-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case9_test.m"), PowerModels.SOCWRPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 10.7 atol=1e-1
                    @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 1.168 atol=1e-2
                    @test result["solution"]["busdc_ne"]["2"]["wdc_ne"] ≈ 0.845 atol=1e-2
                end
            end
            @testset "QCRMPowerModel" begin
                @testset "6-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case6_test.m"), PowerModels.QCRMPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 31.6 atol=1e-1
                    @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["4"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["10"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -2.29 atol=1e-1
                    @test result["solution"]["busdc_ne"]["2"]["wdc_ne"] ≈ 1.18695 atol=1e-2
                end
                @testset "9-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case9_test.m"), PowerModels.QCRMPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 10.7 atol=1e-1
                    @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 1.0799 atol=1e-2
                    @test result["solution"]["busdc_ne"]["2"]["wdc_ne"] ≈ 0.8777 atol=1e-2
                end
            end
        end
    end
    @testset "Single network, <:AbstractBFModel" begin
        if use_commercial_solvers
            @testset "SOCBFConicPowerModel" begin
                @testset "6-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case6_test.m"), PowerModels.SOCBFConicPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 31.6 atol=1e-1
                    @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["4"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["10"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["3"]["pf"] ≈ -2.29 atol=1e-2
                    @test result["solution"]["busdc_ne"]["2"]["wdc_ne"] ≈ 1.18695 atol=1e-2
                end
                @testset "9-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case9_test.m"), PowerModels.SOCBFConicPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 10.7 atol=1e-1
                    @test result["solution"]["branchdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["1"]["pf"] ≈ 0.9547343363830544 atol=1e-2 #1.029695717391926
                    @test result["solution"]["busdc_ne"]["2"]["wdc_ne"] ≈ 0.9607722492758961 atol=1e-2
                end
                @testset "14-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case14_test.m"), PowerModels.SOCBFConicPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 20 atol=1e-1
                    @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["7"]["isbuilt"] ≈ 1 atol=1e-2
                end
                @testset "39-bus case" begin
                    result = solve_tnep(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case39_test.m"), PowerModels.SOCBFConicPowerModel, gurobi; setting=s)
                    @test result["objective"] ≈ 30.4 atol=1e-1
                    @test result["solution"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["4"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["convdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["branchdc_ne"]["29"]["isbuilt"] ≈ 1 atol=1e-2
                end
            end
        end
    end
    @testset "Multinetwork, <:AbstractPowerModel" begin
        @testset "DCPPowerModel" begin
            @testset "4-bus case" begin
                data_acdc = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"))
                result = solve_tnep(data_acdc, PowerModels.DCPPowerModel, highs, multinetwork=true; setting=s)
                @test result["objective"] ≈ 659.90 atol=1e-1
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"] ≈ -1.009 atol=1e-2
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-2
                @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["pconv"] ≈ -1 atol=1e-2
                @test result["solution"]["nw"]["1"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-2
            end
            @testset "6-bus case" begin
                data_dc = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case6_strg.m"))
                result = solve_tnep(data_dc, PowerModels.DCPPowerModel, highs; multinetwork=true, setting=s)
                @test result["objective"] ≈ 52.67 atol=1e-1
                @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["nw"]["1"]["convdc_ne"]["5"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["nw"]["1"]["convdc_ne"]["6"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"] ≈ 0 atol=1e-2
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["10"]["isbuilt"] ≈ 0 atol=1e-2
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["pf"] ≈ 1.3 atol=1e-2
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["1"]["pt"] ≈ -1.3 atol=1e-2
            end
        end
        @testset "LPACCPowerModel" begin
            @testset "4-bus case" begin
                data_dc = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_original.m"))
                result = solve_tnep(data_dc, PowerModels.LPACCPowerModel, juniper, multinetwork=true; setting=s)
                @test result["objective"] ≈ 10.2 atol=1e-1
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"] ≈ -1.2868 atol=1e-2
                @test result["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"] ≈ -1.2868 atol=1e-2
                @test result["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"] ≈ -2.15833 atol=1e-2
            end
        end
        if use_commercial_solvers
            @testset "ACPPowerModel" begin
                @testset "4-bus case" begin
                    data_dc = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_original.m"))
                    result = solve_tnep(data_dc, PowerModels.ACPPowerModel, juniper, multinetwork=true; setting=s)
                    @test result["objective"] ≈ 10.2 atol=1e-1
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"] ≈ -1.07017 atol=1e-2
                    @test result["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"] ≈ -1.07057 atol=1e-2
                    @test result["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"] ≈ -2.08104 atol=1e-2
                end
                @testset "4-bus case" begin
                    data_acdc = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"))
                    result = solve_tnep(data_acdc, PowerModels.ACPPowerModel, juniper, multinetwork=true; setting=s)
                    @test result["objective"] ≈ 696.043 atol=1e-1
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"] ≈ -0.631 atol=1e-2
                    @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-2
                    @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["pconv"] ≈ -0.6189 atol=1e-2
                    @test result["solution"]["nw"]["1"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-2
                end
            end
            @testset "SOCWRPowerModel" begin
                @testset "4-bus case" begin
                    data_dc = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_original.m"))
                    result = solve_tnep(data_dc, PowerModels.SOCWRPowerModel, gurobi, multinetwork=true; setting=s)
                    @test result["objective"] ≈ 10.2 atol=1e-1
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"] ≈ -1.227 atol=1e-2
                    @test result["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"] ≈ -1.227 atol=1e-2
                    @test result["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"] ≈ -2.1151 atol=1e-2
                end
                @testset "4-bus case" begin
                    data_acdc = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"))
                    result = solve_tnep(data_acdc, PowerModels.SOCWRPowerModel, gurobi, multinetwork=true; setting=s)
                    @test result["objective"] ≈ 696.04 atol=1e-1
                    @test result["solution"]["nw"]["2"]["branchdc_ne"]["3"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"] ≈ -0.631 atol=1e-2
                    @test result["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"] ≈ 0 atol=1e-2
                    @test result["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["convdc_ne"]["1"]["pconv"] ≈ -0.618 atol=1e-2
                    @test result["solution"]["nw"]["1"]["ne_branch"]["1"]["built"] ≈ 1 atol=1e-2
                end
            end
        end
    end
    @testset "Multinetwork, <:AbstractBFModel" begin
        if use_commercial_solvers
            @testset "SOCBFConicPowerModel" begin
                @testset "4-bus case" begin
                    data_dc = build_mn_data(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_original.m"))
                    result = solve_tnep(data_dc, PowerModels.SOCBFConicPowerModel, gurobi, multinetwork=true; setting=s)
                    @test result["objective"] ≈ 10.2 atol=1e-1
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"] ≈ -1.3660 atol=1e-2
                    @test result["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"] ≈ -1.3800 atol=1e-2
                    @test result["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"] ≈ 1 atol=1e-2
                    @test result["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"] ≈ -2.1338 atol=1e-2
                end
            end
        end
    end
end
