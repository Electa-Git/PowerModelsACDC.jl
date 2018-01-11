isdefined(Base, :__precompile__) && __precompile__()

module PowerModelsACDC

using Compat
using JuMP
using PowerModels
PMs = PowerModels

#include("core/variable.jl")

end
