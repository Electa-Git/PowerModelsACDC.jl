using PowerModelsACDC
using Test

import InfrastructureModels
import PowerModels

import Ipopt
import Juniper
import HiGHS

# Settings
local_test = false # If true, additional tests are run using commercial solvers.

# Silence logging within PowerModelsACDC, PowerModels and InfrastructureModels.
silence()

# Solvers
ipopt_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
highs = optimizer_with_attributes(HiGHS.Optimizer)
juniper = optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt_solver, "mip_solver" => highs, "time_limit" => 7200)
if local_test
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

    # Components
    include("im.jl")

    # Exported names
    include("export.jl")
end
