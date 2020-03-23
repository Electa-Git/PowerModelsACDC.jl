"""
Shunt constraint using linearized voltage magnitude difference phi

```
sum(p) + sum(pconv_grid_ac)  == sum(pg) - sum(pd) - sum(gs*(1.0 + 2*phi)
```
"""
function constraint_kcl_shunt(pm::AbstractLPACModel, n::Int,  i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
    phi = PowerModels.var(pm, n, :phi, i)
    p = PowerModels.var(pm, n, :p)
    q = PowerModels.var(pm, n, :q)
    pg = PowerModels.var(pm, n, :pg)
    qg = PowerModels.var(pm, n, :qg)
    pconv_grid_ac = PowerModels.var(pm, n, :pconv_tf_fr)
    qconv_grid_ac = PowerModels.var(pm, n, :qconv_tf_fr)


    PowerModels.con(pm, n, :kcl_p)[i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)   - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*(1.0 + 2*phi))
    PowerModels.con(pm, n, :kcl_q)[i] = @constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)   - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*(1.0 + 2*phi))
end
"""
DC branch power flow using linearized voltage magnitude difference phi

```
p_dc_fr == p * g *  (phi_fr - phi_to)
p_dc_to == p * g *  (phi_to - phi_fr)
```
"""
function constraint_ohms_dc_branch(pm::AbstractLPACModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr = PowerModels.var(pm, n, :p_dcgrid, f_idx)
    p_dc_to = PowerModels.var(pm, n, :p_dcgrid, t_idx)
    phi_fr = PowerModels.var(pm, n, :phi_vdcm, f_bus)
    phi_to = PowerModels.var(pm, n, :phi_vdcm, t_bus)
    phi_fr_ub = JuMP.UpperBoundRef(phi_to)
    phi_fr_lb = JuMP.LowerBoundRef(phi_to)

    if r == 0
        @constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        @constraint(pm.model, p_dc_fr == p * g *  (phi_fr - phi_to))
        @constraint(pm.model, p_dc_to == p * g *  (phi_to - phi_fr))
    end
end

function constraint_dc_branch_current(pm::AbstractLPACModel, n::Int,  f_bus, f_idx, ccm_max, p)

end

function add_dc_bus_voltage_setpoint(sol, pm::AbstractLPACModel)
    PowerModels.add_setpoint!(sol, pm, "busdc", "vm", :phi_vdcm, status_name="Vdc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
end
