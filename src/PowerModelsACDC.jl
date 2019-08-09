isdefined(Base, :__precompile__) && __precompile__()

module PowerModelsACDC

# using Compat
using JuMP
using PowerModels
using InfrastructureModels
using Memento

# import Compat: @__MODULE__

# using Compat.LinearAlgebra
# using Compat.SparseArrays
#
# PMs = PowerModels

import JuMP: with_optimizer
export with_optimizer


include("prob/acdcopf.jl")
include("prob/acdcpf.jl")
include("prob/acdcopf_bf.jl")
include("core/solution.jl")
include("core/data.jl")
include("core/variabledcgrid.jl")
include("core/variableconv.jl")
include("core/base.jl")
include("core/constraint.jl")
include("core/objective.jl")
include("core/relaxation_scheme.jl")

include("formdcgrid/acp.jl")
include("formdcgrid/dcp.jl")
include("formdcgrid/wr.jl")
include("formdcgrid/wrm.jl")
include("formdcgrid/df.jl")
include("formdcgrid/shared.jl")

include("formconv/acp.jl")
include("formconv/dcp.jl")
include("formconv/wr.jl")
include("formconv/wrm.jl")
include("formconv/df.jl")
include("formconv/shared.jl")

include("core/constraint_template.jl")
end
