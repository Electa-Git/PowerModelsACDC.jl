function variable_converter_filter_voltage(pm::_PM.AbstractWModels; kwargs...)
    variable_converter_filter_voltage_magnitude_sqr(pm; kwargs...)
    variable_converter_filter_voltage_cross_products(pm; kwargs...)
end

function variable_converter_internal_voltage(pm::_PM.AbstractWModels; kwargs...)
    variable_converter_internal_voltage_magnitude_sqr(pm; kwargs...)
    variable_converter_internal_voltage_cross_products(pm; kwargs...)
end
"""
Creates lossy converter model between AC and DC side
```
pconv_ac[i] + pconv_dc[i] == a + b*I + c*Isq
```
"""
function constraint_converter_losses(pm::_PM.AbstractWModels, n::Int, i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n,  :pconv_ac, i)
    pconv_dc = _PM.var(pm, n,  :pconv_dc, i)
    iconv = _PM.var(pm, n,  :iconv_ac, i)
    iconv_sq = _PM.var(pm, n,  :iconv_ac_sq, i)

    JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv_sq)
end
"""
Converter transformer constraints
```
p_tf_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)
q_tf_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)
p_tf_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))
q_tf_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))
```
"""
function constraint_conv_transformer(pm::_PM.AbstractWRModels, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = _PM.var(pm, n,  :pconv_tf_fr, i)
    qtf_fr = _PM.var(pm, n,  :qconv_tf_fr, i)
    ptf_to = _PM.var(pm, n,  :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n,  :qconv_tf_to, i)

    w = _PM.var(pm, n,  :w, acbus)  # vm^2
    wf = _PM.var(pm, n,  :wf_ac, i)   # vmf * vmf
    wrf = _PM.var(pm, n,  :wrf_ac, i) # vm*vmf*cos(va-vaf) =  vmf*vm*cos(vaf-va)
    wif = _PM.var(pm, n,  :wif_ac, i) # vm*vmf*sin(va-vaf) = -vmf*vm*sin(vaf-va)

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm, gtf, btf, w, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
        constraint_voltage_product_converter(pm, wrf, wif, wf, w)
    else
        pcon, qcon = constraint_lossless_section(pm, w, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to)
    end
end
"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints_w(pm::_PM.AbstractWRModels, g, b, w_fr, w_to, wr, wi, p_fr, p_to, q_fr, q_to, tm)
    c1 = JuMP.@constraint(pm.model, p_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)
    c2 = JuMP.@constraint(pm.model, q_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)
    c3 = JuMP.@constraint(pm.model, p_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))
    c4 = JuMP.@constraint(pm.model, q_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))
    return c1, c2, c3, c4
end
"""
Converter reactor constraints
```
p_pr_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)
q_pr_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)
p_pr_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))
q_pr_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))
```
"""
function constraint_conv_reactor(pm::_PM.AbstractWRModels, n::Int, i::Int, rc, xc, reactor)
    ppr_fr = _PM.var(pm, n,  :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n,  :qconv_pr_fr, i)
    ppr_to = -_PM.var(pm, n,  :pconv_ac, i)
    qpr_to = -_PM.var(pm, n,  :qconv_ac, i)

    wf = _PM.var(pm, n,  :wf_ac, i)
    wc = _PM.var(pm, n,  :wc_ac, i)
    wrc = _PM.var(pm, n,  :wrc_ac, i)
    wic = _PM.var(pm, n,  :wic_ac, i)

    zc  = rc  + im*xc

    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        constraint_voltage_product_converter(pm, wrc, wic, wf, wc)
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm, gc, bc, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to, 1)
    else
        pcon, qcon = constraint_lossless_section(pm, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to)
    end
