using PowerModelsACDC
using PowerModels
using Memento
using InfrastructureModels
using JuMP

# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
Memento.setlevel!(Memento.getlogger(PowerModelsACDC), "error")
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

using Ipopt
using SCS
using Cbc
using Juniper

using Test

local_test = true   # as some tests require Mosek, only limited set sent to travis.

ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-6, "print_level" => 0)
scs_solver = JuMP.optimizer_with_attributes(SCS.Optimizer, "verbose" => 0)
cbc = JuMP.optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0)
juniper = JuMP.optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt_solver, "mip_solver" => cbc, "time_limit" => 7200)


if local_test == false
    ### ONLY for local testing, not supported intravis due to licensces ##############
    import Gurobi
    import Mosek
    import MosekTools
    # import CPLEX
    gurobi = JuMP.optimizer_with_attributes(Gurobi.Optimizer)
    # cplex = JuMP.optimizer_with_attributes(CPLEX.Optimizer)
    mosek = JuMP.optimizer_with_attributes(Mosek.Optimizer)
    ##############################
end
include("common.jl")
data_dc = build_mn_data("../test/data/tnep/case4_original.m")

@testset "PowerModelsACDC" begin

include("pf.jl")

include("opf.jl")

include("tnep.jl")

end
