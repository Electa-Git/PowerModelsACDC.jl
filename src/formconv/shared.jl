function variable_converter_filter_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractWRForms}
    variable_converter_filter_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_converter_filter_voltage_cross_products(pm, n; kwargs...)
end

function variable_converter_internal_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractWRForms}
    variable_converter_internal_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_converter_internal_voltage_cross_products(pm, n; kwargs...)
end

"""
Creates lossy converter model between AC and DC side

```
pconv_ac[i] + pconv_dc[i] == a + b*I + c*Isq
```
"""
function constraint_converter_losses(pm::GenericPowerModel{T}, n::Int, i::Int, a, b, c) where {T <: PowerModels.AbstractWForms}
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    pconv_dc = pm.var[:nw][n][:pconv_dc][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]

    pm.con[:nw][n][:conv_loss][i] = @constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv_sq)
end

function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractWRForms}
    ptf_fr = pm.var[:nw][n][:pconv_tf_fr][i]
    qtf_fr = pm.var[:nw][n][:qconv_tf_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    qtf_to = pm.var[:nw][n][:qconv_tf_to][i]

    #ac bus voltage
    w = pm.var[:nw][n][:w][acbus] # vm^2
    #filter voltage
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf
    wrf = pm.var[:nw][n][:wrf_ac][i] # vm*vmf*cos(va-vaf) =  vmf*vm*cos(vaf-va)
    wif = pm.var[:nw][n][:wif_ac][i] # vm*vmf*sin(va-vaf) = -vmf*vm*sin(vaf-va)

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm, gtf, btf, w, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
        pm.con[:nw][n][:conv_tf_p_fr][i] = c1
        pm.con[:nw][n][:conv_tf_q_fr][i] = c2
        pm.con[:nw][n][:conv_tf_p_to][i] = c3
        pm.con[:nw][n][:conv_tf_q_to][i] = c4

        #@constraint(pm.model, (wrf)^2 + (wif)^2 <= wf*w)
        constraint_voltage_product_converter(pm::GenericPowerModel{T}, wrf, wif, wf, w)
    else
        pcon, qcon = constraint_lossless_section(pm, w/tm^2, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to)
    end
end

"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints_w(pm::GenericPowerModel{T}, g, b, w_fr, w_to, wr, wi, p_fr, p_to, q_fr, q_to, tm)  where {T <: PowerModels.AbstractWRForms}
    c1 = @constraint(pm.model, p_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)
    c2 = @constraint(pm.model, q_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)
    c3 = @constraint(pm.model, p_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))
    c4 = @constraint(pm.model, q_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))
    return c1, c2, c3, c4
end


function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractWRForms}
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_fr][i]
    ppr_to = -pm.var[:nw][n][:pconv_ac][i]
    qpr_to = -pm.var[:nw][n][:qconv_ac][i]

    #filter voltage
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf

    #converter voltage
    wc = pm.var[:nw][n][:wc_ac][i]   # vmc * vmc
    wrc = pm.var[:nw][n][:wrc_ac][i] # vmc*vmf*cos(vac-vaf) =  vmf*vmc*cos(vaf-vac)
    wic = pm.var[:nw][n][:wic_ac][i] # vmc*vmf*sin(vac-vaf) = -vmf*vmc*sin(vaf-vac)

    zc  = rc  + im*xc

    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
#        PowerModels.relaxation_complex_product(pm.model, wf, wc, wrc, wic)
        constraint_voltage_product_converter(pm, wrc, wic, wf, wc)
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm, gc, bc, wf, wc, wrc, wic, ppr_fr, ppr_to, ppr_to, qpr_to, 1)
        pm.con[:nw][n][:conv_pr_p][i] = c1
        pm.con[:nw][n][:conv_pr_q][i] = c2
    else
        pcon, qcon = constraint_lossless_section(pm, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to)
        pm.con[:nw][n][:conv_pr_p][i] = pcon
        pm.con[:nw][n][:conv_pr_q][i] = qcon
    end
end


function constraint_conv_filter(pm::GenericPowerModel{T}, n::Int, i::Int, bv, filter) where {T <: PowerModels.AbstractWForms}
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    qtf_to = pm.var[:nw][n][:qconv_tf_to][i]

    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf

    pm.con[:nw][n][:conv_kcl_p][i] = @constraint(pm.model, ppr_fr + ptf_to == 0 )
    pm.con[:nw][n][:conv_kcl_q][i] = @constraint(pm.model, qpr_fr + qtf_to + -bv*filter*wf == 0)
end

function constraint_lossless_section(pm::GenericPowerModel{T}, w_fr, w_to, wr, wi, p_fr, p_to, q_fr, q_to) where {T <: PowerModels.AbstractWForms}
    @constraint(pm.model, w_fr ==  w_to)
    @constraint(pm.model, wr   ==  w_fr)
    @constraint(pm.model, wi   ==  0)

    pcon = @constraint(pm.model, p_fr + p_to == 0)
    qcon = @constraint(pm.model, q_fr + q_to == 0)
    return pcon, qcon
end



function add_converter_voltage_setpoint(sol, pm::GenericPowerModel{T}) where {T <: PowerModels.AbstractWForms}
    PowerModels.add_setpoint(sol, pm, "convdc", "vmconv", :wc_ac; scale = (x,item) -> sqrt(x))
    PowerModels.add_setpoint(sol, pm, "convdc", "vmfilt", :wf_ac; scale = (x,item) -> sqrt(x))
end
