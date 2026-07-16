@testset "Redispatch Optimal Power Flow" begin
    data_opf = PowerModels.parse_file(pkgdir(PowerModelsACDC, "test", "data", "case5_acdc_pst_3_grids.m"))
    process_additional_data!(data_opf)
    s = Dict("conv_losses_mp" => true, "objective_components" => ["gen", "demand"])
    result_opf = solve_acdcopf(data_opf, PowerModels.DCPPowerModel, highs; setting=s)
    contingency = 8 # Deactivates a line (branch 5)
    rd_cost_factor = 2 # Defines a redispatch cost factor of 2, i.e. redispatch cost = 2 * dispatch cost
    # Use the OPF solution as the starting point for the redispatch minimization problem.
    data = prepare_redispatch_opf_data(result_opf["solution"], data_opf; contingency=contingency, rd_cost_factor=rd_cost_factor)
    @testset "No control" begin
        # Fix HVDC converter setpoints
        s = Dict("output" => Dict("duals" => true), "conv_losses_mp" => false, "fix_converter_setpoints" => true, "inertia_limit" => false, "objective_components" => ["demand"])
        result = solve_rdopf(data, PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 19878.0 atol=1
    end
    @testset "With control" begin
        # Allow HVDC converter setpoints to be determined optimally
        s = Dict("output" => Dict("duals" => true), "conv_losses_mp" => false, "fix_converter_setpoints" => false, "inertia_limit" => false, "objective_components" => ["demand"])
        result = solve_rdopf(data, PowerModels.DCPPowerModel, highs; setting=s)
        @test result["termination_status"] == OPTIMAL
        @test result["objective"] ≈ 19844.6 atol=1
    end
end
