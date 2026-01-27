"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```

Overloads are provided for QP and conic BF models. The QP variant uses a simple
quadratic relaxation for the cross-product term while the conic variant uses a
rotated second-order cone representation to model p_dc_fr^2 <= p^2 * wdc_fr * ccm_dcgrid.
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractBFQPModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    l = f_idx[1];
    p_dc_fr = _PM.var(pm, n,  :p_dcgrid, f_idx)
    p_dc_to = _PM.var(pm, n,  :p_dcgrid, t_idx)
    ccm_dcgrid = _PM.var(pm, n,  :ccm_dcgrid, l)
    wdc_fr = _PM.var(pm, n,  :wdc, f_bus)
    wdc_to = _PM.var(pm, n,  :wdc, t_bus)

    JuMP.@constraint(pm.model, p_dc_fr + p_dc_to ==  r * p * ccm_dcgrid)
    JuMP.@constraint(pm.model, p_dc_fr^2 <= p^2 * wdc_fr * ccm_dcgrid)
    JuMP.@constraint(pm.model, wdc_to == wdc_fr - 2 * r * (p_dc_fr/p) + (r)^2 * ccm_dcgrid)
end

"""
Creates Ohms constraints for DC branches using conic relaxation.

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```

Uses rotated second-order cone for the quadratic term.
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractBFConicModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    l = f_idx[1];
    p_dc_fr = _PM.var(pm, n,  :p_dcgrid, f_idx)
    p_dc_to = _PM.var(pm, n,  :p_dcgrid, t_idx)
    ccm_dcgrid = _PM.var(pm, n,  :ccm_dcgrid, l)
    wdc_fr = _PM.var(pm, n,  :wdc, f_bus)
    wdc_to = _PM.var(pm, n,  :wdc, t_bus)

    JuMP.@constraint(pm.model, p_dc_fr + p_dc_to ==  r * p * ccm_dcgrid)
    JuMP.@constraint(pm.model, [p*wdc_fr/sqrt(2), p*ccm_dcgrid/sqrt(2), p_dc_fr/sqrt(2), p_dc_fr/sqrt(2)] in JuMP.RotatedSecondOrderCone())
    JuMP.@constraint(pm.model, wdc_to == wdc_fr - 2 * r * (p_dc_fr/p) + (r)^2 * ccm_dcgrid)
end

"""
Model hook for DC voltage cross-product approximations in BF models.

Default BF implementation does nothing because node-voltage cross-products are
handled implicitly by the Ohm constraints above. This function is provided so
other backends can override or extend the voltage-cross-product handling if
required (e.g., QC relaxations or explicit wdc cross-term modelling).
"""
function constraint_voltage_dc(pm::_PM.AbstractBFModel, n::Int = _PM.nw_id_default)
# do nothing
end
"""
Generic dispatcher for DC branch current variables.

On BF models this forwards to the squared-current variant. Concrete variable
constructors may differ between model backends (BFQP, BFConic, IVR, ...).
"""
function variable_dcbranch_current(pm::_PM.AbstractBFModel; kwargs...)
    variable_dcbranch_current_sqr(pm; kwargs...)
end
"""
DC branch current constraint for BF/QP models (no-op placeholder).

BF/QP backends that require explicit current-based thermal or device limits can
override this function. The default BF/QP implementation does not add extra
constraints here since Ohm-law constraints already bind p_dc variables to voltages.
"""
function constraint_dc_branch_current(pm::_PM.AbstractBFModel, n::Int, f_bus, f_idx, ccm_max, p)
# do nothing
end
"""
DC branch current constraint for IVR-formulated models.

This overload exists so IVR-specific implementations can add current-based
constraints (thermal limits, current squaring relations, etc.). The default
body delegates to the IVR current variable constructor to ensure variables
exist; backends should implement `variable_dcbranch_current_iv`.
"""
function constraint_dc_branch_current(pm::_PM.AbstractIVRModel, n::Int, f_bus, f_idx, ccm_max, p)
    variable_dcbranch_current_iv(pm; kwargs...)
end


#################################################
########## TNEP constraints #####################
#################################################


"""
Creates Ohms constraints for DC branches in the presence of network expansion
(candidates). The semantics are analogous to `constraint_ohms_dc_branch` but
operate on the "_ne" (network expansion) variable sets such as :p_dcgrid_ne and
:ccm_dcgrid_ne and enforce on/off linking through the candidate indicator `z`.
"""
function constraint_ohms_dc_branch_ne(pm::_PM.AbstractBFQPModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    l = f_idx[1];
    p_dc_fr = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    ccm_dcgrid = _PM.var(pm, n, :ccm_dcgrid_ne, l)
    z = _PM.var(pm, n, :branchdc_ne, l)

    wdc_to = []
    wdc_fr = []

    wdc_to, wdc_fr = contraint_ohms_dc_branch_busvoltage_structure_W(pm, n, f_bus, t_bus, wdc_to, wdc_fr)
    wdc_du_to = _PM.var(pm, n, :wdc_du_to, l)
    wdc_du_fr = _PM.var(pm, n, :wdc_du_fr, l)

    JuMP.@constraint(pm.model, p_dc_fr + p_dc_to ==  r * p * ccm_dcgrid)
    JuMP.@constraint(pm.model, p_dc_fr^2 <= p^2 * wdc_fr * ccm_dcgrid)

    # different type of on_off constraint
    JuMP.@constraint(pm.model, wdc_du_to  == wdc_du_fr - 2 * r * (p_dc_fr/p) + (r)^2 * ccm_dcgrid)
    JuMP.@constraint(pm.model, wdc_du_to <= wdc_to - JuMP.lower_bound(wdc_to)*(1-z))
    JuMP.@constraint(pm.model, wdc_du_to >= wdc_to - JuMP.upper_bound(wdc_fr)*(1-z))
    JuMP.@constraint(pm.model, wdc_du_fr <= wdc_fr - JuMP.lower_bound(wdc_to)*(1-z))
    JuMP.@constraint(pm.model, wdc_du_fr >= wdc_fr - JuMP.upper_bound(wdc_fr)*(1-z))
    JuMP.@constraint(pm.model, wdc_du_to <= z* JuMP.upper_bound(wdc_to))
    JuMP.@constraint(pm.model, wdc_du_to >= z* JuMP.lower_bound(wdc_to))
    JuMP.@constraint(pm.model, wdc_du_fr <= z* JuMP.upper_bound(wdc_fr))
    JuMP.@constraint(pm.model, wdc_du_fr >= z* JuMP.lower_bound(wdc_fr))


end

"""
Creates Ohms constraints for DC branches in network expansion using conic relaxation.

