# Test exported names

@testset "Export" begin

    exported = Set(names(PowerModelsACDC))

    @testset "JuMP" begin
        @test :NO_SOLUTION ∈ exported # Sample check that `ResultStatusCode`s are exported
        @test :OPTIMIZE_NOT_CALLED ∈ exported # Sample check that `TerminationStatusCode`s are exported
        @test :optimizer_with_attributes ∈ exported
    end
end
