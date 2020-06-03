
function variable_dcgrid_voltage_magnitude(pm::_PM.AbstractWModels; kwargs...)
    variable_dcgrid_voltage_magnitude_sqr(pm; kwargs...)
end
"""
```
sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) == sum(pg[g] for g in bus_gens)  - pd - gs*w
sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac) == sum(qg[g] for g in bus_gens)  - qd + bs*w
```
"""
function constraint_kcl_shunt(pm::_PM.AbstractWModels, n::Int,  i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
    w = _PM.var(pm, n, :w, i)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)

    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*w)
    JuMP.@constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*w)
end
"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractWRModels, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr = _PM.var(pm, n, :p_dcgrid, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid, t_idx)
    wdc_fr = _PM.var(pm, n, :wdc, f_bus)
    wdc_to = _PM.var(pm, n, :wdc, t_bus)
    wdc_frto = _PM.var(pm, n, :wdcr, (f_bus, t_bus))

    if r == 0
        JuMP.@constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        JuMP.@constraint(pm.model, p_dc_fr == p * g *  (wdc_fr - wdc_frto))
        JuMP.@constraint(pm.model, p_dc_to == p * g *  (wdc_to - wdc_frto))
    end
end
"`wdc[i] == vdcm^2`"
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractWModels, n::Int,  i, vdcm)
    wdc = _PM.var(pm, n, :wdc, i)

    _PM.con(pm, n, :v_dc)[i] = JuMP.@constraint(pm.model, wdc == vdcm^2)
    JuMP.@constraint(pm.model, wdc == vdcm^2)
end

function add_dc_bus_voltage_setpoint(sol, pm::_PM.AbstractWModels)
    _PM.add_setpoint!(sol, pm, "busdc", "vm", :wdc, status_name="Vdc", inactive_status_value = 4; scale = (x,item,cnd) -> sqrt(x))
end

"""
Limits dc branch current

```
p[f_idx] <= wdc[f_bus] * Imax
```
"""
function constraint_dc_branch_current(pm::_PM.AbstractWModels, n::Int,  f_bus, f_idx, ccm_max, p)
    p_dc_fr = _PM.var(pm, n, :p_dcgrid, f_idx)
    wdc_fr = _PM.var(pm, n, :wdc, f_bus)

    JuMP.@constraint(pm.model, p_dc_fr <= wdc_fr * ccm_max * p^2)
end

####### TNEP constraints ###############

function variable_dcgrid_voltage_magnitude_ne(pm::_PM.AbstractWModels; kwargs...)
    variable_dcgrid_voltage_magnitude_sqr_ne(pm; kwargs...)
    variable_dcgrid_voltage_magnitude_sqr_du(pm; kwargs...) # duplicated to cancel out existing dc voltages(W) from ohms constraint when z = 0
end

"""
```
sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne) == sum(pg[g] for g in bus_gens)  - pd - gs*w
sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac) + sum(qconv_grid_ac_ne[c] for c in bus_convs_ac_ne) == sum(qg[g] for g in bus_gens)  - qd + bs*w
```
"""
function constraint_kcl_shunt_ne(pm::_PM.AbstractWModels, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, pd, qd, gs, bs)
    w = _PM.var(pm, n, :w, i)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)
    pconv_grid_ac_ne = _PM.var(pm, n, :pconv_tf_fr_ne)
    qconv_grid_ac_ne = _PM.var(pm, n, :qconv_tf_fr_ne)
    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  == sum(pg[g] for g in bus_gens)  - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*w)
    JuMP.@constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac) + sum(qconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  == sum(qg[g] for g in bus_gens)  - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*w)
end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch_ne(pm::_PM.AbstractWRModels, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    l = f_idx[1]
    p_dc_fr = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    z = _PM.var(pm, n, :branch_ne, l)
    wdc_to = []
    wdc_fr = []


    wdc_to, wdc_fr = contraint_ohms_dc_branch_busvoltage_structure_W(pm, n, f_bus, t_bus, wdc_to, wdc_fr)
    wdc_du_to = _PM.var(pm, n, :wdc_du_to, l)
    wdc_du_fr = _PM.var(pm, n, :wdc_du_fr, l)
    wdc_frto = _PM.var(pm, n, :wdcr_ne, l)
    wdc_du_frto = _PM.var(pm, n, :wdcr_du, l)

    if r == 0
        JuMP.@constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        JuMP.@constraint(pm.model, p_dc_fr == p * g *  (wdc_du_fr - wdc_du_frto))
        JuMP.@constraint(pm.model, p_dc_to == p * g *  (wdc_du_to - wdc_du_frto))
        JuMP.@constraint(pm.model, wdc_du_to <= wdc_to - JuMP.lower_bound(wdc_to)*(1-z))
        JuMP.@constraint(pm.model, wdc_du_to >= wdc_to - JuMP.upper_bound(wdc_to)*(1-z))
        JuMP.@constraint(pm.model, wdc_du_fr <= wdc_fr - JuMP.lower_bound(wdc_fr)*(1-z))
        JuMP.@constraint(pm.model, wdc_du_fr >= wdc_fr - JuMP.upper_bound(wdc_fr)*(1-z))
        JuMP.@constraint(pm.model, wdc_du_frto <= wdc_frto - JuMP.lower_bound(wdc_frto)*(1-z))
        JuMP.@constraint(pm.model, wdc_du_frto >= wdc_frto - JuMP.upper_bound(wdc_frto)*(1-z))

        JuMP.@constraint(pm.model, wdc_du_to <= z* JuMP.upper_bound(wdc_to))
        JuMP.@constraint(pm.model, wdc_du_to >= z* JuMP.lower_bound(wdc_to))
        JuMP.@constraint(pm.model, wdc_du_fr <= z* JuMP.upper_bound(wdc_fr))
        JuMP.@constraint(pm.model, wdc_du_fr >= z* JuMP.lower_bound(wdc_fr))
        JuMP.@constraint(pm.model, wdc_du_frto <= z* JuMP.upper_bound(wdc_frto))
        JuMP.@constraint(pm.model, wdc_du_frto >= z* JuMP.lower_bound(wdc_frto))
    end
end

function add_dc_bus_voltage_setpoint_ne(sol, pm::_PM.AbstractWModels)
    _PM.add_setpoint!(sol, pm, "busdc_ne", "vm", :wdc_ne, status_name="Vdc", inactive_status_value = 4; scale = (x,item,cnd) -> sqrt(x))
end
