"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*v^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*v^2
```
"""
function constraint_kcl_shunt{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, pd, qd, gs, bs)
    vm = pm.var[:nw][n][:vm][i]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    p_dc = pm.var[:nw][n][:p_dc]
    q_dc = pm.var[:nw][n][:q_dc]
    pconv_ac = pm.var[:nw][n][:pconv_ac]
    qconv_ac = pm.var[:nw][n][:qconv_ac]

    pm.con[:nw][n][:kcl_p][i] = @NLconstraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) + sum(pconv_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - pd  - gs*vm^2)
    pm.con[:nw][n][:kcl_q][i] = @NLconstraint(pm.model, sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) + sum(qconv_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - qd + bs*vm^2)
end


"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])
```
"""
function constraint_ohms_dc_branch{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p)
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]
    vmdc_fr = pm.var[:nw][n][:vdcm][f_bus]
    vmdc_to = pm.var[:nw][n][:vdcm][t_bus]

    @NLconstraint(pm.model, p_dc_fr == p * g * vmdc_fr * (vmdc_fr - vmdc_to))
    @NLconstraint(pm.model, p_dc_to == p * g * vmdc_to * (vmdc_to - vmdc_fr))
end


"""
Creates lossy converter model between AC and DC grid

```
pconv_ac[i] + pconv_dc[i] == a + bI + cI^2
```
"""
function constraint_converter_losses{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, a, b, c)
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    pconv_dc = pm.var[:nw][n][:pconv_dc][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_loss][i] = @NLconstraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv^2)
end


"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 == 3 * vm[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_ac, Umax)
    vm = pm.var[:nw][n][:vm][bus_ac]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == 3 * vm^2 * iconv^2)
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i, vdcm)
    v = pm.var[:nw][n][:vdcm][i]
    pm.con[:nw][n][:v_dc][i] = @constraint(pm.model, v == vdcm)
end
