
function variable_dcgrid_voltage_magnitude(pm::AbstractWModels; kwargs...)
    variable_dcgrid_voltage_magnitude_sqr(pm; kwargs...)
end
"""
```
sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) == sum(pg[g] for g in bus_gens)  - pd - gs*w
sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac) == sum(qg[g] for g in bus_gens)  - qd + bs*w
```
"""
function constraint_kcl_shunt(pm::AbstractWModels, n::Int,  i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
    w = PowerModels.var(pm, n, :w, i)
    p = PowerModels.var(pm, n, :p)
    q = PowerModels.var(pm, n, :q)
    pg = PowerModels.var(pm, n, :pg)
    qg = PowerModels.var(pm, n, :qg)
    pconv_grid_ac = PowerModels.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = PowerModels.var(pm, n, :qconv_tf_fr)

    PowerModels.con(pm, n, :kcl_p)[i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*w)
    PowerModels.con(pm, n, :kcl_q)[i] = @constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*w)
end
"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch(pm::AbstractWRModels, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr = PowerModels.var(pm, n, :p_dcgrid, f_idx)
    p_dc_to = PowerModels.var(pm, n, :p_dcgrid, t_idx)
    wdc_fr = PowerModels.var(pm, n, :wdc, f_bus)
    wdc_to = PowerModels.var(pm, n, :wdc, t_bus)
    wdc_frto = PowerModels.var(pm, n, :wdcr, (f_bus, t_bus))

    if r == 0
        @constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        @constraint(pm.model, p_dc_fr == p * g *  (wdc_fr - wdc_frto))
        @constraint(pm.model, p_dc_to == p * g *  (wdc_to - wdc_frto))
    end
end
"`wdc[i] == vdcm^2`"
function constraint_dc_voltage_magnitude_setpoint(pm::AbstractWModels, n::Int,  i, vdcm)
    wdc = PowerModels.var(pm, n, :wdc, i)

    PowerModels.con(pm, n, :v_dc)[i] = @constraint(pm.model, wdc == vdcm^2)
end

function add_dc_bus_voltage_setpoint(sol, pm::AbstractWModels)
    PowerModels.add_setpoint!(sol, pm, "busdc", "vm", :wdc, status_name="Vdc", inactive_status_value = 4; scale = (x,item,cnd) -> sqrt(x))
end

"""
Limits dc branch current

```
p[f_idx] <= wdc[f_bus] * Imax
```
"""
function constraint_dc_branch_current(pm::AbstractWModels, n::Int,  f_bus, f_idx, ccm_max, p)
    p_dc_fr = PowerModels.var(pm, n, :p_dcgrid, f_idx)
    wdc_fr = PowerModels.var(pm, n, :wdc, f_bus)

    @constraint(pm.model, p_dc_fr <= wdc_fr * ccm_max * p^2)
end
