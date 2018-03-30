"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*v^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*v^2
```
"""
function constraint_kcl_shunt(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, pd, qd, gs, bs) where {T <: PowerModels.AbstractACPForm}
    vm = pm.var[:nw][n][:vm][i]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    pconv_grid_ac = pm.var[:nw][n][:pconv_tf_fr]
    qconv_grid_ac = pm.var[:nw][n][:qconv_tf_fr]

    pm.con[:nw][n][:kcl_p][i] = @NLconstraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - pd - gs*vm^2)
    pm.con[:nw][n][:kcl_q][i] = @NLconstraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - qd + bs*vm^2)
end


"""
Creates Ohms constraints for DC branches

```
p[f_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])
```
"""
function constraint_ohms_dc_branch(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p) where {T <: PowerModels.AbstractACPForm}
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
function constraint_converter_losses(pm::GenericPowerModel{T}, n::Int, i::Int, a, b, c) where {T <: PowerModels.AbstractACPForm}
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    pconv_dc = pm.var[:nw][n][:pconv_dc][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_loss][i] = @NLconstraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv^2)
end


"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 == vmc[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, Umax) where {T <: PowerModels.AbstractACPForm}
    vmc = pm.var[:nw][n][:vmc][i]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    #pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == 3 * vm^2 * iconv^2)
    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == vmc^2 * iconv^2)
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::GenericPowerModel{T}, n::Int, i, vdcm) where {T <: PowerModels.AbstractACPForm}
    v = pm.var[:nw][n][:vdcm][i]
    pm.con[:nw][n][:v_dc][i] = @constraint(pm.model, v == vdcm)
end


function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractACPForm}
    ptf_fr = pm.var[:nw][n][:pconv_tf_fr][i]
    qtf_fr = pm.var[:nw][n][:qconv_tf_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    qtf_to = pm.var[:nw][n][:qconv_tf_to][i]

    # ac bus voltage
    vm = pm.var[:nw][n][:vm][acbus]
    va = pm.var[:nw][n][:va][acbus]
    #filter voltage
    vmf = pm.var[:nw][n][:vmf][i]
    vaf = pm.var[:nw][n][:vaf][i]

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        gtf_sh = 0
        c1, c2, c3, c4 = ac_power_flow_constraints(pm.model, gtf, btf, gtf_sh, vm, vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
        pm.con[:nw][n][:conv_tf_p_fr][i] = c1
        pm.con[:nw][n][:conv_tf_q_fr][i] = c2

        pm.con[:nw][n][:conv_tf_p_to][i] = c3
        pm.con[:nw][n][:conv_tf_q_to][i] = c4
    else
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, ptf_fr + ptf_to == 0)
        pm.con[:nw][n][:conv_tf_q_fr][i] = @constraint(pm.model, qtf_fr + qtf_to == 0)
        @constraint(pm.model, va == vaf)
        @constraint(pm.model, vm/(tm) == vmf)
    end
end

"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints(model, g, b, gsh_fr, vm_fr, vm_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm)
    c1 = @NLconstraint(model, p_fr ==  g/(tm^2)*vm_fr^2 + -g/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -b/(tm)*vm_fr*vm_to*sin(va_fr-va_to))
    c2 = @NLconstraint(model, q_fr == -b/(tm^2)*vm_fr^2 +  b/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -g/(tm)*vm_fr*vm_to*sin(va_fr-va_to))
    c3 = @NLconstraint(model, p_to ==  g*vm_to^2 + -g/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b/(tm)*vm_to*vm_fr    *sin(va_to - va_fr))
    c4 = @NLconstraint(model, q_to == -b*vm_to^2 +  b/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g/(tm)*vm_to*vm_fr    *sin(va_to - va_fr))
    return c1, c2, c3, c4
end


function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractACPForm}
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_fr][i]
    #filter voltage
    vmf = pm.var[:nw][n][:vmf][i]
    vaf = pm.var[:nw][n][:vaf][i]
    #converter voltage
    vmc = pm.var[:nw][n][:vmc][i]
    vac = pm.var[:nw][n][:vac][i]

    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        pm.con[:nw][n][:conv_pr_p][i] = @NLconstraint(pm.model, -pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf))
        pm.con[:nw][n][:conv_pr_q][i] = @NLconstraint(pm.model, -qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf))
        @NLconstraint(pm.model, ppr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac))
        @NLconstraint(pm.model, qpr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac))
    else
        ppr_to = -pconv_ac
        qpr_to = -qconv_ac
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, ppr_fr + ppr_to == 0)
        pm.con[:nw][n][:conv_pr_q][i] = @constraint(pm.model, qpr_fr + qpr_to == 0)
        @constraint(pm.model, vac == vaf)
        @constraint(pm.model, vmc == vmf)

    end
end

function constraint_conv_filter(pm::GenericPowerModel{T}, n::Int, i::Int, bv, filter) where {T <: PowerModels.AbstractACPForm}
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    qtf_to = pm.var[:nw][n][:qconv_tf_to][i]

    # filter voltage
    vmf = pm.var[:nw][n][:vmf][i]
    vaf = pm.var[:nw][n][:vaf][i]

    pm.con[:nw][n][:conv_kcl_p][i] = @constraint(pm.model,   ppr_fr + ptf_to == 0 )
    pm.con[:nw][n][:conv_kcl_q][i] = @NLconstraint(pm.model, qpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0)
end


"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 == vmc[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, Umax) where {T <: PowerModels.AbstractACPForm}
    vmc = pm.var[:nw][n][:vmc][i]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == vmc^2 * iconv^2)
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::GenericPowerModel{T}, n::Int, i, vdcm) where {T <: PowerModels.AbstractACPForm}
    v = pm.var[:nw][n][:vdcm][i]
    pm.con[:nw][n][:v_dc][i] = @constraint(pm.model, v == vdcm)
end
