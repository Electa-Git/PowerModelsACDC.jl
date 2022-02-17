#################### COLLECT ALL CONVERTER VARIABLES ######################
function variable_dc_converter(pm::_PM.AbstractIVRModel; kwargs...)
    variable_filter_voltage_real(pm; kwargs...) #
    variable_filter_voltage_imaginary(pm; kwargs...) #
    variable_converter_voltage_real(pm; kwargs...) #
    variable_converter_voltage_imaginary(pm; kwargs...) #
    variable_transformer_current_real_from(pm; kwargs...) #
    variable_transformer_current_real_to(pm; kwargs...)#
    variable_transformer_current_imaginary_from(pm; kwargs...) #
    variable_transformer_current_imaginary_to(pm; kwargs...)#
    variable_reactor_current_real_from(pm; kwargs...)#
    variable_reactor_current_real_to(pm; kwargs...)#
    variable_reactor_current_imaginary_from(pm; kwargs...)#
    variable_reactor_current_imaginary_to(pm; kwargs...)#
    variable_converter_current_real(pm; kwargs...)#
    variable_converter_current_imaginary(pm; kwargs...)#
    variable_converter_current_dc(pm; kwargs...)#
    variable_converter_current_lin(pm; kwargs...)#
    variable_converter_active_power(pm; kwargs...)
    variable_converter_reactive_power(pm; kwargs...)
    variable_dcside_power(pm; kwargs...)
end

