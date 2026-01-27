@testset "Base UC" begin
    file = "../test/data/case5_2grids_uc.m"
    uc_data = prepare_uc_test_data(file)

    @testset "UC, no HVDC, no binary relaxation" begin
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "hvdc_inertia_contribution" => false, "relax_uc_binaries" => false)
    result = _PMACDC.solve_uc(uc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
    @test isapprox(result["objective"], 8.93124e5, atol = 1e2)
    end

    @testset "UC, no HVDC, with binary relaxation" begin
        s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "hvdc_inertia_contribution" => false, "relax_uc_binaries" => true)
        result = _PMACDC.solve_uc(uc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
        @test isapprox(result["objective"], 8.93124e5, atol = 1e2)
    end
    
    file = "../test/data/case5_2grids_uc_hvdc.m"
    uc_data = prepare_uc_test_data(file)
    @testset "UC, with HVDC, no binary relaxation" begin
        s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => false)
        result = _PMACDC.solve_uc(uc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
        @test isapprox(result["objective"], 8.69583e5, atol = 1e2)
    end

    @testset "UC, with HVDC, with binary relaxation" begin
        s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => true)
        result = _PMACDC.solve_uc(uc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
        @test isapprox(result["objective"], 8.69583e5, atol = 1e2)
    end

    file = "../test/data/case5_2grids_uc_hvdc_strg.m"
    uc_data = prepare_uc_test_data(file)
    @testset "UC, with HVDC & storage, no binary relaxation" begin
        s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => false)
        result = _PMACDC.solve_uc(uc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
        @test isapprox(result["objective"],  857044.7, atol = 1e2)
    end

    @testset "UC, with HVDC & storage, with binary relaxation" begin
        s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => true)
        result = _PMACDC.solve_uc(uc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
        @test isapprox(result["objective"],  857044.7, atol = 1e2)
    end
end

@testset "Frequency constrained UC" begin
    file = "../test/data/fcuc_test.m"
    contingencies = Dict("type" => "largest", "elements" => ["gen", "convdc", "storage", "tie_lines"])
    fcuc_data = prepare_uc_test_data(file; contingencies = contingencies)
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => true, "fix_cross_border_flows" => false)
    result_dc_actions = _PMACDC.solve_fcuc(fcuc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
    @test isapprox(result_dc_actions["objective"],  1.25166e6, atol = 1e2)

    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => false, "fix_cross_border_flows" => false)
    result_no_dc_actions = _PMACDC.solve_fcuc(fcuc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
    @test isapprox(result_no_dc_actions["objective"],  6.98297e7, atol = 1e2)
end

@testset "System split constrained UC" begin
    file = "../test/data/split_test.m"
    contingencies = Dict("type" => "N-1", "elements" => ["gen"])
    spcuc_data = prepare_uc_test_data(file; contingencies = contingencies, tielines = [8])
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => true, "fix_cross_border_flows" => false, "add_split_constraints" => true)
    result_with_split_constraints = _PMACDC.solve_spcuc(spcuc_data, DCPPowerModel, juniper, setting = s, multinetwork = true)
    @test isapprox(result_with_split_constraints["objective"],  668769, atol = 1e0)
    @test isapprox(result_with_split_constraints["solution"]["nw"]["64"]["branchdc"]["1"]["pf"],  2.548, atol = 1e-1)

    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => false, "fix_cross_border_flows" => false, "add_split_constraints" => false)
     result_without_split_constraints= _PMACDC.solve_spcuc(spcuc_data, DCPPowerModel, juniper, setting = s, multinetwork = true)
    @test isapprox(result_without_split_constraints["objective"],  668769, atol = 1e0)
    @test isapprox(result_without_split_constraints["solution"]["nw"]["64"]["branchdc"]["1"]["pf"],  0.624, atol = 1e-1)
end