Analogous to `constraint_ohms_dc_branch_ne` but with conic constraints for the quadratic terms.
"""
function constraint_ohms_dc_branch_ne(pm::_PM.AbstractBFConicModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    l = f_idx[1];
    p_dc_fr = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    ccm_dcgrid = _PM.var(pm, n, :ccm_dcgrid_ne, l)
    z = _PM.var(pm, n, :branchdc_ne, l)

    wdc_to = []
    wdc_fr = []

    wdc_to, wdc_fr = contraint_ohms_dc_branch_busvoltage_structure_W(pm, n, f_bus, t_bus, wdc_to, wdc_fr)
    wdc_du_to = _PM.var(pm, n, :wdc_du_to, l)
    wdc_du_fr = _PM.var(pm, n, :wdc_du_fr, l)


    JuMP.@constraint(pm.model, p_dc_fr + p_dc_to ==  r * p * ccm_dcgrid)
    JuMP.@constraint(pm.model, [p*wdc_fr/sqrt(2), p*ccm_dcgrid/sqrt(2), p_dc_fr/sqrt(2), p_dc_fr/sqrt(2)] in JuMP.RotatedSecondOrderCone())

    # different type of on_off constraint
    JuMP.@constraint(pm.model, wdc_du_to  == wdc_du_fr - 2 * r * (p_dc_fr/p) + (r)^2 * ccm_dcgrid)
    JuMP.@constraint(pm.model, wdc_du_to <= wdc_to - JuMP.lower_bound(wdc_to)*(1-z))
    JuMP.@constraint(pm.model, wdc_du_to >= wdc_to - JuMP.upper_bound(wdc_to)*(1-z))
    JuMP.@constraint(pm.model, wdc_du_fr <= wdc_fr - JuMP.lower_bound(wdc_fr)*(1-z))
    JuMP.@constraint(pm.model, wdc_du_fr >= wdc_fr - JuMP.upper_bound(wdc_fr)*(1-z))
    JuMP.@constraint(pm.model, wdc_du_to <= z* JuMP.upper_bound(wdc_to))
    JuMP.@constraint(pm.model, wdc_du_to >= z* JuMP.lower_bound(wdc_to))
    JuMP.@constraint(pm.model, wdc_du_fr <= z* JuMP.upper_bound(wdc_fr))
    JuMP.@constraint(pm.model, wdc_du_fr >= z* JuMP.lower_bound(wdc_fr))
end

"""
Model hook for DC voltage cross-product approximations in NE (candidate) contexts.

Default BF implementation is a no-op. This hook exists for backends that need to
create explicit wdc_ne cross-product variables or additional linking constraints.
"""
function constraint_voltage_dc_ne(pm::_PM.AbstractBFModel, n::Int)
# do nothing
end
"""
Dispatcher for NE DC branch current variable creation.

By default forwards to the squared-current NE variable constructor. Backends
that require alternative representations should override `variable_dcbranch_current_ne`.
"""
function variable_dcbranch_current_ne(pm::_PM.AbstractBFModel; kwargs...)
    variable_dcbranch_current_sqr_ne(pm; kwargs...)
end
"""
Helper that maps the from/to bus indices to the corresponding DC-voltage variables
used by the NE branch Ohm constraints.

Returns a pair (wdc_to, wdc_fr) where each entry is either the normal :wdc
variable or the :wdc_ne variable depending on which bus index is provided.
This abstraction centralizes the selection logic used by the NE Ohm constraints
above.
"""
function contraint_ohms_dc_branch_busvoltage_structure_W(pm::_PM.AbstractPowerModel, n::Int, f_bus, t_bus, wdc_to, wdc_fr)
    for i in _PM.ids(pm, n, :busdc_ne)
        if t_bus == i
            wdc_to = _PM.var(pm, n, :wdc_ne, t_bus)
        end
        if f_bus == i
            wdc_fr = _PM.var(pm, n, :wdc_ne, f_bus)
        end
    end
    for i in _PM.ids(pm, n, :busdc)
        if t_bus == i
            wdc_to = _PM.var(pm, n, :wdc, t_bus)
        end
        if f_bus == i
            wdc_fr = _PM.var(pm, n, :wdc, f_bus)
        end
    end
    return wdc_to, wdc_fr
end
