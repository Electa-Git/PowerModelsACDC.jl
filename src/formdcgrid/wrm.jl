"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::GenericPowerModel{T}, n::Int) where {T <: PowerModels.AbstractWRMForm}
    wdc = pm.var[:nw][n][:wdc]
    wdcr = pm.var[:nw][n][:wdcr]

    for (i,j) in keys(pm.ref[:nw][n][:buspairsdc])
        @constraint(pm.model, norm([ 2*wdcr[(i,j)]; wdc[i]-wdc[j] ]) <= wdc[i]+wdc[j] )
    end
end
