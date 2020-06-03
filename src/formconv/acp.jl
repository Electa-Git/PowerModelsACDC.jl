"""
Creates lossy converter model between AC and DC grid
```
pconv_ac[i] + pconv_dc[i] == a + bI + cI^2
```
"""
function constraint_converter_losses(pm::_PM.AbstractACPModel, n::Int, i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    iconv = _PM.var(pm, n, :iconv_ac, i)

    JuMP.@NLconstraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv^2)
end
"""
Links converter power & current
```
pconv_ac[i]^2 + pconv_dc[i]^2 == vmc[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current(pm::_PM.AbstractACPModel, n::Int, i::Int, Umax, Imax)
    vmc = _PM.var(pm, n, :vmc, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)
    iconv = _PM.var(pm, n, :iconv_ac, i)

    JuMP.@NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == vmc^2 * iconv^2)
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
function constraint_conv_transformer(pm::_PM.AbstractACPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)

    vm = _PM.var(pm, n, :vm, acbus)
    va = _PM.var(pm, n, :va, acbus)
    vmf = _PM.var(pm, n, :vmf, i)
    vaf = _PM.var(pm, n, :vaf, i)

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        gtf_sh = 0
        c1, c2, c3, c4 = ac_power_flow_constraints(pm.model, gtf, btf, gtf_sh, vm, vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, vm == vmf)
    end
end
"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints(model, g, b, gsh_fr, vm_fr, vm_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm)
    c1 = JuMP.@NLconstraint(model, p_fr ==  g/(tm^2)*vm_fr^2 + -g/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -b/(tm)*vm_fr*vm_to*sin(va_fr-va_to))
    c2 = JuMP.@NLconstraint(model, q_fr == -b/(tm^2)*vm_fr^2 +  b/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -g/(tm)*vm_fr*vm_to*sin(va_fr-va_to))
    c3 = JuMP.@NLconstraint(model, p_to ==  g*vm_to^2 + -g/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b/(tm)*vm_to*vm_fr    *sin(va_to - va_fr))
    c4 = JuMP.@NLconstraint(model, q_to == -b*vm_to^2 +  b/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g/(tm)*vm_to*vm_fr    *sin(va_to - va_fr))
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
function constraint_conv_reactor(pm::_PM.AbstractACPModel, n::Int, i::Int, rc, xc, reactor)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)

    vmf = _PM.var(pm, n, :vmf, i)
    vaf = _PM.var(pm, n, :vaf, i)
    vmc = _PM.var(pm, n, :vmc, i)
    vac = _PM.var(pm, n, :vac, i)

    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        JuMP.@NLconstraint(pm.model, -pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf))
        JuMP.@NLconstraint(pm.model, -qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf))
        JuMP.@NLconstraint(pm.model, ppr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac))
        JuMP.@NLconstraint(pm.model, qpr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac))
    else
        ppr_to = -pconv_ac
        qpr_to = -qconv_ac
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, vmc == vmf)

    end
end
"""
Converter filter constraints
```
ppr_fr + ptf_to == 0
qpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0
```
"""
function constraint_conv_filter(pm::_PM.AbstractACPModel, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)

    vmf = _PM.var(pm, n, :vmf, i)

    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
    JuMP.@NLconstraint(pm.model, qpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0)
end
"""
LCC firing angle constraints
```
pconv_ac == cos(phi) * Srated
qconv_ac == sin(phi) * Srated
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractACPModel, n::Int, i::Int, S, P1, Q1, P2, Q2)
    p = _PM.var(pm, n, :pconv_ac, i)
    q = _PM.var(pm, n, :qconv_ac, i)
    phi = _PM.var(pm, n, :phiconv, i)

    JuMP.@NLconstraint(pm.model,   p == cos(phi) * S)
    JuMP.@NLconstraint(pm.model,   q == sin(phi) * S)
end

function constraint_dc_droop_control(pm::_PM.AbstractACPModel, n::Int, i::Int, busdc_i, vref_dc, pref_dc, k_droop)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    vdc = _PM.var(pm, n, :vdcm, busdc_i)

    JuMP.@constraint(pm.model, pconv_dc == pref_dc - sign(pref_dc) * 1 / k_droop * (vdc - vref_dc))
end


#################### TNEP Constraints #########################
"""
Creates lossy converter model between AC and DC grid

```
pconv_ac[i] + pconv_dc[i] == a + bI + cI^2
```
"""
function constraint_converter_losses_ne(pm::_PM.AbstractACPModel, n::Int, i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne, i)
    iconv = _PM.var(pm, n, :iconv_ac_ne, i)
    z = _PM.var(pm, n, :conv_ne, i)

    JuMP.@NLconstraint(pm.model, pconv_ac + pconv_dc == a*z + b*iconv + c*iconv^2)
end


"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 == vmc[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current_ne(pm::_PM.AbstractACPModel, n::Int, i::Int, Umax, Imax)
    vmc = _PM.var(pm, n, :vmc_ne, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne, i)
    iconv = _PM.var(pm, n, :iconv_ac_ne, i)

    JuMP.@NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == vmc^2 * iconv^2)
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
function constraint_conv_transformer_ne(pm::_PM.AbstractACPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)

    ptf_fr = _PM.var(pm, n, :pconv_tf_fr_ne, i)
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to_ne, i)

    vm = _PM.var(pm, n, :vm, acbus)
    va = _PM.var(pm, n, :va, acbus)
    vmf = _PM.var(pm, n, :vmf_ne, i)
    vaf = _PM.var(pm, n, :vaf_ne, i)
    z = _PM.var(pm, n, :conv_ne)[i]
    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        gtf_sh = 0
        c1, c2, c3, c4 = ac_power_flow_constraints(pm.model, gtf, btf, gtf_sh, vm, vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm, z)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, vm/(tm) == vmf)
    end
end

"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints(model, g, b, gsh_fr, vm_fr, vm_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm, z)
    c1 = JuMP.@NLconstraint(model, p_fr ==  z* (g/(tm^2)*vm_fr^2 + -g/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -b/(tm)*vm_fr*vm_to*sin(va_fr-va_to)))
    c2 = JuMP.@NLconstraint(model, q_fr == z* (-b/(tm^2)*vm_fr^2 +  b/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -g/(tm)*vm_fr*vm_to*sin(va_fr-va_to)))
    c3 = JuMP.@NLconstraint(model, p_to == z* (g*vm_to^2 + -g/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b/(tm)*vm_to*vm_fr    *sin(va_to - va_fr)))
    c4 = JuMP.@NLconstraint(model, q_to == z* (-b*vm_to^2 +  b/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g/(tm)*vm_to*vm_fr    *sin(va_to - va_fr)))
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
function constraint_conv_reactor_ne(pm::_PM.AbstractACPModel, n::Int, i::Int, rc, xc, reactor)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne, i)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr_ne, i)

    vmf = _PM.var(pm, n, :vmf_ne, i)
    vaf = _PM.var(pm, n, :vaf_ne, i)
    vmc = _PM.var(pm, n, :vmc_ne, i)
    vac = _PM.var(pm, n, :vac_ne, i)
    zc = rc + im*xc
    z = _PM.var(pm, n, :conv_ne)[i]

    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        JuMP.@NLconstraint(pm.model, -pconv_ac == z*(gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf)))
        JuMP.@NLconstraint(pm.model, -qconv_ac == z*(-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf)))
        JuMP.@NLconstraint(pm.model, ppr_fr ==  z*(gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac)))
        JuMP.@NLconstraint(pm.model, qpr_fr ==  z*(-bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac)))
    else
        ppr_to = -pconv_ac
        qpr_to = -qconv_ac
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, vmc == vmf)

    end
end

"""
Converter filter constraints

```
ppr_fr + ptf_to == 0
qpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0
```
"""
function constraint_conv_filter_ne(pm::_PM.AbstractACPModel, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to_ne, i)

    vmf = _PM.var(pm, n, :vmf_ne, i)
    z = _PM.var(pm, n, :conv_ne)[i]

    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
    JuMP.@NLconstraint(pm.model, qpr_fr + qtf_to +  z*(-bv) * filter *vmf^2 == 0)
end

"""
LCC firing angle constraints

```
pconv_ac == cos(phi) * Srated
qconv_ac == sin(phi) * Srated
```
"""
function constraint_conv_firing_angle_ne(pm::_PM.AbstractACPModel, n::Int, i::Int, S, P1, Q1, P2, Q2)
    p = _PM.var(pm, n, :pconv_ac_ne, i)
    q = _PM.var(pm, n, :qconv_ac_ne, i)
    phi = _PM.var(pm, n, :phiconv_ne, i)

    JuMP.@NLconstraint(pm.model,   p == cos(phi) * S)
    JuMP.@NLconstraint(pm.model,   q == sin(phi) * S)
end

function variable_voltage_slack(pm::_PM.AbstractACPModel; bounded::Bool = true)
end
