"""
Creates lossy converter model between AC and DC grid
```
pconv_ac[i] + pconv_dc[i] == a + bI + cI^2
```
"""
function constraint_converter_losses(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, a, b, c, plmax) where {T <: PowerModels.AbstractACPForm}
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    pconv_dc = PowerModels.var(pm, n, cnd, :pconv_dc, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)

    PowerModels.con(pm, n, cnd, :conv_loss)[i] = @NLconstraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv^2)
end
"""
Links converter power & current
```
pconv_ac[i]^2 + pconv_dc[i]^2 == vmc[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, Umax, Imax) where {T <: PowerModels.AbstractACPForm}
    vmc = PowerModels.var(pm, n, cnd, :vmc, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)

    PowerModels.con(pm, n, cnd, :conv_i)[i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == vmc^2 * iconv^2)
end
"""
Converter transformer constraints
```
p_tf_fr ==  g/(tm^2)*vm_fr^2 + -g/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -b/(tm)*vm_fr*vm_to*sin(va_fr-va_to)
q_tf_fr == -b/(tm^2)*vm_fr^2 +  b/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -g/(tm)*vm_fr*vm_to*sin(va_fr-va_to)
p_tf_to ==  g*vm_to^2 + -g/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b/(tm)*vm_to*vm_fr    *sin(va_to - va_fr)
q_tf_to == -b*vm_to^2 +  b/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g/(tm)*vm_to*vm_fr    *sin(va_to - va_fr)
```
"""
function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractACPForm}
    ptf_fr = PowerModels.var(pm, n, cnd, :pconv_tf_fr, i)
    qtf_fr = PowerModels.var(pm, n, cnd, :qconv_tf_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)
    qtf_to = PowerModels.var(pm, n, cnd, :qconv_tf_to, i)

    vm = PowerModels.var(pm, n, cnd, :vm, acbus)
    va = PowerModels.var(pm, n, cnd, :va, acbus)
    vmf = PowerModels.var(pm, n, cnd, :vmf, i)
    vaf = PowerModels.var(pm, n, cnd, :vaf, i)

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        gtf_sh = 0
        c1, c2, c3, c4 = ac_power_flow_constraints(pm.model, gtf, btf, gtf_sh, vm, vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)

        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = c1
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = c2

        PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = c3
        PowerModels.con(pm, n, cnd, :conv_tf_q_to)[i] = c4
    else
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = @constraint(pm.model, ptf_fr + ptf_to == 0)
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = @constraint(pm.model, qtf_fr + qtf_to == 0)
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
"""
Converter reactor constraints
```
-pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf)
-qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf)
p_pr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac)
q_pr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac)
```
"""
function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractACPForm}
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    qpr_fr = PowerModels.var(pm, n, cnd, :qconv_pr_fr, i)

    vmf = PowerModels.var(pm, n, cnd, :vmf, i)
    vaf = PowerModels.var(pm, n, cnd, :vaf, i)
    vmc = PowerModels.var(pm, n, cnd, :vmc, i)
    vac = PowerModels.var(pm, n, cnd, :vac, i)

    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = @NLconstraint(pm.model, -pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf))
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = @NLconstraint(pm.model, -qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf))
        @NLconstraint(pm.model, ppr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac))
        @NLconstraint(pm.model, qpr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac))
    else
        ppr_to = -pconv_ac
        qpr_to = -qconv_ac
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = @constraint(pm.model, ppr_fr + ppr_to == 0)
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = @constraint(pm.model, qpr_fr + qpr_to == 0)
        @constraint(pm.model, vac == vaf)
        @constraint(pm.model, vmc == vmf)

    end
end
"""
Converter filter constraints
```
ppr_fr + ptf_to == 0
qpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0
```
"""
function constraint_conv_filter(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, bv, filter) where {T <: PowerModels.AbstractACPForm}
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    qpr_fr = PowerModels.var(pm, n, cnd, :qconv_pr_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)
    qtf_to = PowerModels.var(pm, n, cnd, :qconv_tf_to, i)

    vmf = PowerModels.var(pm, n, cnd, :vmf, i)

    PowerModels.con(pm, n, cnd, :conv_kcl_p)[i] = @constraint(pm.model,   ppr_fr + ptf_to == 0 )
    PowerModels.con(pm, n, cnd, :conv_kcl_q)[i] = @NLconstraint(pm.model, qpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0)
end
"""
LCC firing angle constraints
```
pconv_ac == cos(phi) * Srated
qconv_ac == sin(phi) * Srated
```
"""
function constraint_conv_firing_angle(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, S, P1, Q1, P2, Q2) where {T <: PowerModels.AbstractACPForm}
    p = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    q = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    phi = PowerModels.var(pm, n, cnd, :phiconv, i)

    PowerModels.con(pm, n, cnd, :conv_cosphi)[i] = @NLconstraint(pm.model,   p == cos(phi) * S)
    PowerModels.con(pm, n, cnd, :conv_sinphi)[i] = @NLconstraint(pm.model,   q == sin(phi) * S)
end

function constraint_dc_droop_control(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, busdc_i, vref_dc, pref_dc, k_droop) where {T <: PowerModels.AbstractACPForm}
    pconv_dc = PowerModels.var(pm, n, cnd, :pconv_dc, i)
    vdc = PowerModels.var(pm, n, cnd, :vdcm, busdc_i)

    PowerModels.con(pm, n, cnd, :conv_dc_droop)[i] = @constraint(pm.model, pconv_dc == pref_dc - sign(pref_dc) * 1 / k_droop * (vdc - vref_dc))
end
