"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::GenericPowerModel{T}, n::Int, cnd::Int) where {T <: PowerModels.AbstractWRMForm}
    wdc = PowerModels.var(pm, n, cnd, :wdc)
    wdcr = PowerModels.var(pm, n, cnd, :wdcr)

    for (i,j) in PowerModels.ids(pm, n, :buspairsdc)
        @constraint(pm.model, [ wdc[i]/sqrt(2), wdc[j]/sqrt(2), wdcr[(i,j)]/sqrt(2), wdcr[(i,j)]/sqrt(2)] in JuMP.RotatedSecondOrderCone() )
    end
end

"""
Limits dc branch current

```
p[f_idx] <= wdc[f_bus] * Imax
```
"""
function constraint_dc_branch_current(pm::GenericPowerModel{T}, n::Int, cnd::Int, f_bus, f_idx, ccm_max, p) where {T <: PowerModels.AbstractWRMForm}
    p_dc_fr = PowerModels.var(pm, n, cnd, :p_dcgrid, f_idx)
    wdc_fr = PowerModels.var(pm, n, cnd, :wdc, f_bus)

    @constraint(pm.model, p_dc_fr <= wdc_fr * ccm_max * p^2)
end
