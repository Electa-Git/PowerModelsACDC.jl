"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::AbstractWRModel, n::Int, cnd::Int)
    wdc = PowerModels.var(pm, n, cnd, :wdc)
    wdcr = PowerModels.var(pm, n, cnd, :wdcr)

    for (i,j) in PowerModels.ids(pm, n, :buspairsdc)
        JuMP.@constraint(pm.model, wdcr[(i,j)]^2 <= wdc[i]*wdc[j])
        # InfrastructureModels.relaxation_product(pm.model, wdc[i], wdc[j], wdcr_, wdcr_)
    end
end

function constraint_voltage_dc(pm::AbstractWRConicModel, n::Int, cnd::Int)
    wdc = PowerModels.var(pm, n, cnd, :wdc)
    wdcr = PowerModels.var(pm, n, cnd, :wdcr)

    for (i,j) in PowerModels.ids(pm, n, :buspairsdc)
        relaxation_complex_product_conic(pm.model, wdc[i], wdc[j], wdcr[(i,j)])
    end
end

"""
Limits dc branch current

```
p[f_idx] <= wdc[f_bus] * Imax
```
"""
function constraint_dc_branch_current(pm::AbstractWRModel, n::Int, cnd::Int, f_bus, f_idx, ccm_max, p)
    p_dc_fr = PowerModels.var(pm, n, cnd, :p_dcgrid, f_idx)
    wdc_fr = PowerModels.var(pm, n, cnd, :wdc, f_bus)

    @constraint(pm.model, p_dc_fr <= wdc_fr * ccm_max * p^2)
end
