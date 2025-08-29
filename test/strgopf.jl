@testset "Storage OPF" begin
    file = "../test/data/case5_2grids_uc_hvdc_strg.m"
    mn_data = prepare_storage_opf_data(file)


    # optimisation settings
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true,  "objective_components" => ["gen", "demand"])

    # run a DC OPF
    result = _PMACDC.solve_acdcopf(mn_data,DCPPowerModel, highs, setting = s, multinetwork = true)

    @test isapprox(result["objective"], 5.41642e6, atol = 1e2)
end