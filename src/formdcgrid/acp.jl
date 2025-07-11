"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*v^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*v^2
```
"""
function constraint_power_balance_ac(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_pst, bus_arcs_sssc, bus_convs_ac, bus_arcs_sw, bus_gens, bus_storage, bus_loads, bus_gs, bus_bs)
    vm   = _PM.var(pm, n, :vm, i)
    p    = _PM.var(pm, n, :p)
    q    = _PM.var(pm, n, :q)
    ppst    = _PM.var(pm, n,    :ppst)
    qpst    = _PM.var(pm, n,    :qpst)
    pg   = _PM.var(pm, n,   :pg)
    qg   = _PM.var(pm, n,   :qg)
    pconv_grid_ac = _PM.var(pm, n,  :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n,  :qconv_tf_fr)
    pflex = _PM.var(pm, n, :pflex)
    qflex = _PM.var(pm, n, :qflex)
    ps    = _PM.var(pm, n, :ps)
    qs    = _PM.var(pm, n, :qs)
    psssc    = _PM.var(pm, n,    :psssc)
    qsssc    = _PM.var(pm, n,    :qsssc)


    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(ppst[a] for a in bus_arcs_pst)
        + sum(psssc[a] for a in bus_arcs_sssc) 
        + sum(pconv_grid_ac[c] for c in bus_convs_ac)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pflex[d] for d in bus_loads)
        - sum(gs for (i,gs) in bus_gs)*vm^2
    )
    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(qpst[a] for a in bus_arcs_pst)
        + sum(qsssc[a] for a in bus_arcs_sssc) 
        + sum(qconv_grid_ac[c] for c in bus_convs_ac)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qflex[d] for d in bus_loads)
        + sum(bs for (i,bs) in bus_bs)*vm^2
    )

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end
"""
Creates Ohms constraints for DC branches

```
p[f_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])
```
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractACPModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr = _PM.var(pm, n,  :p_dcgrid, f_idx)
    p_dc_to = _PM.var(pm, n,  :p_dcgrid, t_idx)
    vmdc_fr = _PM.var(pm, n,  :vdcm, f_bus)
    vmdc_to = _PM.var(pm, n,  :vdcm, t_bus)

    if r == 0
        JuMP.@constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        JuMP.@constraint(pm.model, p_dc_fr == p * g * vmdc_fr * (vmdc_fr - vmdc_to))
        JuMP.@constraint(pm.model, p_dc_to == p * g * vmdc_to * (vmdc_to - vmdc_fr))
    end
end
"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractACPModel, n::Int,  i, vdcm)
    v = _PM.var(pm, n,  :vdcm, i)
    JuMP.@constraint(pm.model, v == vdcm)
end

function constraint_dc_branch_current(pm::_PM.AbstractACPModel, n::Int,  f_bus, f_idx, ccm_max, p)
# do nothing
end

############## TNEP constraints ###############
"""
```
sum(p[a] for a in bus_arcs) + sum(p_ne[a] for a in bus_arcs_ne) + sum(pconv_grid_ac[c] for c in bus_convs_ac) + sum(pconv_grid_ac_ne[c] for c in bus_convs_ac_ne) == sum(pg[g] for g in bus_gens)  - pd - gs*v^2
sum(q[a] for a in bus_arcs) + sum(q_ne[a] for a in bus_arcs_ne) + sum(qconv_grid_ac[c] for c in bus_convs_ac) + sum(qconv_grid_ac_ne[c] for c in bus_convs_ac_ne) == sum(qg[g] for g in bus_gens)  - qd + bs*v^2
```
"""
function constraint_power_balance_acdc_ne(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_arcs_pst, bus_arcs_sssc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_storage, bus_shunts, gs, bs)
    vm = _PM.var(pm, n, :vm, i)
    p = _PM.var(pm, n, :p)
    p_ne = _PM.var(pm,n, :p_ne)
    q = _PM.var(pm, n, :q)
    q_ne = _PM.var(pm,n, :q_ne)
    pg = _PM.var(pm, n, :pg)
    qg = _PM.var(pm, n, :qg)
    pconv_grid_ac = _PM.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = _PM.var(pm, n, :qconv_tf_fr)
    pconv_grid_ac_ne = _PM.var(pm, n, :pconv_tf_fr_ne)
    qconv_grid_ac_ne = _PM.var(pm, n, :qconv_tf_fr_ne)
    pflex = _PM.var(pm, n, :pflex)
    qflex = _PM.var(pm, n, :qflex)
    ps    = _PM.var(pm, n, :ps)
    qs    = _PM.var(pm, n, :qs)
    ppst    = _PM.var(pm, n,    :ppst)
    qpst    = _PM.var(pm, n,    :qpst)
    psssc    = _PM.var(pm, n,    :psssc)
    qsssc    = _PM.var(pm, n,    :qsssc)
    
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
    
    cstr_q = JuMP.@constraint(pm.model, 
    sum(q[a] for a in bus_arcs)
    + sum(qpst[a] for a in bus_arcs_pst)
    + sum(qsssc[a] for a in bus_arcs_sssc) 
    + sum(q_ne[a] for a in bus_arcs_ne) 
    + sum(qconv_grid_ac[c] for c in bus_convs_ac) 
    + sum(qconv_grid_ac_ne[c] for c in bus_convs_ac_ne)  
    == 
    sum(qg[g] for g in bus_gens)  
    - sum(qs[s] for s in bus_storage)
    - sum(qflex[d] for d in bus_loads)
    + sum(bs[s] for s in bus_shunts)*vm^2)
    
    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end
"""
Creates Ohms constraints for DC branches

```
p[f_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])
```
"""
function constraint_ohms_dc_branch_ne(pm::_PM.AbstractACPModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr = _PM.var(pm, n, :p_dcgrid_ne, f_idx)
    p_dc_to = _PM.var(pm, n, :p_dcgrid_ne, t_idx)
    vmdc_fr = []
    vmdc_to = []
    z = _PM.var(pm, n, :branchdc_ne, f_idx[1])
    vmdc_to, vmdc_fr = contraint_ohms_dc_branch_busvoltage_structure(pm, n, f_bus, t_bus, vmdc_to, vmdc_fr)
    if r == 0
        JuMP.@constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r

        JuMP.@constraint(pm.model, p_dc_fr == z * p * g * vmdc_fr * (vmdc_fr - vmdc_to))
        JuMP.@constraint(pm.model, p_dc_to == z * p * g * vmdc_to * (vmdc_to - vmdc_fr))
    end
end

# V or W as input, the function returns V or W with existing dc bus and dc_ne bus voltages
function contraint_ohms_dc_branch_busvoltage_structure(pm::_PM.AbstractACPModel, n::Int, f_bus, t_bus, vmdc_to, vmdc_fr)
    for i in _PM.ids(pm, n, :busdc_ne)
        if t_bus == i
            vmdc_to = _PM.var(pm, n, :vdcm_ne, t_bus)
        end
        if f_bus == i
            vmdc_fr = _PM.var(pm, n, :vdcm_ne, f_bus)
        end
    end
    for i in _PM.ids(pm, n, :busdc)
        if t_bus == i
            vmdc_to = _PM.var(pm, n, :vdcm, t_bus)
        end
        if f_bus == i
            vmdc_fr = _PM.var(pm, n, :vdcm, f_bus)
        end
    end
    return vmdc_to, vmdc_fr
end
