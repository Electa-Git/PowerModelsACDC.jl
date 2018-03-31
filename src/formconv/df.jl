function variable_converter_filter_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDFForm}
    variable_converter_filter_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_conv_transformer_current_sqr(pm, n; kwargs...)
end

function variable_converter_internal_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDFForm}
    variable_converter_internal_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_conv_reactor_current_sqr(pm, n; kwargs...)
end

function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractDFForm}
    w = pm.var[:nw][n][:w][acbus] # vm^2
    itf = pm.var[:nw][n][:itf_sq][i]
    #filter voltage
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf

    ptf_fr = pm.var[:nw][n][:pconv_tf_fr][i]
    qtf_fr = pm.var[:nw][n][:qconv_tf_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    qtf_to = pm.var[:nw][n][:qconv_tf_to][i]

    if transformer
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model,   ptf_fr + ptf_to ==  rtf*itf)
        pm.con[:nw][n][:conv_tf_q_fr][i] = @constraint(pm.model,   qtf_fr + qtf_to ==  xtf*itf)
        pm.con[:nw][n][:conv_tf_p_to][i] = @constraint(pm.model,   ptf_fr^2 + qtf_fr^2 <= w/tm^2 * itf)
        pm.con[:nw][n][:conv_tf_q_to][i] = @constraint(pm.model,   wf == w/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf)
    else
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, ptf_fr + ptf_to == 0)
        pm.con[:nw][n][:conv_tf_q_fr][i] = @constraint(pm.model, qtf_fr + qtf_to == 0)
        @constraint(pm.model, wf == w/tm^2 )
    end
end

function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractDFForm}
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf
    #converter voltage
    ipr = pm.var[:nw][n][:irc_sq][i]
    wc = pm.var[:nw][n][:wc_ac][i]   # vmc * vmc

    ppr_to = -pm.var[:nw][n][:pconv_ac][i]
    qpr_to = -pm.var[:nw][n][:qconv_ac][i]
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_fr][i]

    if reactor
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        pm.con[:nw][n][:conv_pr_q][i] = @constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        @constraint(pm.model, ppr_fr^2 + qpr_fr^2 <= wf * ipr)
        @constraint(pm.model, wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)

    else
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, ppr_fr + ppr_to == 0)
        pm.con[:nw][n][:conv_pr_q][i] = @constraint(pm.model, qpr_fr + qpr_to == 0)
        @constraint(pm.model, wc == wf)
    end
end

"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, Umax) where {T <: PowerModels.AbstractDFForm}
    wc = pm.var[:nw][n][:wc_ac][i]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model,      pconv_ac^2 + qconv_ac^2 <=  wc * iconv_sq)
    pm.con[:nw][n][:conv_i_sqrt][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (Umax)^2 * iconv^2)
end
