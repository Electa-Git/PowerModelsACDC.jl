"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*1^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*1^2
```
"""
function constraint_power_balance_ac(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_pst, bus_arcs_sssc, bus_convs_ac, bus_arcs_sw, bus_gens, bus_storage, bus_loads, bus_gs, bus_bs)
    p    = _PM.var(pm, n, :p)
    ppst    = _PM.var(pm, n,    :ppst)
    pg   = _PM.var(pm, n,   :pg)
    pconv_grid_ac = _PM.var(pm, n,  :pconv_tf_fr)
    pflex = _PM.var(pm, n, :pflex)
    ps    = _PM.var(pm, n, :ps)
    psssc    = _PM.var(pm, n,    :psssc)

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(ppst[a] for a in bus_arcs_pst)
        + sum(psssc[a] for a in bus_arcs_sssc)
        + sum(pconv_grid_ac[c] for c in bus_convs_ac)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pflex[d] for d in bus_loads)
        - sum(gs for (i,gs) in bus_gs)*1^2
    )

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end
end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == 0)
```
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractDCPModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr = _PM.var(pm, n, :p_dcgrid, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid, t_idx)

    JuMP.@constraint(pm.model, p_dc_fr + p_dc_to == 0)
end
"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractDCPModel, n::Int,  i, vdcm)
    # not used
end

function variable_dcgrid_voltage_magnitude(pm::_PM.AbstractDCPModel; kwrags...)
    # not used nw::Int=_PM.nw_id_default
end

function constraint_dc_branch_current(pm::_PM.AbstractDCPModel, n::Int,  f_bus, f_idx, ccm_max, p)
# do nothing
end


#################### TNEP constraints #################
"""
```
sum(p[a] for a in bus_arcs) sum(p_ne[a] for a in bus_arcs_ne) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*1^2
```
"""
function constraint_power_balance_acdc_ne(pm::_PM.AbstractDCPModel, n::Int, i::Int, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_arcs_pst, bus_arcs_sssc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_storage, bus_shunts, gs, bs)
    vm = 1
    p = _PM.var(pm, n, :p)
    p_ne = _PM.var(pm,n, :p_ne)
    pg = _PM.var(pm, n, :pg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    pconv_grid_ac_ne = _PM.var(pm, n, :pconv_tf_fr_ne)
    pflex = _PM.var(pm, n, :pflex)
    ps    = _PM.var(pm, n, :ps)
    ppst    = _PM.var(pm, n, :ppst)
    psssc    = _PM.var(pm, n,    :psssc)
    
    cstr_p = JuMP.@constraint(pm.model, 
    sum(p[a] for a in bus_arcs)
    + sum(ppst[a] for a in bus_arcs_pst) 
    + sum(psssc[a] for a in bus_arcs_sssc)
    + sum(p_ne[a] for a in bus_arcs_ne) 
    + sum(pconv_grid_ac[c] for c in bus_convs_ac) 
    + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  
    == 
    sum(pg[g] for g in bus_gens)  
    - sum(ps[s] for s in bus_storage)
    - sum(pflex[d] for d in bus_loads)
    - sum(gs[s] for s in bus_shunts)*vm^2)
    
    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end
end

"""
Creates Ohms constraints for candidate DC branches

```
p[f_idx] + p[t_idx] == 0)
```
"""
function constraint_ohms_dc_branch_ne(pm::_PM.AbstractDCPModel, n::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr_ne = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to_ne = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    JuMP.@constraint(pm.model, p_dc_fr_ne + p_dc_to_ne == 0)
end

function variable_dcgrid_voltage_magnitude_ne(pm::_PM.AbstractDCPModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    # not used
end


function add_dc_bus_voltage_setpoint_ne(sol, pm::_PM.AbstractDCPModel)
    _PM.add_setpoint!(sol, pm, "busdc_ne", "vm", :vdcm_ne, status_name="Vdc", inactive_status_value = 4)
    for (i, bus) in sol["busdc_ne"]
        sol["busdc_ne"]["$i"]["vm"] = 1.0
    end
end
