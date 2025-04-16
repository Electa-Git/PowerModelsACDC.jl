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
        @test isapprox(result["objective"],  8.56395e5, atol = 1e2)
    end

    @testset "UC, with HVDC & storage, with binary relaxation" begin
        s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => true)
        result = _PMACDC.solve_uc(uc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
        @test isapprox(result["objective"],  8.56395e5, atol = 1e2)
    end
end

@testset "Frequency constrained UC" begin
    file = "../test/data/fcuc_test.m"
    fcuc_data = prepare_uc_test_data(file; contingencies = true)
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => true, "fix_cross_border_flows" => false)
    result_dc_actions = _PMACDC.solve_fcuc(fcuc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
    @test isapprox(result_dc_actions["objective"],  1.25166e6, atol = 1e2)

    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => false, "fix_cross_border_flows" => false)
    result_no_dc_actions = _PMACDC.solve_fcuc(fcuc_data, DCPPowerModel, highs, setting = s, multinetwork = true)
    @test isapprox(result_no_dc_actions["objective"],  6.98297e7, atol = 1e2)
end