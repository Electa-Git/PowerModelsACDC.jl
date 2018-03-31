
"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p) where {T <: PowerModels.AbstractDFForm}
    l = f_idx[1];
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]
    ccm_dcgrid = pm.var[:nw][n][:ccm_dcgrid][l]

    wdc_fr = pm.var[:nw][n][:wdc][f_bus]

    r = 1/g

    @constraint(pm.model, p_dc_fr + p_dc_to == p * r * ccm_dcgrid)
    @NLconstraint(pm.model, p_dc_fr^2 <= wdc_fr*ccm_dcgrid)
end

"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::GenericPowerModel{T}, n::Int) where {T <: PowerModels.AbstractDFForm}
    wdc = pm.var[:nw][n][:wdc]
    wdcr = pm.var[:nw][n][:wdcr]

    for (i,j) in keys(pm.ref[:nw][n][:buspairsdc])
        PowerModels.relaxation_complex_product(pm.model, wdc[i], wdc[j], wdcr[(i,j)], 0)
    end
end

function variable_dcbranch_current(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDFForm}
    variable_dcbranch_current_sqr(pm, n; kwargs...)
end
