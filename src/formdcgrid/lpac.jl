"""
Shunt constraint using linearized voltage magnitude difference phi

```
sum(p) + sum(pconv_grid_ac)  == sum(pg) - sum(pd) - sum(gs*(1.0 + 2*phi)
```
"""
function constraint_kcl_shunt(pm::_PM.AbstractLPACModel, n::Int,  i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
    phi = _PM.var(pm, n, :phi, i)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)


    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)   - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*(1.0 + 2*phi))
    JuMP.@constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)   - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*(1.0 + 2*phi))
end
"""
DC branch power flow using linearized voltage magnitude difference phi

```
p_dc_fr == p * g *  (phi_fr - phi_to)
p_dc_to == p * g *  (phi_to - phi_fr)
```
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractLPACModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr = _PM.var(pm, n, :p_dcgrid, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid, t_idx)
    phi_fr = _PM.var(pm, n, :phi_vdcm, f_bus)
    phi_to = _PM.var(pm, n, :phi_vdcm, t_bus)
    phi_fr_ub = JuMP.UpperBoundRef(phi_to)
    phi_fr_lb = JuMP.LowerBoundRef(phi_to)

    if r == 0
        JuMP.@constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        JuMP.@constraint(pm.model, p_dc_fr == p * g *  (phi_fr - phi_to))
        JuMP.@constraint(pm.model, p_dc_to == p * g *  (phi_to - phi_fr))
    end
end

function constraint_dc_branch_current(pm::_PM.AbstractLPACModel, n::Int,  f_bus, f_idx, ccm_max, p)

end

function add_dc_bus_voltage_setpoint(sol, pm::_PM.AbstractLPACModel)
    _PM.add_setpoint!(sol, pm, "busdc", "vm", :phi_vdcm, status_name="Vdc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
end


############# TNEP Constraints #################

function constraint_kcl_shunt_ne(pm::_PM.AbstractLPACModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_shunts, pd, qd, gs, bs)
    phi = _PM.var(pm, n, :phi, i)
    p = _PM.var(pm, n, :p)
    q = _PM.var(pm, n, :q)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)
    pconv_grid_ac_ne = _PM.var(pm, n, :pconv_tf_fr_ne)
    qconv_grid_ac_ne = _PM.var(pm, n, :qconv_tf_fr_ne)

    JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  == sum(pg[g] for g in bus_gens)  - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*(1.0 + 2*phi))
    JuMP.@constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac) + sum(qconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  == sum(qg[g] for g in bus_gens)  - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*(1.0 + 2*phi))
end

function constraint_ohms_dc_branch_ne(pm::_PM.AbstractLPACModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    l = f_idx[1];
    p_dc_fr = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    phi_fr = []
    phi_to = []
    phi_fr_du = _PM.var(pm, n, :phi_vdcm_fr, l)
    phi_to_du = _PM.var(pm, n, :phi_vdcm_to, l)
    z = _PM.var(pm, n, :branch_ne, l)
    phi_to, phi_fr = contraint_ohms_dc_branch_busvoltage_structure_phi(pm, n, f_bus, t_bus, phi_to, phi_fr)
    if r == 0
        JuMP.@constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        JuMP.@constraint(pm.model, p_dc_fr == p * g *  (phi_fr_du - phi_to_du))
        JuMP.@constraint(pm.model, p_dc_to == p * g *  (phi_to_du - phi_fr_du))

        JuMP.@constraint(pm.model, phi_to_du <= phi_to - JuMP.lower_bound(phi_to)*(1-z))
        JuMP.@constraint(pm.model, phi_to_du >= phi_to - JuMP.upper_bound(phi_to)*(1-z))
        JuMP.@constraint(pm.model, phi_fr_du <= phi_fr - JuMP.lower_bound(phi_fr)*(1-z))
        JuMP.@constraint(pm.model, phi_fr_du >= phi_fr - JuMP.upper_bound(phi_fr)*(1-z))

        relaxation_variable_on_off(pm.model, phi_to, phi_to_du, z)
        relaxation_variable_on_off(pm.model, phi_fr, phi_fr_du, z)

    end
end

function constraint_dc_branch_current_ne(pm::_PM.AbstractLPACModel, n::Int, f_bus, f_idx, ccm_max, p)

end

function add_dc_bus_voltage_setpoint_ne(sol, pm::_PM.AbstractLPACModel)
    _PM.add_setpoint!(sol, pm, "busdc_ne", "vm", :phi_vdcm_ne, status_name="Vdc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
end

function contraint_ohms_dc_branch_busvoltage_structure_phi(pm::_PM.AbstractPowerModel, n::Int, f_bus, t_bus, phi_to, phi_fr)
    for i in _PM.ids(pm, n, :busdc_ne)
        if t_bus == i
            phi_to = _PM.var(pm, n, :phi_vdcm_ne, t_bus)
        end
        if f_bus == i
            phi_fr = _PM.var(pm, n, :phi_vdcm_ne, f_bus)
        end
    end
    for i in _PM.ids(pm, n, :busdc)
        if t_bus == i
            phi_to = _PM.var(pm, n, :phi_vdcm, t_bus)
        end
        if f_bus == i
            phi_fr = _PM.var(pm, n, :phi_vdcm, f_bus)
        end
    end
    return phi_to, phi_fr
end
