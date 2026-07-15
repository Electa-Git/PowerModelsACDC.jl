module PowerModelsACDC

import InfrastructureModels as _IM
import JuMP
import LinearAlgebra
import Logging
import NLsolve
import PowerModels as _PM
import SparseArrays

function __init__()
    logger_config!("info")
    return
end

include("core/logging.jl")
include("core/data.jl")
include("core/base.jl")
include("core/constraint.jl")
include("core/constraint_template.jl")
include("core/objective.jl")
include("core/relaxation_scheme.jl")
include("core/util.jl")

include("prob/acdcopf.jl")
include("prob/acdcpf.jl")
include("prob/acdcopf_bf.jl")
include("prob/acdcopf_iv.jl")
include("prob/tnep.jl")
include("prob/sacdcpf.jl")
include("prob/uc.jl")
include("prob/fcuc.jl")
include("prob/rdopf.jl")
include("prob/scopf.jl")
include("prob/spcuc.jl")
include("prob/rocofuc.jl")

include("security/contingency.jl")
include("security/frequency.jl")

include("components/demand.jl")
include("components/gen.jl")
include("components/dcgen.jl")
include("components/pst.jl")
include("components/sssc.jl")
include("components/dcbranch.jl")
include("components/dcconverter.jl")
include("components/storage.jl")
include("components/xb_connections.jl")
include("components/branch.jl")

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

# This must come last to support automated export
include("core/export.jl")

end  # module PowerModelsACDC
