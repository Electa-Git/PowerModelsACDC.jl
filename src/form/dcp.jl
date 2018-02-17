"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*1^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*1^2
```
"""
function constraint_kcl_shunt{T <: PowerModels.AbstractDCPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, pd, qd, gs, bs)
    p = pm.var[:nw][n][:p]
    pg = pm.var[:nw][n][:pg]
    p_dc = pm.var[:nw][n][:p_dc]
    pconv_ac = pm.var[:nw][n][:pconv_ac]

    pm.con[:nw][n][:kcl_p][i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) + sum(pconv_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - pd  - gs*1^2)
end


"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == 0)
```
"""
function constraint_ohms_dc_branch{T <: PowerModels.AbstractDCPForm}(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p)
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]

    @constraint(pm.model, p_dc_fr + p_dc_to == 0)
end


"""
Creates lossy converter model between AC and DC grid

```
pconv_ac[i] + pconv_dc[i] == a 
```
"""
function constraint_converter_losses{T <: PowerModels.AbstractDCPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, a, b, c)
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    pconv_dc = pm.var[:nw][n][:pconv_dc][i]

    warn(a<0, ": dc line losses are negative")
    pm.con[:nw][n][:conv_loss][i] = @constraint(pm.model, pconv_ac + pconv_dc == a )
end


""
function constraint_converter_current{T <: PowerModels.AbstractDCPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_ac, Umax)
    # not used
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint{T <: PowerModels.AbstractDCPForm}(pm::GenericPowerModel{T}, n::Int, i, vdcm)
    # not used
end

function variable_dcgrid_voltage_magnitude{T <: PowerModels.AbstractDCPForm}(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true)
    # not used
end

function variable_dc_converter{T <: PowerModels.AbstractDCPForm}(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...)
    variable_acside_active_power(pm, n; kwargs...)
    variable_dcside_power(pm, n; kwargs...)
end