########### CONVERTER AC SIDE VOLTAGES   ##############################
"real part of the voltage variable k at the filter bus"
function variable_filter_voltage_real(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vk_r = _PM.var(pm, nw)[:vk_r] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_vk_r",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "vr_start", 1.0)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vk_r[i], -convdc["Vmmax"])
            JuMP.set_upper_bound(vk_r[i],  convdc["Vmmax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :vk_r, _PM.ids(pm, nw, :convdc), vk_r)
end

"imaginary part of the voltage variable k at the filter bus"
function variable_filter_voltage_imaginary(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vk_i = _PM.var(pm, nw)[:vk_i] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_vk_i",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "vi_start", 1.0)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vk_i[i], -convdc["Vmmax"])
            JuMP.set_upper_bound(vk_i[i],  convdc["Vmmax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :vk_i, _PM.ids(pm, nw, :convdc), vk_i)
end

"real part of the voltage variable c at the PE converter bus"
function variable_converter_voltage_real(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vc_r = _PM.var(pm, nw)[:vc_r] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_vc_r",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "v_start", 1.0)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vc_r[i], -convdc["Vmmax"])
            JuMP.set_upper_bound(vc_r[i],  convdc["Vmmax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :vc_r, _PM.ids(pm, nw, :convdc), vc_r)
end

"imaginary part of the voltage variable c at the PE converter bus"
function variable_converter_voltage_imaginary(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vc_i = _PM.var(pm, nw)[:vc_i] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_vc_i",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "vi_start", 1.0)
    )

    if bounded
        for (i, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vc_i[i], -convdc["Vmmax"])
            JuMP.set_upper_bound(vc_i[i],  convdc["Vmmax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :vc_i, _PM.ids(pm, nw, :convdc), vc_i)
end
###################  CONVERTER AC SIDE CURRENT VARIABLES #########################################
function variable_transformer_current_real_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    iik_r = _PM.var(pm, nw)[:iik_r] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_iik_r",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(iik_r[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(iik_r[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iik_r, _PM.ids(pm, nw, :convdc), iik_r)
end

function variable_transformer_current_imaginary_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    iik_i = _PM.var(pm, nw)[:iik_i] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_iik_i",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(iik_i[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(iik_i[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iik_i, _PM.ids(pm, nw, :convdc), iik_i)
end

function variable_transformer_current_real_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    iki_r = _PM.var(pm, nw)[:iki_r] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_iki_r",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(iki_r[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(iki_r[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iki_r, _PM.ids(pm, nw, :convdc), iki_r)
end

function variable_transformer_current_imaginary_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    iki_i = _PM.var(pm, nw)[:iki_i] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_iki_i",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(iki_i[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(iki_i[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iki_i, _PM.ids(pm, nw, :convdc), iki_i)
end

function variable_reactor_current_real_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    ikc_r = _PM.var(pm, nw)[:ikc_r] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_ikc_r",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ikc_r[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(ikc_r[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :ikc_r, _PM.ids(pm, nw, :convdc), ikc_r)
end

function variable_reactor_current_imaginary_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    ikc_i = _PM.var(pm, nw)[:ikc_i] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_ikc_i",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ikc_i[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(ikc_i[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :ikc_i, _PM.ids(pm, nw, :convdc), ikc_i)
end

function variable_reactor_current_real_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    ick_r = _PM.var(pm, nw)[:ick_r] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_ick_r",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ick_r[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(ick_r[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :ick_r, _PM.ids(pm, nw, :convdc), ick_r)
end

function variable_reactor_current_imaginary_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    ick_i = _PM.var(pm, nw)[:ick_i] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_ick_i",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ick_i[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(ick_i[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :ick_i, _PM.ids(pm, nw, :convdc), ick_i)
end

function variable_converter_current_real(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    ic_r = _PM.var(pm, nw)[:ic_r] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_ic_r",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ic_r[c],  -convdc["Imax"] * bigM)
            JuMP.set_upper_bound(ic_r[c],   convdc["Imax"]* bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :ic_r, _PM.ids(pm, nw, :convdc), ic_r)
end

function variable_converter_current_imaginary(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    ic_i = _PM.var(pm, nw)[:ic_i] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_ic_i",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ic_i[c],  -convdc["Imax"] * bigM)
            JuMP.set_upper_bound(ic_i[c],   convdc["Imax"] * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :ic_i, _PM.ids(pm, nw, :convdc), ic_i)
end

function variable_converter_current_dc(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1.2;
    vpu = 1;
    iconv_dc = _PM.var(pm, nw)[:iconv_dc] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_iconv_dc",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(iconv_dc[c],  -convdc["Pacrated"]/vpu * bigM)
            JuMP.set_upper_bound(iconv_dc[c],   convdc["Pacrated"]/vpu * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iconv_dc, _PM.ids(pm, nw, :convdc), iconv_dc)
end

function variable_converter_current_lin(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1;
    vpu = 1;
    iconv_lin = _PM.var(pm, nw)[:iconv_lin] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_iconv_lin",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(iconv_lin[c],  0)
            JuMP.set_upper_bound(iconv_lin[c],  convdc["Imax"] * bigM)
        end
    end

    report && _PM.sol_component_value(pm, nw, :convdc, :iconv_lin, _PM.ids(pm, nw, :convdc), iconv_lin)
end

#################### CONVERTER CURRENT LIMITS #########################

function constraint_converter_limits(pm::_PM.AbstractIVRModel, n::Int, i, imax, vmax, vmin, b_idx, pdcmin, pdcmax)
    iik_r = _PM.var(pm, n, :iik_r)[i]
    iik_i = _PM.var(pm, n, :iik_i)[i]
    iki_r = _PM.var(pm, n, :iki_r)[i]
    iki_i = _PM.var(pm, n, :iki_i)[i]

    ikc_r = _PM.var(pm, n, :ikc_r)[i]
    ikc_i = _PM.var(pm, n, :ikc_i)[i]
    ick_r = _PM.var(pm, n, :ick_r)[i]
    ick_i = _PM.var(pm, n, :ick_i)[i]

    ic_r = _PM.var(pm, n, :ic_r)[i]
    ic_i = _PM.var(pm, n, :ic_i)[i]

    iconv_lin = _PM.var(pm, n, :iconv_lin)[i]

    vk_r = _PM.var(pm, n, :vk_r)[i]
    vk_i = _PM.var(pm, n, :vk_i)[i]
    vc_r = _PM.var(pm, n, :vc_r)[i]
    vc_i = _PM.var(pm, n, :vc_i)[i]

    JuMP.@NLconstraint(pm.model, (iik_r)^2 + (iik_i)^2 <=  imax^2) #(32)
    JuMP.@NLconstraint(pm.model, (iki_r)^2 + (iki_i)^2 <=  imax^2) #(33)
    JuMP.@NLconstraint(pm.model, (ikc_r)^2 + (ikc_i)^2 <=  imax^2) #(34)
    JuMP.@NLconstraint(pm.model, (ick_r)^2 + (ick_i)^2 <=  imax^2) #(35)
    JuMP.@NLconstraint(pm.model, (ic_r)^2 + (ic_i)^2 <=  imax^2) #(39)
    JuMP.@NLconstraint(pm.model, (ic_r)^2 + (ic_i)^2 ==  (iconv_lin)^2) #(47)  
    ## relaxed version 
    #JuMP.@NLconstraint(pm.model, (ic_r)^2 + (ic_i)^2 ==  (iconv_lin)^2) #(49)
    JuMP.@NLconstraint(pm.model, (vk_r)^2 + (vk_i)^2 <=  vmax^2) #(22)
    JuMP.@NLconstraint(pm.model, (vk_r)^2 + (vk_i)^2 >=  vmin^2) #(22)
    JuMP.@NLconstraint(pm.model, (vc_r)^2 + (vc_i)^2 <=  vmax^2) #(23)
    JuMP.@NLconstraint(pm.model, (vc_r)^2 + (vc_i)^2 >=  vmin^2) #(23)


    vc = _PM.var(pm, n, :vdcm)[b_idx]
    pconv_dc = _PM.var(pm, n, :pconv_dc)[i]
    iconv_dc = _PM.var(pm, n, :iconv_dc)[i]

    JuMP.@NLconstraint(pm.model, pconv_dc ==  vc * iconv_dc)
end


######## Constraint converter losses ######
function constraint_converter_losses(pm::_PM.AbstractIVRModel, n::Int, i::Int, a, b, c, plmax)
    iconv_lin = _PM.var(pm, n, :iconv_lin, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)

    JuMP.@NLconstraint(pm.model, pconv_ac + pconv_dc == a + b*iconv_lin + c*(iconv_lin)^2)
end

function constraint_converter_current(pm::_PM.AbstractIVRModel, n::Int, i::Int, Umax, Imax)
    vc_r = _PM.var(pm, n, :vc_r, i)
    vc_i = _PM.var(pm, n, :vc_i, i)
    ic_r = _PM.var(pm, n, :ic_r, i)
    ic_i = _PM.var(pm, n, :ic_i, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)



    JuMP.@NLconstraint(pm.model, pconv_ac == vc_r * ic_r + vc_i * ic_i)
    JuMP.@NLconstraint(pm.model, qconv_ac == vc_i * ic_r - vc_r * ic_i)
end

function constraint_conv_transformer(pm::_PM.AbstractIVRModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    vi_r = _PM.var(pm, n, :vr, acbus)
    vi_i = _PM.var(pm, n, :vi, acbus)
    vk_r = _PM.var(pm, n, :vk_r, i)
    vk_i = _PM.var(pm, n, :vk_i, i)

    iik_r = _PM.var(pm, n, :iik_r, i)
    iik_i = _PM.var(pm, n, :iik_i, i)
    iki_r = _PM.var(pm, n, :iki_r, i)
    iki_i = _PM.var(pm, n, :iki_i, i)

    #TODO add transformation ratio.....
    if transformer
        JuMP.@constraint(pm.model, vk_r == vi_r - rtf * iik_r + xtf * iik_i) #(24)
        JuMP.@constraint(pm.model, vk_i == vi_i - rtf * iik_i - xtf * iik_r) #(25)
        JuMP.@constraint(pm.model, vi_r == vk_r - rtf * iki_r + xtf * iki_i) #reverse
        JuMP.@constraint(pm.model, vi_i == vk_i - rtf * iki_i - xtf * iki_r) #reverse
    else
        JuMP.@constraint(pm.model, vk_r == vi_r)
        JuMP.@constraint(pm.model, vk_i == vi_i)
        JuMP.@constraint(pm.model, iik_r + iki_r == 0)
        JuMP.@constraint(pm.model, iik_i + iki_i == 0)
    end
end

function constraint_conv_reactor(pm::_PM.AbstractIVRModel, n::Int, i::Int, rc, xc, reactor)
    vk_r = _PM.var(pm, n, :vk_r, i)
    vk_i = _PM.var(pm, n, :vk_i, i)
    vc_r = _PM.var(pm, n, :vc_r, i)
    vc_i = _PM.var(pm, n, :vc_i, i)

    ikc_r = _PM.var(pm, n, :ikc_r, i)
    ikc_i = _PM.var(pm, n, :ikc_i, i)
    ick_r = _PM.var(pm, n, :ick_r, i)
    ick_i = _PM.var(pm, n, :ick_i, i)
    ic_r = _PM.var(pm, n, :ic_r, i)
    ic_i = _PM.var(pm, n, :ic_i, i)

    JuMP.@constraint(pm.model, ick_r + ic_r == 0) #(20)
    JuMP.@constraint(pm.model, ick_i + ic_i == 0) #(21)

    if reactor
        JuMP.@constraint(pm.model, vc_r == vk_r - rc * ikc_r + xc * ikc_i) #(28)
        JuMP.@constraint(pm.model, vc_i == vk_i - rc * ikc_i - xc * ikc_r) #(29)
        JuMP.@constraint(pm.model, vk_r == vc_r - rc * ick_r + xc * ick_i) #reverse
        JuMP.@constraint(pm.model, vk_i == vc_i - rc * ick_i - xc * ick_r) #reverse
    else
        JuMP.@constraint(pm.model, vk_r == vc_r)
        JuMP.@constraint(pm.model, vk_i == vc_i)
        JuMP.@constraint(pm.model, ikc_r + ick_r == 0)
        JuMP.@constraint(pm.model, ikc_i + ick_i == 0)
    end
end

function constraint_conv_filter(pm::_PM.AbstractIVRModel, n::Int, i::Int, bv, filter)
    iki_r = _PM.var(pm, n, :iki_r, i)
    iki_i = _PM.var(pm, n, :iki_i, i)
    ikc_r = _PM.var(pm, n, :ikc_r, i)
    ikc_i = _PM.var(pm, n, :ikc_i, i)

    vk_r = _PM.var(pm, n, :vk_r, i)
    vk_i = _PM.var(pm, n, :vk_i, i)

    JuMP.@constraint(pm.model,   iki_r + ikc_r + bv * filter * vk_i == 0)
    JuMP.@constraint(pm.model,   iki_i + ikc_i - bv * filter * vk_r == 0)
end

################# Kicrchhoff's current law ############################################

function constraint_current_balance_ac(pm::_PM.AbstractIVRModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, bus_pd, bus_qd, bus_gs, bus_bs)
    vr = _PM.var(pm, n, :vr, i)
    vi = _PM.var(pm, n, :vi, i)

    cr =  _PM.var(pm, n, :cr)
    ci =  _PM.var(pm, n, :ci)
    cidc = _PM.var(pm, n, :cidc)

    iik_r = _PM.var(pm, n, :iik_r)
    iik_i = _PM.var(pm, n, :iik_i)

    crg = _PM.var(pm, n, :crg)
    cig = _PM.var(pm, n, :cig)

    JuMP.@NLconstraint(pm.model, sum(cr[a] for a in bus_arcs) + sum(iik_r[c] for c in bus_convs_ac)
                                ==
                                sum(crg[g] for g in bus_gens)
                                - (sum(pd for pd in values(bus_pd))*vr + sum(qd for qd in values(bus_qd))*vi)/(vr^2 + vi^2)
                                - sum(gs for gs in values(bus_gs))*vr + sum(bs for bs in values(bus_bs))*vi 
                                )
    JuMP.@NLconstraint(pm.model, sum(ci[a] for a in bus_arcs) + sum(iik_i[c] for c in bus_convs_ac)
                                + sum(cidc[d] for d in bus_arcs_dc)
                                ==
                                sum(cig[g] for g in bus_gens)
                                - (sum(pd for pd in values(bus_pd))*vi - sum(qd for qd in values(bus_qd))*vr)/(vr^2 + vi^2)
                                - sum(gs for gs in values(bus_gs))*vi - sum(bs for bs in values(bus_bs))*vr 
                                )
end