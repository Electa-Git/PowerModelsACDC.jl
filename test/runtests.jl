using PowerModelsACDC
using Test

import InfrastructureModels
import PowerModels

import Ipopt
import Juniper
import HiGHS

# Settings
logging = false # Print logs from modeling packages and solvers to the REPL.
use_commercial_solvers = false # Run additional tests using commercial solvers.

if logging
    logger_config!("info")
    PowerModels.logger_config!("info")
    InfrastructureModels.logger_config!("info")
else
    silence(all_levels=true) # Silence logging within PowerModelsACDC, PowerModels and InfrastructureModels.
end

# Solvers
ipopt = optimizer_with_attributes(
    Ipopt.Optimizer,
    "tol" => 1e-6,
    "print_level" => logging ? 2 : 0,
    "sb" => "yes"
)
ipopt_warmstart = optimizer_with_attributes(
    Ipopt.Optimizer,
    "warm_start_init_point" => "yes",
    "tol" => 1e-6,
    "print_level" => logging ? 2 : 0,
    "sb" => "yes"
)
highs = optimizer_with_attributes(
    HiGHS.Optimizer,
    "output_flag" => logging ? true : false
)
juniper = optimizer_with_attributes(
    Juniper.Optimizer,
    "nl_solver" => ipopt,
    "mip_solver" => highs,
    "log_levels" => logging ? [:Table,:Info,:Options] : []
)
juniper_warmstart = optimizer_with_attributes(
    Juniper.Optimizer,
    "nl_solver" => ipopt_warmstart,
    "mip_solver" => highs,
    "log_levels" => logging ? [:Table,:Info,:Options] : []
)
if use_commercial_solvers
    import Gurobi
    gurobi = optimizer_with_attributes(
        Gurobi.Optimizer,
        "OutputFlag" => logging ? 1 : 0
    )
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
end; # The colon suppresses output when running tests in a REPL.
