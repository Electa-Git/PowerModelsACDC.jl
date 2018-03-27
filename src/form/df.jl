
"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p) where {T <: PowerModels.AbstractDFForm}
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]

    wdc_fr = pm.var[:nw][n][:wdc][f_bus]
    wdc_to = pm.var[:nw][n][:wdc][t_bus]
    wdc_frto = pm.var[:nw][n][:wdcr][(f_bus, t_bus)]

    #TODO change model to include squared current value
    @constraint(pm.model, p_dc_fr == p * g *  (wdc_fr - wdc_frto))
    @constraint(pm.model, p_dc_to == p * g *  (wdc_to - wdc_frto))
end

"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::GenericPowerModel{T}, n::Int) where {T <: PowerModels.AbstractDFForm}
    wdc = pm.var[:nw][n][:wdc]
    wdcr = pm.var[:nw][n][:wdcr]

    for (i,j) in keys(pm.ref[:nw][n][:buspairsdc])
        PowerModels.relaxation_complex_product(pm.model, wdc[i], wdc[j], wdcr[(i,j)], 0) #TODO
    end
end

function variable_converter_filter_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDFForm}
    variable_converter_filter_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_conv_transformer_current_sqr(pm, n; kwargs...)
end


function variable_converter_internal_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDFForm}
    variable_converter_internal_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_conv_reactor_current_sqr(pm, n; kwargs...)
end

function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, acbus, tap, transformer) where {T <: PowerModels.AbstractDFForm}
    w = pm.var[:nw][n][:w][acbus] # vm^2
    itf = pm.var[:nw][n][:itf_sq][i]
    #filter voltage
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf

    ptf_fr = pm.var[:nw][n][:pconv_grid_ac][i]
    qtf_fr = pm.var[:nw][n][:qconv_grid_ac][i]
    ptf_to = pm.var[:nw][n][:pconv_grid_ac_to][i]
    qtf_to = pm.var[:nw][n][:qconv_grid_ac_to][i]

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

end

function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractDFForm}
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf
    #converter voltage
    ipr = pm.var[:nw][n][:irc_sq][i]
    wc = pm.var[:nw][n][:wc_ac][i]   # vmc * vmc

    ppr_to = -pm.var[:nw][n][:pconv_ac][i]
    qpr_to = -pm.var[:nw][n][:qconv_ac][i]
    ppr_fr = pm.var[:nw][n][:pconv_pr_from][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_from][i]

    if reactor
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        pm.con[:nw][n][:conv_pr_q][i] = @constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        @NLconstraint(pm.model, ppr_fr^2 + qpr_fr^2 <= wf * ipr)
        @constraint(pm.model, wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)

    else
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, ppr_fr + ppr_to == 0)
        pm.con[:nw][n][:conv_tf_q][i] = @constraint(pm.model, qpr_fr + qpr_to == 0)
        @constraint(pm.model, wc == wf)
    end
end

function constraint_conv_filter(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, bv, rc, xc, acbus, transformer, reactor, filter) where {T <: PowerModels.AbstractDFForm}
    ptf_to = pm.var[:nw][n][:pconv_grid_ac_to][i]
    qtf_to = pm.var[:nw][n][:qconv_grid_ac_to][i]
    ppr_fr = pm.var[:nw][n][:pconv_pr_from][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_from][i]
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf
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
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, bus_ac, Umax) where {T <: PowerModels.AbstractDFForm}
    wac = pm.var[:nw][n][:w][bus_ac]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model,      pconv_ac^2 + qconv_ac^2 <= 3 * wac * iconv_sq)
    pm.con[:nw][n][:conv_i_sqrt][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= 3 * (Umax)^2 * iconv^2)
end
