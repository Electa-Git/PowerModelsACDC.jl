@testset "Unit Commitment" begin
    file = pkgdir(PowerModelsACDC, "test", "data", "case5_2grids_uc.m")
    uc_data = prepare_uc_test_data(file; number_of_hours=12)
    @testset "No HVDC, no binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => false, "relax_uc_binaries" => false)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 5.3283e5 rtol=1e-3
    end
    @testset "No HVDC, with binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => false, "relax_uc_binaries" => true)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 5.3283e5 rtol=1e-3
    end
    file = pkgdir(PowerModelsACDC, "test", "data", "case5_2grids_uc_hvdc.m")
    uc_data = prepare_uc_test_data(file; number_of_hours=12)
    @testset "With HVDC, no binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => false)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 4.9748e5 rtol=1e-3
    end
    @testset "With HVDC, with binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => true)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 4.9748e5 rtol=1e-3
    end
    file = pkgdir(PowerModelsACDC, "test", "data", "case5_2grids_uc_hvdc_strg.m")
    uc_data = prepare_uc_test_data(file; number_of_hours=12)
    @testset "With HVDC & storage, no binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => false)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 4.9679e5 rtol=1e-3
    end
    @testset "With HVDC & storage, with binary relaxation" begin
        s = Dict("conv_losses_mp" => true, "hvdc_inertia_contribution" => true, "relax_uc_binaries" => true)
        result = solve_uc(uc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 4.9679e5 rtol=1e-3
    end
end
@testset "Frequency-Constrained Unit Commitment" begin
    file = pkgdir(PowerModelsACDC, "test", "data", "fcuc_test.m")
    contingencies = Dict("type" => "largest", "elements" => ["gen", "convdc", "storage", "tie_lines"])
    fcuc_data = prepare_uc_test_data(file; contingencies=contingencies, number_of_hours=6)
    @testset "No DC actions" begin
        s = Dict("conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => false, "fix_cross_border_flows" => false)
        result = solve_fcuc(fcuc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 5.7793e6 rtol=1e-3
    end
    @testset "With DC actions" begin
        s = Dict("conv_losses_mp" => true, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => true, "fix_cross_border_flows" => false)
        result = solve_fcuc(fcuc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 1.8343e5 rtol=1e-3
    end
end
@testset "System-Split-Constrained Unit Commitment" begin
    file = pkgdir(PowerModelsACDC, "test", "data", "split_test.m")
    contingencies = Dict("type" => "N-1", "elements" => ["gen"])
    spcuc_data = prepare_uc_test_data(file; contingencies=contingencies, tielines=[8], number_of_hours=6)
    @testset "No split constraints" begin
        s = Dict("conv_losses_mp" => false, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => false, "fix_cross_border_flows" => false, "add_split_constraints" => false)
        result = solve_spcuc(spcuc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 1.1039e5 rtol=1e-3
        @test result["solution"]["nw"]["36"]["branchdc"]["1"]["pf"] ≈ 1.0297 rtol=1e-3
    end
    @testset "With split constraints" begin
        s = Dict("conv_losses_mp" => false, "relax_uc_binaries" => false, "uc_reserves" => false, "hvdc_inertia_contribution" => true, "fix_cross_border_flows" => false, "add_split_constraints" => true)
        result = solve_spcuc(spcuc_data, PowerModels.DCPPowerModel, scip, setting=s, multinetwork=true)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 1.1039e5 rtol=1e-3
        @test result["solution"]["nw"]["36"]["branchdc"]["1"]["pf"] ≈ 1.0297 rtol=1e-3
    end
end
