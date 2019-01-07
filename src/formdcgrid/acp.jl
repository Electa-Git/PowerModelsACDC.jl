"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*v^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*v^2
```
"""
function constraint_kcl_shunt(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs) where {T <: PowerModels.AbstractACPForm}
    vm = PowerModels.var(pm, n, cnd, :vm, i)
    p = PowerModels.var(pm, n, cnd, :p)
    q = PowerModels.var(pm, n, cnd, :q)
    pg = PowerModels.var(pm, n, cnd, :pg)
    qg = PowerModels.var(pm, n, cnd, :qg)
    pconv_grid_ac = PowerModels.var(pm, n, cnd, :pconv_tf_fr)
    qconv_grid_ac = PowerModels.var(pm, n, cnd, :qconv_tf_fr)

    PowerModels.con(pm, n, cnd, :kcl_p)[i] = @NLconstraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)   - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*vm^2)
    PowerModels.con(pm, n, cnd, :kcl_q)[i] = @NLconstraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*vm^2)
end
"""
Creates Ohms constraints for DC branches

```
p[f_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])
```
"""
function constraint_ohms_dc_branch(pm::GenericPowerModel{T}, n::Int, cnd::Int, f_bus, t_bus, f_idx, t_idx, r, p) where {T <: PowerModels.AbstractACPForm}
    p_dc_fr = PowerModels.var(pm, n, cnd, :p_dcgrid, f_idx)
    p_dc_to = PowerModels.var(pm, n, cnd, :p_dcgrid, t_idx)
    vmdc_fr = PowerModels.var(pm, n, cnd, :vdcm, f_bus)
    vmdc_to = PowerModels.var(pm, n, cnd, :vdcm, t_bus)

    if r == 0
        @constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        @NLconstraint(pm.model, p_dc_fr == p * g * vmdc_fr * (vmdc_fr - vmdc_to))
        @NLconstraint(pm.model, p_dc_to == p * g * vmdc_to * (vmdc_to - vmdc_fr))
    end
end
"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::GenericPowerModel{T}, n::Int, cnd::Int, i, vdcm) where {T <: PowerModels.AbstractACPForm}
    v = PowerModels.var(pm, n, cnd, :vdcm, i)
    PowerModels.con(pm, n, cnd, :v_dc)[i] = @constraint(pm.model, v == vdcm)
end

function constraint_dc_branch_current(pm::GenericPowerModel{T}, n::Int, cnd::Int, f_bus, f_idx, ccm_max, p) where {T <: PowerModels.AbstractACPForm}
# do nothing
end
