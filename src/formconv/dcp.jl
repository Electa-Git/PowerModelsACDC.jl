"""
Creates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically

```
pconv_ac[i] + pconv_dc[i] == a + b*pconv_ac
```
"""
function constraint_converter_losses(pm::_PM.AbstractDCPModel, n::Int,  i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    v = 1 #pu, assumption to approximate current
    cm_conv_ac = pconv_ac/v # can actually be negative, not a very nice model...
    if pm.setting["conv_losses_mp"] == true
        # _PM.con(pm, n, :conv_loss)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a + b*cm_conv_ac )
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a + b*cm_conv_ac )
    else
        # _PM.con(pm, n, :conv_loss)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc >= a + b*cm_conv_ac )
        # _PM.con(pm, n, :conv_loss_aux)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc >= a - b*cm_conv_ac )
        # _PM.con(pm, n, :conv_loss_plmax)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc <= plmax)
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc >= a + b*cm_conv_ac )
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc >= a - b*cm_conv_ac )
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc <= plmax)
    end
end
"""
Converter transformer constraints

```
p_tf_fr == -btf*(v^2)/tm*(va-vaf)
p_tf_to == -btf*(v^2)/tm*(vaf-va)
```
"""
function constraint_conv_transformer(pm::_PM.AbstractDCPModel, n::Int,  i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)

    vaf = _PM.var(pm, n, :vaf, i)
    va = _PM.var(pm, n, :va, acbus)

    if transformer
        btf = imag(1/(im*xtf)) # classic DC approach to obtain susceptance form
        v = 1 # pu, assumption DC approximation
        # _PM.con(pm, n, :conv_tf_p_fr)[i] = JuMP.@constraint(pm.model, ptf_fr == -btf*(v^2)/tm*(va-vaf))
        # _PM.con(pm, n, :conv_tf_p_to)[i] = JuMP.@constraint(pm.model, ptf_to == -btf*(v^2)/tm*(vaf-va))
        JuMP.@constraint(pm.model, ptf_fr == -btf*(v^2)/tm*(va-vaf))
        JuMP.@constraint(pm.model, ptf_to == -btf*(v^2)/tm*(vaf-va))
    else
        # _PM.con(pm, n, :conv_tf_p_fr)[i] = JuMP.@constraint(pm.model, va == vaf)
        # _PM.con(pm, n, :conv_tf_p_to)[i] = JuMP.@constraint(pm.model, ptf_fr + ptf_to  == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, ptf_fr + ptf_to  == 0)
    end
end
"""
Converter reactor constraints

```
p_pr_fr == -bc*(v^2)*(vaf-vac)
pconv_ac == -bc*(v^2)*(vac-vaf)
```
"""
function constraint_conv_reactor(pm::_PM.AbstractDCPModel, n::Int,  i::Int, rc, xc, reactor)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    vaf = _PM.var(pm, n, :vaf, i)
    vac = _PM.var(pm, n, :vac, i)

    if reactor
        bc = imag(1/(im*xc))
        v = 1 # pu, assumption DC approximation
        # _PM.con(pm, n, :conv_pr_p)[i] = JuMP.@constraint(pm.model, ppr_fr == -bc*(v^2)*(vaf-vac))
        # _PM.con(pm, n, :conv_pr_p_to)[i] = JuMP.@constraint(pm.model, pconv_ac == -bc*(v^2)*(vac-vaf))
        JuMP.@constraint(pm.model, ppr_fr == -bc*(v^2)*(vaf-vac))
        JuMP.@constraint(pm.model, pconv_ac == -bc*(v^2)*(vac-vaf))
    else
        # _PM.con(pm, n, :conv_pr_p)[i] =  JuMP.@constraint(pm.model, vac == vaf)
        # _PM.con(pm, n, :conv_pr_p_to)[i] = JuMP.@constraint(pm.model, ppr_fr + pconv_ac  == 0)
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, ppr_fr + pconv_ac  == 0)
    end
end
"""
Converter filter constraints (no active power losses)
```
p_pr_fr + p_tf_to == 0
```
"""
function constraint_conv_filter(pm::_PM.AbstractDCPModel, n::Int,  i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)

    # _PM.con(pm, n, :conv_kcl_p)[i] = JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
end
"""
Converter current constraint (not applicable)
```
```
"""
function constraint_converter_current(pm::_PM.AbstractDCPModel, n::Int,  i::Int, Umax, Imax)
    # not used
end
function variable_dc_converter(pm::_PM.AbstractDCPModel; kwargs...)
    variable_converter_active_power(pm; kwargs...)
    variable_dcside_power(pm; kwargs...)
    variable_converter_filter_voltage(pm; kwargs...)
    variable_converter_internal_voltage(pm; kwargs...)
    variable_converter_to_grid_active_power(pm; kwargs...)

    variable_conv_transformer_active_power_to(pm; kwargs...)
    variable_conv_reactor_active_power_from(pm; kwargs...)
end

