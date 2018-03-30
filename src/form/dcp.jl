"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*1^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*1^2
```
"""
function constraint_kcl_shunt(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, pd, qd, gs, bs) where {T <: PowerModels.AbstractDCPForm}
    p = pm.var[:nw][n][:p]
    pg = pm.var[:nw][n][:pg]
    pconv_ac = pm.var[:nw][n][:pconv_ac]
    v = 1
    pm.con[:nw][n][:kcl_p][i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(pconv_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - pd  - gs*v^2)
end


"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == 0)
```
"""
function constraint_ohms_dc_branch(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p) where {T <: PowerModels.AbstractDCPForm}
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]

    @constraint(pm.model, p_dc_fr + p_dc_to == 0)
end


"""
Creates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically

```
pconv_ac[i] + pconv_dc[i] == a + b*pconv_ac
```
"""
function constraint_converter_losses(pm::GenericPowerModel{T}, n::Int, i::Int, a, b, c) where {T <: PowerModels.AbstractDCPForm}
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    pconv_dc = pm.var[:nw][n][:pconv_dc][i]
    v = 1 #pu, assumption to approximate current
    cm_conv_ac = pconv_ac/v
    pm.con[:nw][n][:conv_loss][i] = @constraint(pm.model, pconv_ac + pconv_dc == a + b*cm_conv_ac )
end

function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractDCPForm}
    ptf_fr = pm.var[:nw][n][:pconv_tf_fr][i]
    #filter voltage angle
    vaf = pm.var[:nw][n][:vaf][i]
    #acbus voltage angle
    va = pm.var[:nw][n][:va][acbus]

    if transformer
        btf = imag(1/(im*xtf)) # classic DC approach to obtain susceptance form
        v = 1 # pu, assumption DC approximation
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, ptf_fr == -btf*(v^2)/tm*(va-vaf))
    else
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, va == vaf)
    end
end

function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractDCPForm}
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    #filter voltage angle
    vaf = pm.var[:nw][n][:vaf][i]
    #converter voltage angle
    vac = pm.var[:nw][n][:vac][i]

    if reactor
        bc = imag(1/(im*xc))
        v = 1 # pu, assumption DC approximation
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, ppr_fr == -bc*(v^2)*(vaf-vac))
    else
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, vac == vaf)
    end
end

function constraint_conv_filter(pm::GenericPowerModel{T}, n::Int, i::Int, bv, filter)where {T <: PowerModels.AbstractDCPForm}
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    pm.con[:nw][n][:conv_kcl_p][i] = @constraint(pm.model,   ppr_fr + ptf_to == 0 )
end


""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, Umax) where {T <: PowerModels.AbstractDCPForm}
    # not used
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint(pm::GenericPowerModel{T}, n::Int, i, vdcm) where {T <: PowerModels.AbstractDCPForm}
    # not used
end

function variable_dcgrid_voltage_magnitude(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true) where {T <: PowerModels.AbstractDCPForm}
    # not used
end

function variable_dc_converter(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDCPForm}
    variable_converter_active_power(pm, n; kwargs...)
    variable_dcside_power(pm, n; kwargs...)
    variable_converter_filter_voltage(pm, n; kwargs...)
    variable_converter_internal_voltage(pm, n; kwargs...)
    variable_converter_to_grid_active_power(pm, n; kwargs...)

    variable_conv_transformer_active_power_to(pm, n; kwargs...)
    variable_conv_reactor_active_power_from(pm, n; kwargs...)
end

function variable_converter_filter_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDCPForm}
    variable_converter_filter_voltage_angle(pm, n; kwargs...)
end


function variable_converter_internal_voltage(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...) where {T <: PowerModels.AbstractDCPForm}
    variable_converter_internal_voltage_angle(pm, n; kwargs...)
end
