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
import SparseArrays
import NLsolve

import JuMP: optimizer_with_attributes
export optimizer_with_attributes

# Create our module level logger (this will get precompiled)
const _LOGGER = Memento.getlogger(@__MODULE__)

# Register the module level logger at runtime so that folks can access the logger via `getlogger(PowerModels)`
# NOTE: If this line is not included then the precompiled `_PM._LOGGER` won't be registered at runtime.
__init__() = Memento.register(_LOGGER)


include("prob/acdcopf.jl")
include("prob/acdcpf.jl")
include("prob/acdcopf_bf.jl")
include("prob/acdcopf_iv.jl")
include("prob/tnep.jl")
include("prob/sacdcpf.jl")
include("prob/uc.jl")
include("prob/rdopf.jl")

include("core/solution.jl")
include("core/data.jl")
include("core/base.jl")
include("core/constraint.jl")
include("core/constraint_template.jl")
include("core/objective.jl")
include("core/relaxation_scheme.jl")
include("core/util.jl")

include("components/demand.jl")
include("components/gen.jl")
include("components/pst.jl")
include("components/dcbranch.jl")
include("components/dcconverter.jl")
include("components/storage.jl")

include("formdcgrid/acp.jl")
include("formdcgrid/acr.jl")
include("formdcgrid/dcp.jl")
include("formdcgrid/wr.jl")
include("formdcgrid/wrm.jl")
include("formdcgrid/bf.jl")
include("formdcgrid/lpac.jl")
include("formdcgrid/shared.jl")
include("formdcgrid/iv.jl")

include("formconv/acp.jl")
include("formconv/acr.jl")
include("formconv/dcp.jl")
include("formconv/wr.jl")
include("formconv/wrm.jl")
include("formconv/bf.jl")
include("formconv/lpac.jl")
include("formconv/shared.jl")
include("formconv/iv.jl")

include("io/multinetwork.jl")
include("io/results.jl")
end