end
"""
Converter filter constraints

```
p_pr_fr + p_tf_to == 0
q_pr_fr + q_tf_to + -bv*filter*wf == 0
```
"""
function constraint_conv_filter(pm::_PM.AbstractWModels, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n,  :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n,  :qconv_pr_fr, i)
    ptf_to = _PM.var(pm, n,  :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n,  :qconv_tf_to, i)

    wf = _PM.var(pm, n,  :wf_ac, i)

    JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0 )
    JuMP.@constraint(pm.model, qpr_fr + qtf_to + -bv*filter*wf == 0)
end

function constraint_lossless_section(pm::_PM.AbstractWModels, w_fr, w_to, wr, wi, p_fr, p_to, q_fr, q_to)
    JuMP.@constraint(pm.model, w_fr ==  w_to)
    JuMP.@constraint(pm.model, wr   ==  w_fr)
    JuMP.@constraint(pm.model, wi   ==  0)

    pcon = JuMP.@constraint(pm.model, p_fr + p_to == 0)
    qcon = JuMP.@constraint(pm.model, q_fr + q_to == 0)
    return pcon, qcon
end



function add_converter_voltage_setpoint(sol, pm::_PM.AbstractWModels)
    _PM.add_setpoint!(sol, pm, "convdc", "vmconv", :wc_ac; scale = (x,item) -> sqrt(x))
    _PM.add_setpoint!(sol, pm, "convdc", "vmfilt", :wf_ac; scale = (x,item) -> sqrt(x))
end
"""
LCC firing angle constraints
```
qconv_ac >= Q1 + (pconv_ac-P1) * (Q2-Q1)/(P2-P1)

P1 = cos(0) * Srated
Q1 = sin(0) * Srated
P2 = cos(pi) * Srated
Q2 = sin(pi) * Srated
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractWModels, n::Int, i::Int, S, P1, Q1, P2, Q2)
    pc = _PM.var(pm, n,  :pconv_ac, i)
    qc = _PM.var(pm, n,  :qconv_ac, i)
    coeff = (Q2-Q1)/(P2-P1)

    JuMP.@constraint(pm.model, qc >= Q1 + (pc-P1) * coeff )
end

################ TNEP constraints #####################
function variable_converter_filter_voltage_ne(pm::_PM.AbstractWRModels; kwargs...)
    variable_converter_filter_voltage_magnitude_sqr_ne(pm; kwargs...)
    variable_converter_filter_voltage_cross_products_ne(pm; kwargs...)
end

function variable_converter_internal_voltage_ne(pm::_PM.AbstractWRModels; kwargs...)
    variable_converter_internal_voltage_magnitude_sqr_ne(pm; kwargs...)
    variable_converter_internal_voltage_cross_products_ne(pm; kwargs...)
end

"""
Creates lossy converter model between AC and DC side

```
pconv_ac[i] + pconv_dc[i] == a*z + b*I + c*Isq
```
"""
function constraint_converter_losses_ne(pm::_PM.AbstractWModels, n::Int, i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne, i)
    iconv = _PM.var(pm, n, :iconv_ac_ne, i)
    iconv_sq = _PM.var(pm, n, :iconv_ac_sq_ne, i)
    z = _PM.var(pm, n, :conv_ne, i)

    JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a*z + b*iconv + c*iconv_sq)
end


"""
Converter transformer constraints

```
p_tf_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)
q_tf_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)
p_tf_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))
q_tf_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))
```
"""
function constraint_conv_transformer_ne(pm::_PM.AbstractWRModels, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr_ne, i)
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to_ne, i)

    w = _PM.var(pm, n, :w, acbus)  # vm^2
    w_du = _PM.var(pm, n, :w_du, i)
    wf = _PM.var(pm, n, :wf_ac_ne, i)   # vmf * vmf
    wrf = _PM.var(pm, n, :wrf_ac_ne, i) # vm*vmf*cos(va-vaf) =  vmf*vm*cos(vaf-va)
    wif = _PM.var(pm, n, :wif_ac_ne, i) # vm*vmf*sin(va-vaf) = -vmf*vm*sin(vaf-va)
    z = _PM.var(pm, n, :conv_ne)[i]
    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm, gtf, btf, w_du, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)

        _IM.relaxation_equality_on_off(pm.model, w, w_du, z)
        JuMP.@constraint(pm.model, w_du >= z*JuMP.lower_bound(w))
        JuMP.@constraint(pm.model, w_du <= z*JuMP.upper_bound(w))
        constraint_voltage_product_converter_ne(pm, wrf, wif, wf, w, z)
    else
        pcon, qcon = constraint_lossless_section_ne(pm, w_du, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to)
        _IM.relaxation_equality_on_off(pm.model, w, w_du, z)
        JuMP.@constraint(pm.model, w_du >= z*JuMP.lower_bound(w))
        JuMP.@constraint(pm.model, w_du <= z*JuMP.upper_bound(w))
    end
end

"""
Converter reactor constraints

