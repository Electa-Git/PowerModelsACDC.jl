"""
Creates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically

```
pconv_ac[i] + pconv_dc[i] == a + b*pconv_ac
```
"""
function constraint_converter_losses(pm::AbstractDCPModel, n::Int, cnd::Int, i::Int, a, b, c, plmax)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    pconv_dc = PowerModels.var(pm, n, cnd, :pconv_dc, i)
    v = 1 #pu, assumption to approximate current
    cm_conv_ac = pconv_ac/v # can actually be negative, not a very nice model...
    if pm.setting["conv_losses_mp"] == true
        PowerModels.con(pm, n, cnd, :conv_loss)[i] = @constraint(pm.model, pconv_ac + pconv_dc == a + b*cm_conv_ac )
    else
        PowerModels.con(pm, n, cnd, :conv_loss)[i] = @constraint(pm.model, pconv_ac + pconv_dc >= a + b*cm_conv_ac )
        PowerModels.con(pm, n, cnd, :conv_loss_aux)[i] = @constraint(pm.model, pconv_ac + pconv_dc >= a - b*cm_conv_ac )
        PowerModels.con(pm, n, cnd, :conv_loss_plmax)[i] = @constraint(pm.model, pconv_ac + pconv_dc <= plmax)
    end
end
"""
Converter transformer constraints

```
p_tf_fr == -btf*(v^2)/tm*(va-vaf)
p_tf_to == -btf*(v^2)/tm*(vaf-va)
```
"""
function constraint_conv_transformer(pm::AbstractDCPModel, n::Int, cnd::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = PowerModels.var(pm, n, cnd, :pconv_tf_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)

    vaf = PowerModels.var(pm, n, cnd, :vaf, i)
    va = PowerModels.var(pm, n, cnd, :va, acbus)

    if transformer
        btf = imag(1/(im*xtf)) # classic DC approach to obtain susceptance form
        v = 1 # pu, assumption DC approximation
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = @constraint(pm.model, ptf_fr == -btf*(v^2)/tm*(va-vaf))
        PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = @constraint(pm.model, ptf_to == -btf*(v^2)/tm*(vaf-va))
    else
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = @constraint(pm.model, va == vaf)
        PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = @constraint(pm.model, ptf_fr + ptf_to  == 0)
    end
end
"""
Converter reactor constraints

```
p_pr_fr == -bc*(v^2)*(vaf-vac)
pconv_ac == -bc*(v^2)*(vac-vaf)
```
"""
function constraint_conv_reactor(pm::AbstractDCPModel, n::Int, cnd::Int, i::Int, rc, xc, reactor)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    vaf = PowerModels.var(pm, n, cnd, :vaf, i)
    vac = PowerModels.var(pm, n, cnd, :vac, i)

    if reactor
        bc = imag(1/(im*xc))
        v = 1 # pu, assumption DC approximation
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = @constraint(pm.model, ppr_fr == -bc*(v^2)*(vaf-vac))
        PowerModels.con(pm, n, cnd, :conv_pr_p_to)[i] = @constraint(pm.model, pconv_ac == -bc*(v^2)*(vac-vaf))
    else
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] =  @constraint(pm.model, vac == vaf)
        PowerModels.con(pm, n, cnd, :conv_pr_p_to)[i] = @constraint(pm.model, ppr_fr + pconv_ac  == 0)
    end
end
"""
Converter filter constraints (no active power losses)
```
p_pr_fr + p_tf_to == 0
```
"""
function constraint_conv_filter(pm::AbstractDCPModel, n::Int, cnd::Int, i::Int, bv, filter)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)

    PowerModels.con(pm, n, cnd, :conv_kcl_p)[i] = @constraint(pm.model,   ppr_fr + ptf_to == 0 )
end
"""
Converter current constraint (not applicable)
```
```
"""
function constraint_converter_current(pm::AbstractDCPModel, n::Int, cnd::Int, i::Int, Umax, Imax)
    # not used
end
function variable_dc_converter(pm::AbstractDCPModel; kwargs...)
    variable_converter_active_power(pm; kwargs...)
    variable_dcside_power(pm; kwargs...)
    variable_converter_filter_voltage(pm; kwargs...)
    variable_converter_internal_voltage(pm; kwargs...)
    variable_converter_to_grid_active_power(pm; kwargs...)

    variable_conv_transformer_active_power_to(pm; kwargs...)
    variable_conv_reactor_active_power_from(pm; kwargs...)
end

function variable_converter_filter_voltage(pm::AbstractDCPModel; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end


function variable_converter_internal_voltage(pm::AbstractDCPModel; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end
"""
Converter reactive power setpoint constraint (PF only, not applicable)
```
```
"""
function constraint_reactive_conv_setpoint(pm::AbstractDCPModel, n::Int, cnd::Int, i, qconv)
end
"""
Converter firing angle constraint (not applicable)
```
```
"""
function constraint_conv_firing_angle(pm::AbstractDCPModel, n::Int, cnd::Int, i::Int, S, P1, Q1, P2, Q2)
end
"""
Converter droop constraint (not applicable)
```
```
"""
function constraint_dc_droop_control(pm::AbstractDCPModel, n::Int, cnd::Int, i::Int, busdc_i, vref_dc, pref_dc, k_droop)
end