function variable_converter_filter_voltage(pm::_PM.AbstractDCPModel; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end


function variable_converter_internal_voltage(pm::_PM.AbstractDCPModel; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end
"""
Converter reactive power setpoint constraint (PF only, not applicable)
```
```
"""
function constraint_reactive_conv_setpoint(pm::_PM.AbstractDCPModel, n::Int,  i, qconv)
end
"""
Converter firing angle constraint (not applicable)
```
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractDCPModel, n::Int,  i::Int, S, P1, Q1, P2, Q2)
end
"""
Converter droop constraint (not applicable)
```
```
"""
function constraint_dc_droop_control(pm::_PM.AbstractDCPModel, n::Int,  i::Int, busdc_i, vref_dc, pref_dc, k_droop)
end
######################## TNEP Constraints #################
"""
Creates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically

```
pconv_ac[i] + pconv_dc[i] == a + b*pconv_ac
```
"""
function constraint_converter_losses_ne(pm::_PM.AbstractDCPModel, n::Int, i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne)[i]
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne)[i]
    z = _PM.var(pm, n, :conv_ne)[i]
    v = 1 #pu, assumption to approximate current
    cm_conv_ac = pconv_ac/v # can actually be negative, not a very nice model...
    # binary to omit the no load losses, power omitted via binary constraint in varible bounds
    if pm.setting["conv_losses_mp"] == true
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a * z + b*cm_conv_ac )
    else
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc >= a * z + b*cm_conv_ac )
        JuMP.@constraint(pm.model, pconv_ac + pconv_dc >= a * z - b*cm_conv_ac )
        JuMP.@constraint(pm.model,  pconv_ac + pconv_dc <= plmax)
    end
     #pm.con[:nw][n][:conv_loss_ne][i] = @constraint(pm.model, pconv_ac + pconv_dc == a * z )
end

function constraint_conv_transformer_ne(pm::_PM.AbstractDCPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    #filter voltage angle
    vaf = _PM.var(pm, n, :vaf_ne, i)
    #acbus voltage angle
    va = _PM.var(pm, n, :va, acbus)
    va_du = _PM.var(pm, n, :va_du, i)
    JuMP.set_upper_bound(va, pi/2)
    JuMP.set_lower_bound(va, -pi/2)
    z = _PM.var(pm, n, :conv_ne, i)

    if transformer
        btf = imag(1/(im*xtf)) # classic DC approach to obtain susceptance form
        v = 1 # pu, assumption DC approximation
        JuMP.@constraint(pm.model, ptf_fr == -btf*(v^2)/tm*(va-vaf))
        JuMP.@constraint(pm.model, ptf_to == -btf*(v^2)/tm*(vaf-va))
    else
        JuMP.@constraint(pm.model, va_du == vaf)
        JuMP.@constraint(pm.model, ptf_fr + ptf_to  == 0)
    end
    relaxation_variable_on_off(pm.model, va, va_du, z)
    _IM.relaxation_equality_on_off(pm.model, va, va_du, z)
end
#
function constraint_conv_reactor_ne(pm::_PM.AbstractDCPModel, n::Int, i::Int, rc, xc, reactor)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    pconv = _PM.var(pm, n, :pconv_ac_ne, i)
    #filter voltage angle
    vaf = _PM.var(pm, n, :vaf_ne, i)
    #converter voltage angle
    vac = _PM.var(pm, n, :vac_ne, i)
    z = _PM.var(pm, n, :conv_ne)[i]

    if reactor
        bc = imag(1/(im*xc))
        v = 1 # pu, assumption DC approximation
        JuMP.@constraint(pm.model, ppr_fr == -bc*(v^2)*(vaf-vac))
        JuMP.@constraint(pm.model, pconv == -bc*(v^2)*(vac-vaf))
    else
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, ppr_fr + pconv == 0)
    end
end
#
function constraint_conv_filter_ne(pm::_PM.AbstractDCPModel, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
end
#
#
function constraint_converter_current_ne(pm::_PM.AbstractDCPModel, n::Int, i::Int, Umax, Imax)
     # not used
 end
#
#
function variable_dc_converter_ne(pm::_PM.AbstractDCPModel; kwargs...)
    variable_converter_ne(pm; kwargs...)
    variable_converter_active_power_ne(pm; kwargs...)
    variable_dcside_power_ne(pm; kwargs...)
    variable_converter_filter_voltage_ne(pm; kwargs...)
    variable_converter_internal_voltage_ne(pm; kwargs...)
    variable_converter_to_grid_active_power_ne(pm; kwargs...)

    variable_conv_transformer_active_power_to_ne(pm; kwargs...)
    variable_conv_reactor_active_power_from_ne(pm; kwargs...)
end

function variable_converter_filter_voltage_ne(pm::_PM.AbstractDCPModel; kwargs...)
    variable_converter_filter_voltage_angle_ne(pm; kwargs...)
end
#
#
function variable_converter_internal_voltage_ne(pm::_PM.AbstractDCPModel; kwargs...)
    variable_converter_internal_voltage_angle_ne(pm; kwargs...)
end

function variable_voltage_slack(pm::_PM.AbstractDCPModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=false)
    va_ne = _PM.var(pm, nw)[:va_du] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_va_du",
    lower_bound = -2*pi,
    upper_bound = 2*pi,
    start = 0,
    )
    report && _IM.sol_component_value(pm, nw, :convdc_ne, :va, _PM.ids(pm, nw, :convdc_ne), va_ne)
end