```
p_pr_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)
q_pr_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)
p_pr_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))
q_pr_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))
```
"""
function constraint_conv_reactor_ne(pm::_PM.AbstractWRModels, n::Int, i::Int, rc, xc, reactor)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr_ne, i)
    ppr_to = -_PM.var(pm, n, :pconv_ac_ne, i)
    qpr_to = -_PM.var(pm, n, :qconv_ac_ne, i)

    wf = _PM.var(pm, n, :wf_ac_ne, i)
    wc = _PM.var(pm, n, :wc_ac_ne, i)
    wrc = _PM.var(pm, n, :wrc_ac_ne, i)
    wic = _PM.var(pm, n, :wic_ac_ne, i)
    z = _PM.var(pm, n, :conv_ne)[i]
    zc  = rc  + im*xc

    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm, gc, bc, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to, 1)
        constraint_voltage_product_converter_ne(pm, wrc, wic, wf, wc, z)
    else
        pcon, qcon = constraint_lossless_section_ne(pm, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to)
    end
end

"""
Converter filter constraints

```
p_pr_fr + p_tf_to == 0
q_pr_fr + q_tf_to + -bv*filter*wf == 0
```
"""
function constraint_conv_filter_ne(pm::_PM.AbstractWModels, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to_ne, i)
    wf = _PM.var(pm, n, :wf_ac_ne, i)
    JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0 )

    JuMP.@constraint(pm.model, qpr_fr + qtf_to + (-bv) * filter * (wf) == 0)

end
function constraint_lossless_section_ne(pm::_PM.AbstractWModels, w_fr, w_to, wr, wi, p_fr, p_to, q_fr, q_to)
    JuMP.@constraint(pm.model, w_fr ==  w_to)
    JuMP.@constraint(pm.model, wr   ==  w_fr)
    JuMP.@constraint(pm.model, wi   ==  0)

    pcon = JuMP.@constraint(pm.model, p_fr + p_to == 0)
    qcon = JuMP.@constraint(pm.model, q_fr + q_to == 0)
    return pcon, qcon
end
function add_converter_voltage_setpoint_ne(sol, pm::_PM.AbstractWModels)
    _PM.add_setpoint!(sol, pm, "convdc", "vmconv", :wc_ac_ne; scale = (x,item) -> sqrt(x))
    _PM.add_setpoint!(sol, pm, "convdc", "vmfilt", :wf_ac_ne; scale = (x,item) -> sqrt(x))
end

"""
LCC firing angle constraints

```
qconv_ac >= Q1 + (pconv_ac-P1) * (Q2-Q1)/(P2-P1)

P1 = cos(0) * Srated
Q1 = sin(0) * Srated
P2 = cos(pi) * Srated
Q2 = sin(pi) * Srated
```
"""
function constraint_conv_firing_angle_ne(pm::_PM.AbstractWModels, n::Int, i::Int, S, P1, Q1, P2, Q2)
    pc = _PM.var(pm, n, :pconv_ac_ne, i)
    qc = _PM.var(pm, n, :qconv_ac_ne, i)
    coeff = (Q2-Q1)/(P2-P1)

    JuMP.@constraint(pm.model, qc >= Q1 + (pc-P1) * coeff )
end
