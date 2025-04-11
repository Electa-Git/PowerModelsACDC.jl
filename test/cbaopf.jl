@testset "CBA OPF" begin
    data = PowerModels.parse_file("../test/data/case5_acdc_pst_3_grids.m")
    _PMACDC.process_additional_data!(data) 
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true, "objective_components" => ["gen", "demand"])
    resultOPF = _PMACDC.solve_acdcopf(data, DCPPowerModel, highs; setting = s)
    @testset "Basic OPF with flex demand" begin
        @test isapprox(resultOPF["objective"], 24021.7, atol = 1)
        @test isapprox(resultOPF["solution"]["gen"]["3"]["pg"], 0.955232, atol = 1e-1)
        @test isapprox(resultOPF["solution"]["branch"]["2"]["pt"], -1.20165, atol = 1e-2)
        @test isapprox(resultOPF["solution"]["convdc"]["4"]["ptf_to"], 0.977907, atol = 1e-2)
    end

    @testset "Redispatch OPF" begin
        # Let us deactivate a line (branch 5) and run the redispatch minimisation problem
        contingency = 8
        # we define a redispatch cost factor of 2, e.g. redispatch cost = 2 * dispatch cost
        rd_cost_factor = 2
        # Write OPF solution as starting point to the redispatch minimisation problem
        dataRD = _PMACDC.prepare_redispatch_opf_data(resultOPF["solution"], data; contingency = contingency, rd_cost_factor = rd_cost_factor)
        @testset "Redispatch OPF no control" begin
            # Provide settings for the optimisation problem, here we fix the HVDC converter set points
            s = Dict("output" => Dict("branch_flows" => true, "duals" =>true), "conv_losses_mp" => false, "fix_converter_setpoints" => true, "inertia_limit" => false, "objective_components" => ["demand"])
            # Run optimisation problem
            resultRD_no_control = _PMACDC.solve_rdopf(dataRD, DCPPowerModel, highs; setting = s) 
            @test isapprox(resultRD_no_control["objective"],  19878.0, atol = 1)
        end
        @testset "Redispatch OPF with control" begin
        # Now we allow the HVDC converter set points to be determined optimally
            s = Dict("output" => Dict("branch_flows" => true, "duals" =>true), "conv_losses_mp" => false, "fix_converter_setpoints" => false, "inertia_limit" => false, "objective_components" => ["demand"])
            resultRD_with_control = _PMACDC.solve_rdopf(dataRD, DCPPowerModel, highs; setting = s) 
            @test isapprox(resultRD_with_control["objective"], 19844.6, atol = 1)
        end
    end
end