isdefined(Base, :__precompile__) && __precompile__()

module PowerModelsACDC

using Compat
using JuMP
using PowerModels
PMs = PowerModels

include("prob/acdcopf.jl")
include("core/solution.jl")
include("core/data.jl")
#include("core/variable.jl")

end
