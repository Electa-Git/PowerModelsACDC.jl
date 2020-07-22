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

local_test = false

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
scs_solver = JuMP.with_optimizer(SCS.Optimizer)
cbc = JuMP.with_optimizer(Cbc.Optimizer, tol=1e-4, print_level=0)
juniper = JuMP.with_optimizer(Juniper.Optimizer, nl_solver = ipopt_solver, mip_solver= cbc, time_limit= 7200)


if local_test == true
    ### ONLY for local testing, not supported intravis due to licensces ##############
    import Gurobi
    import Mosek
    import MosekTools
    gurobi = JuMP.with_optimizer(Gurobi.Optimizer)
    mosek = JuMP.with_optimizer(Mosek.Optimizer)
    ##############################
end

@testset "PowerModelsACDC" begin

include("pf.jl")

include("opf.jl")

include("tnep.jl")

end
