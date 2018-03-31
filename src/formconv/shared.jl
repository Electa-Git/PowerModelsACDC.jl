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

function add_converter_voltage_setpoint(sol, pm::GenericPowerModel{T}) where {T <: PowerModels.AbstractWForms}
    PowerModels.add_setpoint(sol, pm, "convdc", "vmconv", :wc_ac; scale = (x,item) -> sqrt(x))
    PowerModels.add_setpoint(sol, pm, "convdc", "vmfilt", :wf_ac; scale = (x,item) -> sqrt(x))
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
