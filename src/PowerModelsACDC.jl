isdefined(Base, :__precompile__) && __precompile__()

module PowerModelsACDC

# import Compat
import JuMP
import Memento
import PowerModels
const _PM = PowerModels
import InfrastructureModels
# import InfrastructureModels: ids, ref, var, con, sol, nw_ids, nws, optimize_model!, @im_fields
const _IM = InfrastructureModels

import JuMP: with_optimizer
export with_optimizer

# Create our module level logger (this will get precompiled)
const _LOGGER = Memento.getlogger(@__MODULE__)

# Register the module level logger at runtime so that folks can access the logger via `getlogger(PowerModels)`
# NOTE: If this line is not included then the precompiled `_PM._LOGGER` won't be registered at runtime.
__init__() = Memento.register(_LOGGER)


include("prob/acdcopf.jl")
include("prob/acdcpf.jl")
include("prob/acdcopf_bf.jl")
include("prob/tnepopf.jl")
include("prob/acdctnepopf.jl")
include("prob/tnepopf_bf.jl")
include("prob/acdctnepopf_bf.jl")
include("prob/mp_tnepopf.jl")
include("prob/mp_acdctnepopf.jl")
include("prob/mp_tnepopf_bf.jl")
include("prob/mp_acdctnepopf_bf.jl")



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
include("formdcgrid/bf.jl")
include("formdcgrid/lpac.jl")
include("formdcgrid/shared.jl")

include("formconv/acp.jl")
include("formconv/dcp.jl")
include("formconv/wr.jl")
include("formconv/wrm.jl")
include("formconv/bf.jl")
include("formconv/lpac.jl")
include("formconv/shared.jl")

include("core/constraint_template.jl")
include("io/multinetwork.jl")
include("io/results.jl")
end
