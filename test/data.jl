@testset "Data" begin
    @testset "parse_file" begin
        @testset "PowerModels data" begin
            # Sample check that PowerModels data are imported and scaled correctly.
            data = parse_file(pkgdir(PowerModelsACDC, "test", "data", "case3.m"))
            @test typeof(data) == Dict{String,Any}
            @test data["per_unit"] == true
            @test data["baseMVA"] == 100.0
            @test data["bus"]["1"]["vm"] == 1.1
            @test data["gen"]["1"]["pmax"] == 20.0
            @test data["gen"]["1"]["cost"] == [1100.0; 500.0; 0.0]
            @test data["branch"]["1"]["rate_a"] == 90.0
            @test data["branch"]["1"]["number_id"] == 123 # Named column in Matpower table extension
        end
        @testset "PowerModelsACDC data" begin
            # Sample check that PowerModelsACDC data are imported and scaled correctly.
            # The correctness of data from individual network components should be tested separately.
            data = parse_file(pkgdir(PowerModelsACDC, "test", "data", "tnep", "case4_acdc.m"))
            @test typeof(data) == Dict{String,Any}
            @test data["per_unit"] == true
            @test data["baseMVA"] == 100.0
            @test data["busdc"]["1"]["Vdcmax"] == 1.1
            @test data["busdc_ne"]["3"]["Vdcmax"] == 1.1
            @test data["branchdc"]["1"]["rateA"] == 2.5
            @test data["branchdc_ne"]["1"]["rateA"] == 2.0
            @test data["convdc"]["1"]["Pacmax"] == 2.5
            @test data["convdc_ne"]["1"]["Pacmax"] == 1.0
        end
    end
end
