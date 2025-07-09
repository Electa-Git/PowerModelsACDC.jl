"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*(vr^2 + vi^2)
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*(vr^2 + vi^2)
```
"""
function constraint_power_balance_ac(pm::_PM.AbstractACRModel, n::Int, i::Int, bus_arcs, bus_arcs_pst, bus_arcs_sssc, bus_convs_ac, bus_arcs_sw, bus_gens, bus_storage, bus_loads, bus_gs, bus_bs)
    vr = _PM.var(pm, n, :vr, i)
    vi = _PM.var(pm, n, :vi, i)
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
        + sum(psssc[sc] for sc in bus_arcs_sssc) 
        + sum(pconv_grid_ac[c] for c in bus_convs_ac)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pflex[d] for d in bus_loads)
        - sum(gs for (i,gs) in bus_gs)*(vr^2 + vi^2)^2
    )
    cstr_q = JuMP.@constraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(qpst[a] for a in bus_arcs_pst)
        + sum(qsssc[sc] for sc in bus_arcs_sssc) 
        + sum(qconv_grid_ac[c] for c in bus_convs_ac)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qflex[d] for d in bus_loads)
        + sum(bs for (i,bs) in bus_bs)*(vr^2 + vi^2)^2
    )

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end
# function constraint_power_balance_ac(pm::_PM.AbstractACRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
#     vr = _PM.var(pm, n, :vr, i)
#     vi = _PM.var(pm, n, :vi, i)
#     p    = _PM.var(pm, n, :p)
#     q    = _PM.var(pm, n, :q) 
#     pg   = _PM.var(pm, n, :pg) 
#     qg   = _PM.var(pm, n, :qg) 
#     pconv_grid_ac = _PM.var(pm, n,  :pconv_tf_fr)
#     qconv_grid_ac = _PM.var(pm, n,  :qconv_tf_fr)

#     cstr_p = JuMP.@constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*(vr^2 + vi^2))
#     cstr_q = JuMP.@constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac) == sum(qg[g] for g in bus_gens) - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*(vr^2 + vi^2))

#     if _IM.report_duals(pm)
#         _PM.sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
#         _PM.sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
#     end
# end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])
```
"""

function constraint_ohms_dc_branch(pm::_PM.AbstractACRModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
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
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractACRModel, n::Int,  i, vdcm)
    v = _PM.var(pm, n,  :vdcm, i)
    JuMP.@constraint(pm.model, v == vdcm)
end

function constraint_dc_branch_current(pm::_PM.AbstractACRModel, n::Int,  f_bus, f_idx, ccm_max, p)
# do nothing
end

############## TNEP constraints ###############