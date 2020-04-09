s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false)
@testset "test dc tnep" begin
    @testset "6-bus case" begin
        resultDC = run_tnepopf("../test/data/tnep/case6_test.m", DCPPowerModel, cbc; setting = s)

        @test isapprox(resultDC["objective"], 24.7; atol = 1e-1)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["12"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["7"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
    end
    #
    @testset "9-bus case" begin
        resultDC = run_tnepopf("../test/data/tnep/case9_test.m", DCPPowerModel, cbc; setting = s)
        @test isapprox(resultDC["objective"], 20.9; atol = 1e-1)
        @test isapprox(resultDC["solution"]["branchdc_ne"]["34"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultDC["solution"]["convdc_ne"]["9"]["isbuilt"], 1; atol = 1e-2)
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
    @testset "6-bus case" begin
        resultSOCBF = run_tnepopf_bf("../test/data/tnep/case6_test.m", SOCBFConicPowerModel, mosek; setting = s)
        @test isapprox(resultSOCBF["objective"], 30.7; atol = 1e-1)
        @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["12"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["25"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
    end
#
    @testset "9-bus case" begin
        resultSOCBF = run_tnepopf_bf("../test/data/tnep/case9_test.m", SOCBFConicPowerModel, mosek; setting = s)
        @test isapprox(resultSOCBF["objective"], 36.5; atol = 1e-1)
        @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["branchdc_ne"]["61"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["1"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["3"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultSOCBF["solution"]["convdc_ne"]["9"]["isbuilt"], 1; atol = 1e-2)
    end
#
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

@testset "test ac tnep" begin
    @testset "6-bus case" begin
        resultAC = run_tnepopf("../test/data/tnep/case6_test.m", ACPPowerModel, juniper; setting = s)
        @test isapprox(resultAC["objective"], 31.284; atol = 1e-2)
        @test isapprox(resultAC["solution"]["branchdc_ne"]["10"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultAC["solution"]["branchdc_ne"]["23"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultAC["solution"]["branchdc_ne"]["25"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultAC["solution"]["convdc_ne"]["2"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultAC["solution"]["convdc_ne"]["4"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultAC["solution"]["convdc_ne"]["5"]["isbuilt"], 1; atol = 1e-2)
        @test isapprox(resultAC["solution"]["convdc_ne"]["6"]["isbuilt"], 1; atol = 1e-2)
    end
end
