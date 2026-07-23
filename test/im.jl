@testset "Induction Machine" begin
    data = inductionmachine_data()
    @testset "ACPPowerModel" begin
        result = solve_acdcpf(data, PowerModels.ACPPowerModel, ipopt)
        @test result["termination_status"] == LOCALLY_SOLVED
        @test result["solution"]["im"]["1"]["pg"] ≈ 0.8944 rtol=1e-3
        @test result["solution"]["im"]["1"]["qg"] ≈ 0.8633 rtol=1e-3
    end
end
