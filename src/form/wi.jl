#AbstractWIForm = AbstractWRForm
#AbstractWForms = Union{AbstractWRForms, AbstractWIForm}


function variable_converter_filter_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractWIForm}
    variable_converter_filter_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_conv_transformer_current_sqr(pm, n; kwargs...)

    variable_conv_transformer_active_power_to(pm, n; kwargs...)
    variable_conv_transformer_reactive_power_to(pm, n; kwargs...)
end


function variable_converter_internal_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractWIForm}
    variable_converter_internal_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_conv_reactor_current_sqr(pm, n; kwargs...)
    variable_conv_reactor_active_power_from(pm, n; kwargs...)
    variable_conv_reactor_reactive_power_from(pm, n; kwargs...)
end

"""
Creates transformer, filter and phase reactor model at ac side of converter

```
pconv_ac[i]
```
"""
function constraint_converter_filter_transformer_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, bv, rc, xc, acbus, transformer, filter, reactor) where {T <: PowerModels.AbstractWIForm}
    w = pm.var[:nw][n][:w][acbus] # vm^2
    itf = pm.var[:nw][n][:itf_sq][i]
    #filter voltage
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf_ac * vmf_ac
    #converter voltage
    ipr = pm.var[:nw][n][:irc_sq][i]
    wc = pm.var[:nw][n][:wc_ac][i]   # vmc_ac * vmc_ac

    #qf = -bv*wf

    ptf_fr = pm.var[:nw][n][:pconv_grid_ac][i]
    qtf_fr = pm.var[:nw][n][:qconv_grid_ac][i]
    ptf_to = pm.var[:nw][n][:pconv_grid_ac_to][i]
    qtf_to = pm.var[:nw][n][:qconv_grid_ac_to][i]
    ppr_to = -pm.var[:nw][n][:pconv_ac][i]
    qpr_to = -pm.var[:nw][n][:qconv_ac][i]
    ppr_fr = pm.var[:nw][n][:pconv_pr_from][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_from][i]

    # ppr_to = -pconv_ac
    # qpr_to = -qconv_ac
    # ppr_fr = -ptf_to
    # qpr_fr = -qtf_to - qf

    if transformer
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, ptf_fr + ptf_to ==  rtf*itf)
        pm.con[:nw][n][:conv_tf_q][i] = @constraint(pm.model, qtf_fr + qtf_to ==  xtf*itf)
        @NLconstraint(pm.model, ptf_fr^2 + qtf_fr^2 <= w * itf)
        @constraint(pm.model, wf == w -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf)
    else
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, ptf_fr + ptf_to == 0)
        pm.con[:nw][n][:conv_tf_q][i] = @constraint(pm.model, qtf_fr + qtf_to == 0)
        @constraint(pm.model, w ==  wf)
    end

    if reactor
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        pm.con[:nw][n][:conv_pr_q][i] = @constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        @NLconstraint(pm.model, ppr_fr^2 + qpr_fr^2 <= wf * ipr)
        @constraint(pm.model, wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)

    else
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, ppr_fr + ppr_to == 0)
        pm.con[:nw][n][:conv_tf_q][i] = @constraint(pm.model, qpr_fr + qpr_to == 0)
        @constraint(pm.model, wc ==  wf)
    end
    @constraint(pm.model, ptf_to + ppr_fr         == 0)
    @constraint(pm.model, qtf_to + qpr_fr + wf*bv == 0)
end

"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= 3 * wdc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= 3 * (Umax)^2] * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, bus_ac, Umax) where {T <: PowerModels.AbstractWIForm}
    wac = pm.var[:nw][n][:w][bus_ac]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model,      pconv_ac^2 + qconv_ac^2 <= 3 * wac * iconv_sq)
    pm.con[:nw][n][:conv_i_sqrt][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= 3 * (Umax)^2 * iconv^2)
end
