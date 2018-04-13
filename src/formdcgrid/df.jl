
"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, r, p) where {T <: PowerModels.AbstractDFForm}
    l = f_idx[1];
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]
    ccm_dcgrid = pm.var[:nw][n][:ccm_dcgrid][l]

    wdc_fr = pm.var[:nw][n][:wdc][f_bus]
    wdc_to = pm.var[:nw][n][:wdc][t_bus]

    @constraint(pm.model, p_dc_fr + p_dc_to ==  r/p * ccm_dcgrid)
    @NLconstraint(pm.model, p_dc_fr^2 <= wdc_fr*ccm_dcgrid)
    @constraint(pm.model, wdc_to == wdc_fr - 2*(r/p)*p_dc_fr + (r/p)^2*ccm_dcgrid)
end

"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::GenericPowerModel{T}, n::Int) where {T <: PowerModels.AbstractDFForm}
# do nothing
end

function variable_dcbranch_current(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDFForm}
    variable_dcbranch_current_sqr(pm, n; kwargs...)
end
