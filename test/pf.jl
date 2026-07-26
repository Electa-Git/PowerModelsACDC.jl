@testset "Power Flow" begin
    s = Dict("conv_losses_mp" => true)
    case5 = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc.m"))
    @testset "solve_acdcpf(file, ...)" begin
        result = solve_acdcpf(case5, PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
    end
    @testset "Bus type and gen setpoints" begin
        data = deepcopy(case5)
        gen3 = data["gen"]["3"] = deepcopy(data["gen"]["2"])
        gen3["index"] = 3
        gen3["gen_bus"] = 3
        gen3["qg"] = 0.2
        result = solve_acdcpf(data, PowerModels.ACPPowerModel, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        # Bus 1 and gen 1: reference. Fixed variables: va, vm.
        @test result["solution"]["bus"]["1"]["va"] ≈ 0.0 atol=1e-3 # Fixed variable.
        @test result["solution"]["bus"]["1"]["vm"] ≈ 1.06 rtol=1e-3 # Fixed variable.
        @test result["solution"]["gen"]["1"]["pg"] ≈ 0.9351 rtol=1e-3
        @test result["solution"]["gen"]["1"]["qg"] ≈ 0.8877 rtol=1e-3
        # Bus 2 and gen 2: PV. Fixed variables: vm, pg.
        @test result["solution"]["bus"]["2"]["va"] ≈ -0.02597 rtol=1e-3
        @test result["solution"]["bus"]["2"]["vm"] ≈ 1.0 rtol=1e-3 # Fixed variable.
        @test result["solution"]["gen"]["2"]["pg"] ≈ 0.4 rtol=1e-3 # Fixed variable.
        @test result["solution"]["gen"]["2"]["qg"] ≈ -0.5454 rtol=1e-3
        # Bus 3 and gen 3: PQ. Fixed variables: pg, pq.
        @test result["solution"]["bus"]["3"]["va"] ≈ -0.03562 rtol=1e-3
        @test result["solution"]["bus"]["3"]["vm"] ≈ 1.016 rtol=1e-3
        @test result["solution"]["gen"]["3"]["pg"] ≈ 0.4 rtol=1e-3 # Fixed variable.
        @test result["solution"]["gen"]["3"]["qg"] ≈ 0.2 rtol=1e-3 # Fixed variable.
    end
    @testset "ACPPowerModel" begin
        @testset "5-bus AC/DC case" begin
            result = solve_acdcpf(case5, PowerModels.ACPPowerModel, ipopt; setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 0 atol=1e-3
            @test result["solution"]["gen"]["1"]["pg"] ≈ 1.3494 rtol=1e-3
            @test result["solution"]["gen"]["2"]["pg"] ≈ 0.4000 rtol=1e-3
            @test result["solution"]["bus"]["1"]["vm"] ≈ 1.0600 rtol=1e-3
            @test result["solution"]["bus"]["1"]["va"] ≈ 0.0000 atol=1e-3
            @test result["solution"]["bus"]["2"]["vm"] ≈ 1.0000 rtol=1e-3
            @test result["solution"]["bus"]["3"]["vm"] ≈ 0.9953 rtol=1e-3
            @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0077 rtol=1e-3
            @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.0000 rtol=1e-3
            @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.9977 rtol=1e-3
            @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.1954 rtol=1e-3
            @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.3642 rtol=1e-3
        end
    end
    @testset "ACRPowerModel" begin
        @testset "5-bus AC/DC case" begin
            result = solve_acdcpf(case5, PowerModels.ACRPowerModel, ipopt; setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 0 atol=1e-3
            @test result["solution"]["gen"]["1"]["pg"] ≈ 1.3477 rtol=1e-3
            @test result["solution"]["gen"]["2"]["pg"] ≈ 0.4000 rtol=1e-3
            @test result["solution"]["bus"]["1"]["vr"] ≈ 1.0600 rtol=1e-3
            @test result["solution"]["bus"]["1"]["vi"] ≈ 0.0000 atol=1e-3
            @test result["solution"]["bus"]["2"]["vr"] ≈ 0.9991 rtol=1e-3
            @test result["solution"]["bus"]["3"]["vr"] ≈ 0.9930 rtol=1e-3
            @test result["solution"]["busdc"]["1"]["vm"] ≈ 1.0077 rtol=1e-3
            @test result["solution"]["busdc"]["2"]["vm"] ≈ 1.0000 rtol=1e-3
            @test result["solution"]["busdc"]["3"]["vm"] ≈ 0.9977 rtol=1e-3
            @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.1970 rtol=1e-3
            @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.3631 rtol=1e-3
        end
    end
    @testset "DCPPowerModel" begin
        @testset "5-bus AC/DC case" begin
            result = solve_acdcpf(case5, PowerModels.DCPPowerModel, highs; setting=s)
            @test result["termination_status"] == OPTIMAL
            @test result["objective"] ≈ 0 atol=1e-3
            @test result["solution"]["gen"]["1"]["pg"] ≈ 1.2831 rtol=1e-3
            @test result["solution"]["gen"]["2"]["pg"] ≈ 0.4000 rtol=1e-3
            @test result["solution"]["bus"]["1"]["vm"] ≈ 1.0000 rtol=1e-3
            @test result["solution"]["bus"]["1"]["va"] ≈ 0.0000 atol=1e-3
            @test result["solution"]["bus"]["2"]["vm"] ≈ 1.0000 rtol=1e-3
            @test result["solution"]["bus"]["3"]["vm"] ≈ 1.0000 rtol=1e-3
            @test result["solution"]["convdc"]["2"]["pgrid"] ≈ -0.2169 rtol=1e-3
            @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.3605 rtol=1e-3
        end
    end
    @testset "SOCBFPowerModel" begin
        @testset "5-bus AC/DC case" begin
            result = solve_acdcpf(case5, PowerModels.SOCBFPowerModel, ipopt; setting=s)
            @test result["termination_status"] == LOCALLY_SOLVED
            @test result["objective"] ≈ 0 atol=1e-3
            @test result["solution"]["gen"]["1"]["pg"] ≈ 1.2897 rtol=1e-3
            @test result["solution"]["gen"]["2"]["pg"] ≈ 0.4000 rtol=1e-3
            @test result["solution"]["bus"]["1"]["w"] ≈ 1.1236 rtol=1e-3
            @test result["solution"]["bus"]["2"]["w"] ≈ 1.0000 rtol=1e-3
            @test result["solution"]["bus"]["3"]["w"] ≈ 1.0924 rtol=1e-3
            @test result["solution"]["busdc"]["1"]["wdc"] ≈ 1.0069 rtol=1e-3
            @test result["solution"]["busdc"]["2"]["wdc"] ≈ 1.0000 rtol=1e-3
            @test result["solution"]["busdc"]["3"]["wdc"] ≈ 0.9869 rtol=1e-3
            @test result["solution"]["convdc"]["2"]["pgrid"] ≈ 0.2767 rtol=1e-3
            @test result["solution"]["convdc"]["3"]["pdc"] ≈ 0.4131 rtol=1e-3
        end
    end
end
