
"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
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
Model to approximate cross products of node voltages
```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::_PM.AbstractBFModel, n::Int = pm.cnw)
# do nothing
end

function variable_dcbranch_current(pm::_PM.AbstractBFModel; kwargs...)
    variable_dcbranch_current_sqr(pm; kwargs...)
end
function constraint_dc_branch_current(pm::_PM.AbstractBFModel, n::Int, f_bus, f_idx, ccm_max, p)
# do nothing
end

########## TNEP constraints #####################

"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch_ne(pm::_PM.AbstractBFQPModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    l = f_idx[1];
    p_dc_fr = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    ccm_dcgrid = _PM.var(pm, n, :ccm_dcgrid_ne, l)
    z = _PM.var(pm, n, :branch_ne, l)

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

function constraint_ohms_dc_branch_ne(pm::_PM.AbstractBFConicModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    l = f_idx[1];
    p_dc_fr = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    ccm_dcgrid = _PM.var(pm, n, :ccm_dcgrid_ne, l)
    z = _PM.var(pm, n, :branch_ne, l)

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
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc_ne(pm::_PM.AbstractBFModel, n::Int)
# do nothing
end
function variable_dcbranch_current_ne(pm::_PM.AbstractBFModel; kwargs...)
    variable_dcbranch_current_sqr_ne(pm; kwargs...)
end
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
