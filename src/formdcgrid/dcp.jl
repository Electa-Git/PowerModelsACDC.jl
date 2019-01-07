"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*1^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*1^2
```
"""
function constraint_kcl_shunt(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs) where {T <: PowerModels.AbstractDCPForm}
    p = PowerModels.var(pm, n, cnd, :p)
    pg = PowerModels.var(pm, n, cnd, :pg)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac)
    pconv_grid_ac = PowerModels.var(pm, n, cnd, :pconv_tf_fr)
    v = 1

    PowerModels.con(pm, n, cnd, :kcl_p)[i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*v^2)
end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == 0)
```
"""
function constraint_ohms_dc_branch(pm::GenericPowerModel{T}, n::Int, cnd::Int, f_bus, t_bus, f_idx, t_idx, r, p) where {T <: PowerModels.AbstractDCPForm}
    p_dc_fr = PowerModels.var(pm, n, cnd, :p_dcgrid, f_idx)
    p_dc_to = PowerModels.var(pm, n, cnd, :p_dcgrid, t_idx)

    @constraint(pm.model, p_dc_fr + p_dc_to == 0)
end
"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::GenericPowerModel{T}, n::Int, cnd::Int, i, vdcm) where {T <: PowerModels.AbstractDCPForm}
    # not used
end

function variable_dcgrid_voltage_magnitude(pm::GenericPowerModel{T}; kwrags...) where {T <: PowerModels.AbstractDCPForm}
    # not used nw::Int=pm.cnw
end

function constraint_dc_branch_current(pm::GenericPowerModel{T}, n::Int, cnd::Int, f_bus, f_idx, ccm_max, p) where {T <: PowerModels.AbstractDCPForm}
# do nothing
end
