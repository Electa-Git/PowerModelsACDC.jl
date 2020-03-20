function variable_converter_filter_voltage(pm::AbstractWModels; kwargs...)
    variable_converter_filter_voltage_magnitude_sqr(pm; kwargs...)
    variable_converter_filter_voltage_cross_products(pm; kwargs...)
end

function variable_converter_internal_voltage(pm::AbstractWModels; kwargs...)
    variable_converter_internal_voltage_magnitude_sqr(pm; kwargs...)
    variable_converter_internal_voltage_cross_products(pm; kwargs...)
end
"""
Creates lossy converter model between AC and DC side
```
pconv_ac[i] + pconv_dc[i] == a + b*I + c*Isq
```
"""
function constraint_converter_losses(pm::AbstractWModels, n::Int, cnd::Int, i::Int, a, b, c, plmax)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    pconv_dc = PowerModels.var(pm, n, cnd, :pconv_dc, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)
    iconv_sq = PowerModels.var(pm, n, cnd, :iconv_ac_sq, i)

    PowerModels.con(pm, n, cnd, :conv_loss)[i] = @constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv_sq)
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
function constraint_conv_transformer(pm::AbstractWRModels, n::Int, cnd::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = PowerModels.var(pm, n, cnd, :pconv_tf_fr, i)
    qtf_fr = PowerModels.var(pm, n, cnd, :qconv_tf_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)
    qtf_to = PowerModels.var(pm, n, cnd, :qconv_tf_to, i)

    w = PowerModels.var(pm, n, cnd, :w, acbus)  # vm^2
    wf = PowerModels.var(pm, n, cnd, :wf_ac, i)   # vmf * vmf
    wrf = PowerModels.var(pm, n, cnd, :wrf_ac, i) # vm*vmf*cos(va-vaf) =  vmf*vm*cos(vaf-va)
    wif = PowerModels.var(pm, n, cnd, :wif_ac, i) # vm*vmf*sin(va-vaf) = -vmf*vm*sin(vaf-va)

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm, gtf, btf, w, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = c1
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = c2
        PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = c3
        PowerModels.con(pm, n, cnd, :conv_tf_q_to)[i] = c4

        #@constraint(pm.model, (wrf)^2 + (wif)^2 <= wf*w)
        constraint_voltage_product_converter(pm, wrf, wif, wf, w)
    else
        pcon, qcon = constraint_lossless_section(pm, w, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to)
    end
end
"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints_w(pm::AbstractWRModels, g, b, w_fr, w_to, wr, wi, p_fr, p_to, q_fr, q_to, tm)
    c1 = @constraint(pm.model, p_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)
    c2 = @constraint(pm.model, q_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)
    c3 = @constraint(pm.model, p_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))
    c4 = @constraint(pm.model, q_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))
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
function constraint_conv_reactor(pm::AbstractWRModels, n::Int, cnd::Int, i::Int, rc, xc, reactor)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    qpr_fr = PowerModels.var(pm, n, cnd, :qconv_pr_fr, i)
    ppr_to = -PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qpr_to = -PowerModels.var(pm, n, cnd, :qconv_ac, i)

    wf = PowerModels.var(pm, n, cnd, :wf_ac, i)
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    wrc = PowerModels.var(pm, n, cnd, :wrc_ac, i)
    wic = PowerModels.var(pm, n, cnd, :wic_ac, i)

    zc  = rc  + im*xc

    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        constraint_voltage_product_converter(pm, wrc, wic, wf, wc)
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm, gc, bc, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to, 1)
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = c1
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = c2
    else
        pcon, qcon = constraint_lossless_section(pm, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to)
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = pcon
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = qcon
    end
end
"""
Converter filter constraints

```
p_pr_fr + p_tf_to == 0
q_pr_fr + q_tf_to + -bv*filter*wf == 0
```
"""
function constraint_conv_filter(pm::AbstractWModels, n::Int, cnd::Int, i::Int, bv, filter)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    qpr_fr = PowerModels.var(pm, n, cnd, :qconv_pr_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)
    qtf_to = PowerModels.var(pm, n, cnd, :qconv_tf_to, i)

    wf = PowerModels.var(pm, n, cnd, :wf_ac, i)

    PowerModels.con(pm, n, cnd, :conv_kcl_p)[i] = @constraint(pm.model, ppr_fr + ptf_to == 0 )
    PowerModels.con(pm, n, cnd, :conv_kcl_q)[i] = @constraint(pm.model, qpr_fr + qtf_to + -bv*filter*wf == 0)
end

function constraint_lossless_section(pm::AbstractWModels, w_fr, w_to, wr, wi, p_fr, p_to, q_fr, q_to)
    @constraint(pm.model, w_fr ==  w_to)
    @constraint(pm.model, wr   ==  w_fr)
    @constraint(pm.model, wi   ==  0)

    pcon = @constraint(pm.model, p_fr + p_to == 0)
    qcon = @constraint(pm.model, q_fr + q_to == 0)
    return pcon, qcon
end



function add_converter_voltage_setpoint(sol, pm::AbstractWModels)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vmconv", :wc_ac; scale = (x,item) -> sqrt(x))
    PowerModels.add_setpoint!(sol, pm, "convdc", "vmfilt", :wf_ac; scale = (x,item) -> sqrt(x))
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
function constraint_conv_firing_angle(pm::AbstractWModels, n::Int, cnd::Int, i::Int, S, P1, Q1, P2, Q2)
    pc = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qc = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    coeff = (Q2-Q1)/(P2-P1)

    PowerModels.con(pm, n, cnd, :conv_socphi)[i] = @constraint(pm.model, qc >= Q1 + (pc-P1) * coeff )
end
