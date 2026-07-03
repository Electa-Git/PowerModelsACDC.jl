using PowerModelsACDC
using Test

import InfrastructureModels
import PowerModels

import Ipopt
import Juniper
import HiGHS

# Settings
use_commercial_solvers = false # Run additional tests using commercial solvers.

# Silence logging within PowerModelsACDC, PowerModels and InfrastructureModels.
silence()

# Solvers
ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
highs = optimizer_with_attributes(HiGHS.Optimizer)
juniper = optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt, "mip_solver" => highs, "time_limit" => 7200)
if use_commercial_solvers
    import Gurobi
    gurobi = optimizer_with_attributes(Gurobi.Optimizer)
end

# Functions to load test data
include("common.jl")

@testset "PowerModelsACDC" begin

    # Problems
    include("pf.jl")
    include("opf.jl")
    include("cbaopf.jl")
    include("tnep.jl")
    include("spf.jl")
    include("uc.jl")
    include("strgopf.jl")

    # Exported names
    include("export.jl")
end
