function constraint_kcl_shunt(pm::AbstractLPACModel, n::Int, cnd::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
    # vm = PowerModels.var(pm, n, cnd, :vm, i)
    phi = PowerModels.var(pm, n, cnd, :phi, i)
    p = PowerModels.var(pm, n, cnd, :p)
    q = PowerModels.var(pm, n, cnd, :q)
    pg = PowerModels.var(pm, n, cnd, :pg)
    qg = PowerModels.var(pm, n, cnd, :qg)
    pconv_grid_ac = PowerModels.var(pm, n, cnd, :pconv_tf_fr)
    qconv_grid_ac = PowerModels.var(pm, n, cnd, :qconv_tf_fr)


    PowerModels.con(pm, n, cnd, :kcl_p)[i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)   - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*(1.0 + 2*phi))
    PowerModels.con(pm, n, cnd, :kcl_q)[i] = @constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)   - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*(1.0 + 2*phi))
end

function constraint_ohms_dc_branch(pm::AbstractLPACModel, n::Int, cnd::Int, f_bus, t_bus, f_idx, t_idx, r, p)
    p_dc_fr = PowerModels.var(pm, n, cnd, :p_dcgrid, f_idx)
    p_dc_to = PowerModels.var(pm, n, cnd, :p_dcgrid, t_idx)
    phi_fr = PowerModels.var(pm, n, cnd, :phi_vdcm, f_bus)
    phi_to = PowerModels.var(pm, n, cnd, :phi_vdcm, t_bus)
    phi_fr_ub = JuMP.UpperBoundRef(phi_to)
    phi_fr_lb = JuMP.LowerBoundRef(phi_to)

    if r == 0
        @constraint(pm.model, p_dc_fr + p_dc_to == 0)
    else
        g = 1 / r
        # @NLconstraint(pm.model, p_dc_fr == p * g *  (phi_fr - phi_to - phi_fr^2 - phi_fr*phi_to))
        # @NLconstraint(pm.model, p_dc_to == p * g *  (phi_to - phi_fr - phi_to^2 - phi_to*phi_fr))

        @constraint(pm.model, p_dc_fr == p * g *  (phi_fr - phi_to))
        @constraint(pm.model, p_dc_to == p * g *  (phi_to - phi_fr))
    end
end

function constraint_dc_branch_current(pm::AbstractLPACModel, n::Int, cnd::Int, f_bus, f_idx, ccm_max, p)

end

function add_dc_bus_voltage_setpoint(sol, pm::AbstractLPACModel)
    PowerModels.add_setpoint!(sol, pm, "busdc", "vm", :phi_vdcm, status_name="Vdc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
end
