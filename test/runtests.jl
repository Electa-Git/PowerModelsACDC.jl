using PowerModelsACDC
using PowerModels
import Memento
import InfrastructureModels
import JuMP

# Suppress warnings during testing.
Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
Memento.setlevel!(Memento.getlogger(PowerModelsACDC), "error")
Memento.setlevel!(Memento.getlogger(PowerModels), "error")

import Ipopt
import Gurobi
#import GLPKMathProgInterface
import SCS
import Cbc
import Mosek
import MosekTools
import Juniper

using Test

# default setup for solvers
# ipopt_solver = IpoptSolver(tol=1e-6, print_level=0)
# #pajarito_solver = PajaritoSolver(mip_solver=GLPKSolverMIP(), cont_solver=ipopt_solver, log_level=0)
# scs_solver = SCSSolver(max_iters=1000000, verbose=0)
# # mosek = MosekSolver()

ipopt_solver = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
scs_solver = JuMP.with_optimizer(SCS.Optimizer)
gurobi = JuMP.with_optimizer(Gurobi.Optimizer)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
cbc = JuMP.with_optimizer(Cbc.Optimizer, tol=1e-4, print_level=0)
juniper = JuMP.with_optimizer(Juniper.Optimizer, nl_solver = ipopt_solver, mip_solver= cbc, time_limit= 7200)

@testset "PowerModelsACDC" begin

include("pf.jl")

include("opf.jl")

include("tnep.jl")

end
