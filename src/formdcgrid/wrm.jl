"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::_PM.AbstractWRMModel, n::Int)
    wdc = _PM.var(pm, n, :wdc)
    wdcr = _PM.var(pm, n, :wdcr)

    for (i,j) in _PM.ids(pm, n, :buspairsdc)
        JuMP.@constraint(pm.model, [ wdc[i]/sqrt(2), wdc[j]/sqrt(2), wdcr[(i,j)]/sqrt(2), wdcr[(i,j)]/sqrt(2)] in JuMP.RotatedSecondOrderCone() )
    end
end

"""
Limits dc branch current

```
p[f_idx] <= wdc[f_bus] * Imax
```
"""
function constraint_dc_branch_current(pm::_PM.AbstractWRMModel, n::Int, f_bus, f_idx, ccm_max, p)
    p_dc_fr = _PM.var(pm, n, :p_dcgrid, f_idx)
    wdc_fr = _PM.var(pm, n, :wdc, f_bus)

    JuMP.@constraint(pm.model, p_dc_fr <= wdc_fr * ccm_max * p^2)
end

############## TNEP constraints ###################
"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc_ne(pm::_PM.AbstractWRMModel, n::Int)
    wdc = _PM.var(pm, n, :wdc_ne)
    wdc_frto = _PM.var(pm, n, :wdcr_ne)
    wdc_du_frto = _PM.var(pm, n, :wdcr_du)
    wdc_du_to = _PM.var(pm, n, :wdc_du_to)
    wdc_du_fr = _PM.var(pm, n, :wdc_du_fr)
    z  = _PM.var(pm, n, :branch_ne)

        for (l,i,j) in pm.ref[:nw][n][:arcs_dcgrid_from_ne]
        wdc_to = []
        wdc_fr = []
        wdc_to, wdc_fr = contraint_ohms_dc_branch_busvoltage_structure_W(pm, n, i, j, wdc_du_to, wdc_du_fr)
        JuMP.@constraint(pm.model, [ wdc_du_to[l]/sqrt(2), wdc_du_fr[l]/sqrt(2), wdc_du_frto[l]/sqrt(2), wdc_du_frto[l]/sqrt(2)] in JuMP.RotatedSecondOrderCone() )
        end
end
