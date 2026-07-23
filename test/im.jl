@testset "Induction Machine" begin

    data = inductionmachine_data()
    # ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-8, "print_level" => 5, "max_iter" => 4000, "check_derivatives_for_naninf" => "yes", "grad_f_constant"=>"yes",
                                                # "bound_relax_factor" => 1e-8, "expect_infeasible_problem"=> "yes", "fixed_variable_treatment"=>"relax_bounds")

    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false)
    result = solve_acdcpf(data, PowerModels.ACPPowerModel, Ipopt.Optimizer; setting = s)

    # Grid active and reactive power from solving the detailed state-space equations of IM
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["solution"]["im"]["1"]["pg"], 0.89442199456220407, atol=1e-7)
    @test isapprox(result["solution"]["im"]["1"]["qg"], 0.8632554248071891, atol=1e-7)

end