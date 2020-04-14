s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false)
@testset "test dc tnep" begin
    @testset "6-bus case" begin
        resultDC = run_tnepopf("../test/data/tnep/case6_test.m", DCPPowerModel, cbc; setting = s)
        @test isapprox(resultDC["objective"], 25.25; atol = 1e-1)
        @test isapprox(resultDC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["10"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["2"]["pf"], 1.87; atol = 1e-2)
    end

    @testset "9-bus case" begin
        resultDC = run_tnepopf("../test/data/tnep/case9_test.m", DCPPowerModel, cbc; setting = s)
        @test isapprox(resultDC["objective"], 5; atol = 1e-1)
        @test isapprox(resultDC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
    end
    #
    @testset "14-bus case" begin
        resultDC =  run_tnepopf("../test/data/tnep/case14_test.m",  DCPPowerModel, cbc, setting = s)
        @test isapprox(resultDC["objective"], 14.9; atol = 1e-1)
        @test isapprox(resultDC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["7"]["isbuilt"], 1; atol = 1e-2)
    end
    #
    @testset "39-bus case" begin
        resultDC =  run_tnepopf("../test/data/tnep/case39_test.m",  DCPPowerModel, cbc, setting = s)
        @test isapprox(resultDC["objective"], 23.7; atol = 1e-1)
        @test isapprox(resultDC["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["13"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["17"]["isbuilt"], 1; atol = 1e-2)

    end
end
#
@testset "test soc tnep" begin
    @testset "test SOC-BFM tnep" begin
        @testset "6-bus case" begin
            resultSOCBF = run_tnepopf_bf("../test/data/tnep/case6_test.m", SOCBFPowerModel, juniper; setting = s)
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
            resultSOCBF = run_tnepopf_bf("../test/data/tnep/case9_test.m", SOCBFPowerModel, juniper; setting = s)
            @test isapprox(resultSOCBF["objective"], 10.7; atol = 1e-1)
            @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["1"]["pf"], 0.998; atol = 1e-2)
            @test isapprox(resultSOCBF["solution"]["busdc_ne"]["2"]["wdc_ne"], 0.984497; atol = 1e-2)
        end
    end
#    ONLY WITH  MOSEK -> Doesn't run on travis, can be used locally
####################################################################
#     @testset "14-bus case" begin
#         resultSOCBF =  run_tnepopf_bf("../test/data/tnep/case14_test.m",  SOCBFConicPowerModel, mosek; setting = s)
#         @test isapprox(resultSOCBF["objective"], 20; atol = 1e-1)
#         @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
#         @test isapprox(resultSOCBF["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
#         @test isapprox(resultSOCBF["solution"]["convdc_ne"]["7"]["isbuilt"], 1; atol = 1e-2)
#     end
# #
#     @testset "39-bus case" begin
#         resultSOCBF =  run_tnepopf_bf("../test/data/tnep/case39_test.m",  SOCBFConicPowerModel, mosek; setting = s)
#         @test isapprox(resultSOCBF["objective"], 30.4; atol = 1e-1)
#         @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
#         @test isapprox(resultSOCBF["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
#         @test isapprox(resultSOCBF["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
#         @test isapprox(resultSOCBF["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
#         @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
#         @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
#         @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["29"]["isbuilt"], 1; atol = 1e-2)
#     end

end

@testset "test SOC-BIM tnep" begin
    @testset "6-bus case" begin
        resultSOCWR = run_tnepopf("../test/data/tnep/case6_test.m", SOCWRPowerModel, juniper; setting = s)
        @test isapprox(resultSOCWR["objective"], 31.63; atol = 1e-1)
        @test isapprox(resultSOCWR["solution"]["convdc_ne"]["1"]["isbuilt"], 0; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["10"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["3"]["pf"], -2.29067; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["busdc_ne"]["2"]["wdc_ne"], 1.18695; atol = 1e-2)
    end
    @testset "9-bus case" begin
        resultSOCWR = run_tnepopf("../test/data/tnep/case9_test.m", SOCWRPowerModel, juniper; setting = s)
        @test isapprox(resultSOCWR["objective"], 10.7; atol = 1e-1)
        @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["branchdc_ne"]["1"]["pf"], 0.484749; atol = 1e-2)
        @test isapprox(resultSOCWR["solution"]["busdc_ne"]["2"]["wdc_ne"], 0.959131; atol = 1e-2)

    end
end

@testset "test QC tnep" begin
    @testset "6-bus case" begin
        resultQC = run_tnepopf("../test/data/tnep/case6_test.m", QCRMPowerModel, juniper; setting = s)
        @test isapprox(resultQC["objective"], 31.6; atol = 1e-1)
        @test isapprox(resultQC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["branchdc_ne"]["10"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["branchdc_ne"]["3"]["pf"], -2.29; atol = 1e-2)
        @test isapprox(resultQC["solution"]["busdc_ne"]["2"]["wdc_ne"], 1.18695; atol = 1e-2)
    end
    @testset "9-bus case" begin
        resultQC = run_tnepopf("../test/data/tnep/case9_test.m", QCRMPowerModel, juniper; setting = s)
        @test isapprox(resultQC["objective"], 10.7; atol = 1e-1)
        @test isapprox(resultQC["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultQC["solution"]["branchdc_ne"]["1"]["pf"], 0.9092088301606092; atol = 1e-2)
        @test isapprox(resultQC["solution"]["busdc_ne"]["2"]["wdc_ne"], 0.958239; atol = 1e-2)
    end
end

@testset "test AC tnep" begin
    @testset "6-bus case" begin
        resultACP = run_tnepopf("../test/data/tnep/case6_test.m", ACPPowerModel, juniper; setting = s)
        @test isapprox(resultACP["objective"], 32.7; atol = 1e-1)
        @test isapprox(resultACP["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["6"]["isbuilt"], 0; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["10"]["isbuilt"], 0; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["2"]["pf"], -1.9834; atol = 1e-2)
        @test isapprox(resultACP["solution"]["busdc_ne"]["2"]["vm"], 1.09; atol = 1e-2)
    end
    @testset "9-bus case" begin
        resultACP = run_tnepopf("../test/data/tnep/case9_test.m", ACPPowerModel, juniper; setting = s)
        @test isapprox(resultACP["objective"], 10.7; atol = 1e-1)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultACP["solution"]["branchdc_ne"]["1"]["pf"], 0.838; atol = 1e-2)
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
