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
        @constraint(pm.model, norm([ 2*wdcr[(i,j)]; wdc[i]-wdc[j] ]) <= wdc[i]+wdc[j] )
    end
end
