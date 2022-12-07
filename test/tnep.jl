s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)
@testset "test dc tnep" begin
    @testset "6-bus case" begin
        resultDC = run_tnepopf("../test/data/tnep/case6_test.m", DCPPowerModel, highs; setting = s)
        @test isapprox(resultDC["objective"], 26.3331; atol = 1e-1)
        @test isapprox(resultDC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["2"]["isbuilt"], 0; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["10"]["isbuilt"], 0; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["1"]["pf"], 1.77384; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["1"]["pt"], -1.77384; atol = 1e-2)
    end

    @testset "9-bus case" begin
        resultDC = run_tnepopf("../test/data/tnep/case9_test.m", DCPPowerModel, highs; setting = s)
        @test isapprox(resultDC["objective"], 10.7; atol = 1e-1)
        @test isapprox(resultDC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
    end
    #
    @testset "14-bus case" begin
        resultDC =  run_tnepopf("../test/data/tnep/case14_test.m",  DCPPowerModel, highs, setting = s)
        @test isapprox(resultDC["objective"], 15.6921; atol = 1e-1)
        @test isapprox(resultDC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["7"]["isbuilt"], 0; atol = 1e-2)
    end
    #
    @testset "39-bus case" begin
        resultDC =  run_tnepopf("../test/data/tnep/case39_test.m",  DCPPowerModel, highs, setting = s)
        @test isapprox(resultDC["objective"], 25.1605; atol = 1e-1)
        @test isapprox(resultDC["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["13"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["17"]["isbuilt"], 1; atol = 1e-2)

    end
end

if local_test == true
    @testset "test soc tnep" begin
        @testset "test SOC-BFM tnep" begin
            @testset "6-bus case" begin
                resultSOCBF = run_tnepopf_bf("../test/data/tnep/case6_test.m", SOCBFConicPowerModel, mosek; setting = s)
                @test isapprox(resultSOCBF["objective"], 31.6; atol = 1e-1)
                @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["10"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["3"]["pf"], -2.29; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["busdc_ne"]["2"]["wdc_ne"], 1.18695; atol = 1e-2)
            end
            @testset "9-bus case" begin
                resultSOCBF = run_tnepopf_bf("../test/data/tnep/case9_test.m", SOCBFConicPowerModel, mosek; setting = s)
                @test isapprox(resultSOCBF["objective"], 10.7; atol = 1e-1)
                @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["1"]["pf"], 0.9547343363830544; atol = 1e-2) #1.029695717391926
                @test isapprox(resultSOCBF["solution"]["busdc_ne"]["2"]["wdc_ne"], 0.9607722492758961; atol = 1e-2)
            end
        end
        @testset "14-bus case" begin
            resultSOCBF =  run_tnepopf_bf("../test/data/tnep/case14_test.m",  SOCBFConicPowerModel, mosek; setting = s)
            @test isapprox(resultSOCBF["objective"], 20; atol = 1e-1)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["7"]["isbuilt"], 1; atol = 1e-2)
        end
        #
        @testset "39-bus case" begin
            resultSOCBF =  run_tnepopf_bf("../test/data/tnep/case39_test.m",  SOCBFConicPowerModel, mosek; setting = s)
            @test isapprox(resultSOCBF["objective"], 30.4; atol = 1e-1)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["29"]["isbuilt"], 1; atol = 1e-2)
        end

    end

    @testset "test SOC-BIM tnep" begin
        @testset "6-bus case" begin
            resultSOCWR = run_tnepopf("../test/data/tnep/case6_test.m", SOCWRPowerModel, gurobi; setting = s)
            @test isapprox(resultSOCWR["objective"], 31.63; atol = 1e-1)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["1"]["isbuilt"], 0; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["10"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["3"]["pf"], -2.29067; atol = 1e-1)
            @test isapprox(resultSOCWR["solution"]["busdc_ne"]["2"]["wdc_ne"], 1.18695; atol = 1e-2)
        end
        @testset "9-bus case" begin
            resultSOCWR = run_tnepopf("../test/data/tnep/case9_test.m", SOCWRPowerModel, gurobi; setting = s)
            @test isapprox(resultSOCWR["objective"], 10.7; atol = 1e-1)
            @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["1"]["pf"], 1.168; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["busdc_ne"]["2"]["wdc_ne"], 0.845; atol = 1e-2)

        end
    end

    @testset "test QC tnep" begin
        @testset "6-bus case" begin
            resultQC = run_tnepopf("../test/data/tnep/case6_test.m", QCRMPowerModel, gurobi; setting = s)
            @test isapprox(resultQC["objective"], 31.6; atol = 1e-1)
            @test isapprox(resultQC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["branchdc_ne"]["10"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["branchdc_ne"]["3"]["pf"], -2.29; atol = 1e-1)
            @test isapprox(resultQC["solution"]["busdc_ne"]["2"]["wdc_ne"], 1.18695; atol = 1e-2)
        end
        @testset "9-bus case" begin
            resultQC = run_tnepopf("../test/data/tnep/case9_test.m", QCRMPowerModel, gurobi; setting = s)
            @test isapprox(resultQC["objective"], 10.7; atol = 1e-1)
            @test isapprox(resultQC["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultQC["solution"]["branchdc_ne"]["1"]["pf"], 1.0799; atol = 1e-2)
            @test isapprox(resultQC["solution"]["busdc_ne"]["2"]["wdc_ne"], 0.8777; atol = 1e-2)
        end
    end
end

@testset "test AC tnep" begin
    @testset "6-bus case" begin
        # ac solver huristics may build ac branch 2 or 10
        resultACP = run_tnepopf("../test/data/tnep/case6_test.m", ACPPowerModel, juniper; setting = s)
        @test isapprox(resultACP["objective"], 31.65; atol = 5e0)
        @test isapprox(resultACP["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["6"]["isbuilt"], 0; atol = 1e-2)
        @test isapprox(resultACP["solution"]["busdc_ne"]["6"]["vm"], 1.09; atol = 1e-1)
    end
    @testset "9-bus case" begin
        resultACP = run_tnepopf("../test/data/tnep/case9_test.m", ACPPowerModel, juniper; setting = s)
        @test isapprox(resultACP["objective"], 10.7; atol = 1e-1)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["1"]["pf"], 0.841; atol = 1e-1) #0.838 0.8360707133374305
        @test isapprox(resultACP["solution"]["busdc_ne"]["2"]["vm"], 0.99; atol = 1e-2)
    end
end

@testset "test LPAC tnep" begin
    @testset "6-bus case" begin
        resultLPAC = run_tnepopf("../test/data/tnep/case6_test.m", LPACCPowerModel, juniper; setting = s)
        @test isapprox(resultLPAC["objective"], 30.5; atol = 1e-1)
        @test isapprox(resultLPAC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["branchdc_ne"]["1"]["pf"], 1.63; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["busdc_ne"]["2"]["phivdcm_ne"], -0.00668065; atol = 1e-2)

    end
    @testset "9-bus case" begin
        resultLPAC = run_tnepopf("../test/data/tnep/case9_test.m", LPACCPowerModel, juniper; setting = s)
        @test isapprox(resultLPAC["objective"], 10.7; atol = 1e-1)
        @test isapprox(resultLPAC["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["branchdc_ne"]["1"]["pf"], 0.814; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["busdc_ne"]["2"]["phivdcm_ne"], -0.00345834; atol = 1e-2)
    end
end

@testset "ACDC tnep" begin
    @testset "DCP" begin
        resultDCP = run_tnepopf("../test/data/tnep/case4_acdc.m", DCPPowerModel, highs; setting = s)
        @test isapprox(resultDCP["objective"], 329.95456; atol = 1e-1)
        @test isapprox(resultDCP["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDCP["solution"]["branchdc_ne"]["3"]["pf"], -1.009; atol = 1e-2)
        @test isapprox(resultDCP["solution"]["branchdc_ne"]["1"]["pf"], 0; atol = 1e-2)
        @test isapprox(resultDCP["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDCP["solution"]["convdc_ne"]["1"]["pconv"], -1; atol = 1e-2)
        @test isapprox(resultDCP["solution"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)
    end
    @testset "ACP" begin
        resultACP = run_tnepopf("../test/data/tnep/case4_acdc.m", ACPPowerModel, juniper; setting = s)
        @test isapprox(resultACP["objective"], 348.0219; atol = 1e-1)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["3"]["pf"], -0.631; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["1"]["pf"], 0; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["1"]["pconv"], -0.618; atol = 1e-2)
        @test isapprox(resultACP["solution"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)
    end
    @testset "LPAC" begin
        resultLPAC = run_tnepopf("../test/data/tnep/case4_acdc.m", LPACCPowerModel, juniper; setting = s)
        @test isapprox(resultLPAC["objective"], 333.095; atol = 1e-1)
        @test isapprox(resultLPAC["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["branchdc_ne"]["3"]["pf"], -1.009; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["branchdc_ne"]["1"]["pf"], 0; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["convdc_ne"]["1"]["pconv"], -1; atol = 1e-2)
        @test isapprox(resultLPAC["solution"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)
    end   
    if local_test == true
        @testset "SOCWR" begin
            resultSOCWR = run_tnepopf("../test/data/tnep/case4_acdc.m", SOCWRPowerModel, gurobi; setting = s)
            @test isapprox(resultSOCWR["objective"], 348.021; atol = 1e-1)
            @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["3"]["pf"], -0.631; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["1"]["pf"], 0; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["convdc_ne"]["1"]["pconv"], -0.618; atol = 1e-2)
            @test isapprox(resultSOCWR["solution"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)
        end
    end
end

@testset "AC and DC Candidates" begin
    result = run_tnepopf("../test/data/tnep/case6_dc_tnep.m", DCPPowerModel, highs; setting = s)
    @test isapprox(result["objective"], 26.3331; atol = 1e-1)
    @test isapprox(result["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["1"]["pf"], 1.77384; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["1"]["pt"], -1.77384; atol = 1e-2)
    @test isapprox(result["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
    @test isapprox(result["solution"]["convdc_ne"]["5"]["pconv"], -1.76543; atol = 1e-2)

    result = run_tnepopf("../test/data/tnep/case6_acdc_tnep.m", DCPPowerModel, highs; setting = s)
    @test isapprox(result["objective"], 25.4221; atol = 1e-1)
    @test isapprox(result["solution"]["branchdc_ne"]["9"]["isbuilt"], 1; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["9"]["pf"], -3.00658; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["9"]["pt"], 3.00658; atol = 1e-2)
    @test isapprox(result["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
    @test isapprox(result["solution"]["convdc_ne"]["6"]["pconv"], 3.0221; atol = 1e-2)
    @test isapprox(result["solution"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)

    result = run_tnepopf("../test/data/tnep/case6acdc_dc_tnep.m", DCPPowerModel, highs; setting = s)
    @test isapprox(result["objective"], 22.8442; atol = 1e-1)
    @test isapprox(result["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["3"]["pf"], -3.72760; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["3"]["pt"], 3.72760; atol = 1e-2)
    @test isapprox(result["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
    @test isapprox(result["solution"]["convdc_ne"]["6"]["pconv"], 3.74419; atol = 1e-2)

    result = run_tnepopf("../test/data/tnep/case6acdc_dc_branch_tnep.m", DCPPowerModel, highs; setting = s)
    @test isapprox(result["objective"], 13.3663; atol = 1e-1)
    @test isapprox(result["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["3"]["pf"], -3.738639; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["3"]["pt"], 3.738639; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["4"]["isbuilt"], 0; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["1"]["pf"], 1.382799; atol = 1e-2)
    @test isapprox(result["solution"]["branchdc_ne"]["1"]["pt"], -1.382799; atol = 1e-2)

end


s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "process_data_internally" => false)
@testset "mp-tnep" begin
    @testset "dc tnep" begin
        @testset "DCP" begin
            data_dc = build_mn_data("../test/data/tnep/case4_original.m")
            resultDCP = run_mp_tnepopf(data_dc, DCPPowerModel, highs, multinetwork=true; setting = s)
            @test isapprox(resultDCP["objective"], 8.2; atol = 1e-1)
            @test isapprox(resultDCP["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"], -2.0013; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"], -2.00137; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"], -2.0; atol = 1e-2)
        end
        @testset "LPAC" begin
            data_dc = build_mn_data("../test/data/tnep/case4_original.m")
            resultLPAC = run_mp_tnepopf(data_dc, LPACCPowerModel, juniper, multinetwork=true; setting = s)
            @test isapprox(resultLPAC["objective"], 10.2; atol = 1e-1)
            @test isapprox(resultLPAC["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultLPAC["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"], -1.2868; atol = 1e-2)
            @test isapprox(resultLPAC["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"], -1.2868; atol = 1e-2)
            @test isapprox(resultLPAC["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultLPAC["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"], -2.15833; atol = 1e-2)
        end
        if local_test == true
            @testset "ACP" begin   
                data_dc = build_mn_data("../test/data/tnep/case4_original.m")
                resultACP = run_mp_tnepopf(data_dc, ACPPowerModel, juniper, multinetwork=true; setting = s)
                @test isapprox(resultACP["objective"], 10.2; atol = 1e-1)
                @test isapprox(resultACP["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"], -1.07017; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"], -1.07057; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"], -2.08104; atol = 1e-2)
            end
            @testset "SOCWR" begin
                data_dc = build_mn_data("../test/data/tnep/case4_original.m")
                resultSOCWR = run_mp_tnepopf(data_dc, SOCWRPowerModel, gurobi, multinetwork=true; setting = s)
                @test isapprox(resultSOCWR["objective"], 10.2; atol = 1e-1)
                @test isapprox(resultSOCWR["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"], -1.227; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"], -1.227; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"], -2.1151; atol = 1e-2)
            end
                @testset "SOCBF" begin
                data_dc = build_mn_data("../test/data/tnep/case4_original.m")
                resultSOCBF = run_mp_tnepopf_bf(data_dc, SOCBFConicPowerModel, mosek, multinetwork=true; setting = s)
                @test isapprox(resultSOCBF["objective"], 10.2; atol = 1e-1)
                @test isapprox(resultSOCBF["solution"]["nw"]["1"]["branchdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["nw"]["1"]["branchdc_ne"]["2"]["pf"], -1.3660; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["nw"]["2"]["branchdc_ne"]["2"]["pf"], -1.3800; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCBF["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"], -2.1338; atol = 1e-2)
            end
        end
    end
    @testset "acdc tnep" begin
        @testset "DCP" begin
            data_acdc = build_mn_data("../test/data/tnep/case4_acdc.m")
            resultDCP = run_mp_tnepopf(data_acdc, DCPPowerModel, highs, multinetwork=true; setting = s)
            @test isapprox(resultDCP["objective"], 659.90; atol = 1e-1)
            @test isapprox(resultDCP["solution"]["nw"]["1"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"], -1.009; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"], 0; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["1"]["convdc_ne"]["1"]["pconv"], -1; atol = 1e-2)
            @test isapprox(resultDCP["solution"]["nw"]["1"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)
        end
        # @testset "LPAC" begin
        #   data_acdc = build_mn_data("../test/data/tnep/case4_acdc.m")
        #    resultLPAC = run_mp_tnepopf(data_acdc, LPACCPowerModel, juniper, multinetwork=true; setting = s)
        #    @test isapprox(resultLPAC["objective"], 614.15; atol = 1e-1)
        #    @test isapprox(resultLPAC["solution"]["nw"]["1"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        #    @test isapprox(resultLPAC["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"], -1.2466; atol = 1e-2)
        #    @test isapprox(resultLPAC["solution"]["nw"]["2"]["branchdc_ne"]["3"]["pf"], -1.2466; atol = 1e-2)
        #    @test isapprox(resultLPAC["solution"]["nw"]["2"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        #    @test isapprox(resultLPAC["solution"]["nw"]["1"]["convdc_ne"]["2"]["pconv"], -1.2355; atol = 1e-2)
        #    @test isapprox(resultLPAC["solution"]["nw"]["1"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)
        # end
        if local_test == true
            @testset "ACP" begin
                data_acdc = build_mn_data("../test/data/tnep/case4_acdc.m")
                resultACP = run_mp_tnepopf(data_acdc, ACPPowerModel, juniper, multinetwork=true; setting = s)
                @test isapprox(resultACP["objective"], 696.043; atol = 1e-1)
                @test isapprox(resultACP["solution"]["nw"]["1"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"], -0.631; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"], 0; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["1"]["convdc_ne"]["1"]["pconv"], -0.6189; atol = 1e-2)
                @test isapprox(resultACP["solution"]["nw"]["1"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)
            end
            @testset "SOCWR" begin
                data_acdc = build_mn_data("../test/data/tnep/case4_acdc.m")
                resultSOCWR = run_mp_tnepopf(data_acdc, SOCWRPowerModel, gurobi, multinetwork=true; setting = s)
                @test isapprox(resultSOCWR["objective"], 696.04; atol = 1e-1)
                @test isapprox(resultSOCWR["solution"]["nw"]["2"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["1"]["branchdc_ne"]["3"]["pf"], -0.631; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["2"]["branchdc_ne"]["1"]["pf"], 0; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["2"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["1"]["convdc_ne"]["1"]["pconv"], -0.618; atol = 1e-2)
                @test isapprox(resultSOCWR["solution"]["nw"]["1"]["ne_branch"]["1"]["built"], 1; atol = 1e-2)
            end
        end
    end
end
