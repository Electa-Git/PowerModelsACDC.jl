"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::GenericPowerModel{T}, n::Int, cnd::Int) where {T <: PowerModels.AbstractWRForm}
    wdc = PowerModels.var(pm, n, cnd, :wdc)
    wdcr = PowerModels.var(pm, n, cnd, :wdcr)

    for (i,j) in PowerModels.ids(pm, n, :buspairsdc)
        InfrastructureModels.relaxation_complex_product(pm.model, wdc[i], wdc[j], wdcr[(i,j)], 0)
    end
end
