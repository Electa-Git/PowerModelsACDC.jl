using PowerModelsACDC
using Test

import InfrastructureModels
import PowerModels

import Ipopt
import Juniper
import HiGHS
import SCIP

# Settings
logging = false # Print logs from modeling packages and solvers to the REPL.

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
highs = optimizer_with_attributes(
    HiGHS.Optimizer,
    "output_flag" => logging ? true : false
)
juniper = optimizer_with_attributes(
    Juniper.Optimizer,
    "nl_solver" => ipopt,
    "mip_solver" => highs,
    "log_levels" => logging ? [:Table, :Info, :Options] : []
)
scip = optimizer_with_attributes(
    SCIP.Optimizer,
    "display/verblevel" => logging ? 3 : 0
)

# Functions to load test data
include("common.jl")

@testset "PowerModelsACDC" begin

    # Components
    include("conv.jl")
    include("dcgen.jl")
    include("pst.jl")
    include("sssc.jl")

    # Problems
    include("pf.jl")
    include("spf.jl")
    include("opf.jl")
    include("rdopf.jl")
    include("uc.jl")
    include("tnep.jl")

    # Other
    include("data.jl")
    include("export.jl")
end; # The colon suppresses output when running tests in a REPL.
