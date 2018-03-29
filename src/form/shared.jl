function variable_converter_filter_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractWRForms}
    variable_converter_filter_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_converter_filter_voltage_cross_products(pm, n; kwargs...)
end

function variable_converter_internal_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractWRForms}
    variable_converter_internal_voltage_magnitude_sqr(pm, n; kwargs...)
    variable_converter_internal_voltage_cross_products(pm, n; kwargs...)
end

function variable_dcgrid_voltage_magnitude(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractWForms}
    variable_dcgrid_voltage_magnitude_sqr(pm, n; kwargs...)
end

"""
```
sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) == sum(pg[g] for g in bus_gens)  - pd - gs*w
sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac) == sum(qg[g] for g in bus_gens)  - qd + bs*w
```
"""
function constraint_kcl_shunt(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, pd, qd, gs, bs) where {T <: PowerModels.AbstractWForms}
    w = pm.var[:nw][n][:w][i]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    pconv_grid_ac = pm.var[:nw][n][:pconv_grid_ac]
    qconv_grid_ac = pm.var[:nw][n][:qconv_grid_ac]

    pm.con[:nw][n][:kcl_p][i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - pd  - gs*w)
    pm.con[:nw][n][:kcl_q][i] = @constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - qd  + bs*w)
end

"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p) where {T <: PowerModels.AbstractWRForms}
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]

    wdc_fr = pm.var[:nw][n][:wdc][f_bus]
    wdc_to = pm.var[:nw][n][:wdc][t_bus]
    wdc_frto = pm.var[:nw][n][:wdcr][(f_bus, t_bus)]

    @constraint(pm.model, p_dc_fr == p * g *  (wdc_fr - wdc_frto))
    @constraint(pm.model, p_dc_to == p * g *  (wdc_to - wdc_frto))
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

"`wdc[i] == vdcm^2`"
function constraint_dc_voltage_magnitude_setpoint(pm::GenericPowerModel{T}, n::Int, i, vdcm) where {T <: PowerModels.AbstractWForms}
    wdc = pm.var[:nw][n][:wdc][i]
    pm.con[:nw][n][:v_dc][i] = @constraint(pm.model, wdc == vdcm^2)
end

function add_dc_bus_voltage_setpoint(sol, pm::GenericPowerModel{T}) where {T <: PowerModels.AbstractWForms}
    PowerModels.add_setpoint(sol, pm, "busdc", "vm", :wdc; scale = (x,item) -> sqrt(x))
end

function add_converter_voltage_setpoint(sol, pm::GenericPowerModel{T}) where {T <: PowerModels.AbstractWForms}
    PowerModels.add_setpoint(sol, pm, "convdc", "vmconv", :wc_ac; scale = (x,item) -> sqrt(x))
    PowerModels.add_setpoint(sol, pm, "convdc", "vmfilt", :wf_ac; scale = (x,item) -> sqrt(x))
end


function constraint_conv_filter(pm::GenericPowerModel{T}, n::Int, i::Int, bv, filter) where {T <: PowerModels.AbstractWForms}
    ppr_fr = pm.var[:nw][n][:pconv_pr_from][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_from][i]
    ptf_to = pm.var[:nw][n][:pconv_grid_ac_to][i]
    qtf_to = pm.var[:nw][n][:qconv_grid_ac_to][i]

    wf_ac = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf

    pm.con[:nw][n][:conv_kcl_p][i] = @constraint(pm.model, ppr_fr + ptf_to == 0 )
    pm.con[:nw][n][:conv_kcl_q][i] = @constraint(pm.model, qpr_fr + qtf_to + -bv*filter*wf_ac == 0)
end
