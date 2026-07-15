@testset "Unit Commitment" begin
    file = pkgdir(PowerModelsACDC, "test", "data", "case5_2grids_uc.m")
    uc_data = prepare_uc_test_data(file)
    @testset "No HVDC, no binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => false, "relax_uc_binaries" => false)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
        @test result["objective"] ≈ 8.93124e5 atol=1e2
    end
    @testset "No HVDC, with binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => false, "relax_uc_binaries" => true)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
        @test result["objective"] ≈ 8.93124e5 atol=1e2
    end
    file = pkgdir(PowerModelsACDC, "test", "data", "case5_2grids_uc_hvdc.m")
    uc_data = prepare_uc_test_data(file)
    @testset "With HVDC, no binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => false)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
        @test result["objective"] ≈ 8.69583e5 atol=1e2
    end
    @testset "With HVDC, with binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => true)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
        @test result["objective"] ≈ 8.69583e5 atol=1e2
    end
    file = pkgdir(PowerModelsACDC, "test", "data", "case5_2grids_uc_hvdc_strg.m")
    uc_data = prepare_uc_test_data(file)
    @testset "With HVDC & storage, no binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => false)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
        @test result["objective"] ≈ 857044.7 atol=1e2
    end
    @testset "With HVDC & storage, with binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => true)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
        @test result["objective"] ≈ 857044.7 atol=1e2
    end
end
@testset "Frequency-Constrained Unit Commitment" begin
    file = pkgdir(PowerModelsACDC, "test", "data", "fcuc_test.m")
    contingencies = Dict("type" => "largest", "elements" => ["gen", "convdc", "storage", "tie_lines"])
    fcuc_data = prepare_uc_test_data(file; contingencies=contingencies)
    @testset "No DC actions" begin
        s = Dict("conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => false, "fix_cross_border_flows" => false)
        result = solve_fcuc(fcuc_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
        @test result["objective"] ≈ 6.98297e7 atol=1e2
    end
    @testset "With DC actions" begin
        s = Dict("conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => true, "fix_cross_border_flows" => false)
        result = solve_fcuc(fcuc_data, PowerModels.DCPPowerModel, highs, setting=s, multinetwork=true)
        @test result["objective"] ≈ 1.25166e6 atol=1e2
    end
end
@testset "System-Split-Constrained Unit Commitment" begin
    file = pkgdir(PowerModelsACDC, "test", "data", "split_test.m")
    contingencies = Dict("type" => "N-1", "elements" => ["gen"])
    spcuc_data = prepare_uc_test_data(file; contingencies=contingencies, tielines=[8])
    @testset "No split constraints" begin
        s = Dict("conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => true, "fix_cross_border_flows" => false, "add_split_constraints" => true)
        result = solve_spcuc(spcuc_data, PowerModels.DCPPowerModel, juniper_warmstart, setting=s, multinetwork=true)
        @test result["objective"] ≈ 668769 atol=1e0
        @test result["solution"]["nw"]["64"]["branchdc"]["1"]["pf"] ≈ 2.548 atol=1e-1
    end
    @testset "With split constraints" begin
        s = Dict("conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => false, "fix_cross_border_flows" => false, "add_split_constraints" => false)
        result = solve_spcuc(spcuc_data, PowerModels.DCPPowerModel, juniper, setting=s, multinetwork=true)
        @test result["objective"] ≈ 668769 atol=1e0
        @test result["solution"]["nw"]["64"]["branchdc"]["1"]["pf"] ≈ 0.624 atol=1e-1
    end
end
