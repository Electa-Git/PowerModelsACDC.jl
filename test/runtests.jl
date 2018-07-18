using PowerModelsACDC
using PowerModels
using Memento

# Suppress warnings during testing.
setlevel!(getlogger(InfrastructureModels), "error")
setlevel!(getlogger(PowerModelsACDC), "error")
setlevel!(getlogger(PowerModels), "error")

using Ipopt
#using Pajarito
#using GLPKMathProgInterface
using SCS
#using Mosek

using Base.Test

# default setup for solvers
ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
#pajarito_solver = PajaritoSolver(mip_solver=GLPKSolverMIP(), cont_solver=ipopt_solver, log_level=0)
scs_solver = SCSSolver(max_iters=1000000, verbose=0)
# mosek = MosekSolver()

@testset "PowerModelsACDC" begin

include("pf.jl")

include("opf.jl")

end
