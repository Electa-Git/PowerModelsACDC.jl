using PowerModelsACDC
using PowerModels
using Memento
using InfrastructureModels
using JuMP

# Suppress warnings during testing.
setlevel!(Memento.getlogger(InfrastructureModels), "error")
setlevel!(Memento.getlogger(PowerModelsACDC), "error")
setlevel!(Memento.getlogger(PowerModels), "error")

using Ipopt
#using Pajarito
#using GLPKMathProgInterface
using SCS
#using Mosek

using Test

# default setup for solvers
# ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
# #pajarito_solver = PajaritoSolver(mip_solver=GLPKSolverMIP(), cont_solver=ipopt_solver, log_level=0)
# scs_solver = SCSSolver(max_iters=1000000, verbose=0)
# # mosek = MosekSolver()

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
scs_solver = JuMP.with_optimizer(SCS.Optimizer)

@testset "PowerModelsACDC" begin

include("pf.jl")

include("opf.jl")

end
