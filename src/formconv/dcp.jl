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
    cm_conv_ac = pconv_ac/v # can actually be negative, not a very nice model...
    pm.con[:nw][n][:conv_loss][i] = @constraint(pm.model, pconv_ac + pconv_dc == a + b*cm_conv_ac )
    #pm.con[:nw][n][:conv_loss][i] = @constraint(pm.model, pconv_ac + pconv_dc == a  )
end

"""
Converter transformer constraints

```
p_tf_fr == -btf*(v^2)/tm*(va-vaf)
p_tf_to == -btf*(v^2)/tm*(vaf-va)
```
"""

function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractDCPForm}
    ptf_fr = pm.var[:nw][n][:pconv_tf_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    #filter voltage angle
    vaf = pm.var[:nw][n][:vaf][i]
    #acbus voltage angle
    va = pm.var[:nw][n][:va][acbus]

    if transformer
        btf = imag(1/(im*xtf)) # classic DC approach to obtain susceptance form
        v = 1 # pu, assumption DC approximation
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, ptf_fr == -btf*(v^2)/tm*(va-vaf))
        pm.con[:nw][n][:conv_tf_p_to][i] = @constraint(pm.model, ptf_to == -btf*(v^2)/tm*(vaf-va))
    else
        pm.con[:nw][n][:conv_tf_p_to][i] = @constraint(pm.model, va == vaf)
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, ptf_fr + ptf_to  == 0)
    end
end

"""
Converter reactor constraints

```
p_pr_fr == -bc*(v^2)*(vaf-vac)
pconv_ac == -bc*(v^2)*(vac-vaf)
```
"""

function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractDCPForm}
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    #filter voltage angle
    vaf = pm.var[:nw][n][:vaf][i]
    #converter voltage angle
    vac = pm.var[:nw][n][:vac][i]

    if reactor
        bc = imag(1/(im*xc))
        v = 1 # pu, assumption DC approximation
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, ppr_fr == -bc*(v^2)*(vaf-vac))
        pm.con[:nw][n][:conv_pr_p_to][i] = @constraint(pm.model, pconv_ac == -bc*(v^2)*(vac-vaf))
    else
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, vac == vaf)
    end
end

"""
Converter filter constraints (no active power losses)

```
p_pr_fr + p_tf_to == 0
```
"""

function constraint_conv_filter(pm::GenericPowerModel{T}, n::Int, i::Int, bv, filter)where {T <: PowerModels.AbstractDCPForm}
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    pm.con[:nw][n][:conv_kcl_p][i] = @constraint(pm.model,   ppr_fr + ptf_to == 0 )
end


"""
Converter current constraint (not applicable)

```
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, Umax, Imax) where {T <: PowerModels.AbstractDCPForm}
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

"""
Converter reactive power setpoint constraint (PF only, not applicable)

```
```
"""
function constraint_reactive_conv_setpoint(pm::GenericPowerModel{T}, n::Int, i, qconv) where {T <: PowerModels.AbstractDCPForm}
end

"""
Converter firing angle constraint (not applicable)

```
```
"""
function constraint_conv_firing_angle(pm::GenericPowerModel{T}, n::Int, i::Int, S, P1, Q1, P2, Q2) where {T <: PowerModels.AbstractDCPForm}
end
