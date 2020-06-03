function constraint_converter_losses(pm::_PM.AbstractLPACModel, n::Int, i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    iconv = _PM.var(pm, n, :iconv_ac, i)

    # _PM.con(pm, n, :conv_loss)[i] = JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv)
end

function constraint_conv_transformer(pm::_PM.AbstractLPACModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)

    phi = _PM.var(pm, n, :phi, acbus)
    phi_vmf = _PM.var(pm, n, :phi_vmf, i)
    va = _PM.var(pm, n, :va, acbus)
    vaf = _PM.var(pm, n, :vaf, i)
    cs = _PM.var(pm, n, :cs_vaf,i)

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        c1, c2, c3, c4 = lpac_power_flow_constraints(pm.model, gtf, btf, phi, phi_vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm, cs)
        c5 = constraint_cos_angle_diff_PWL(pm, n, cs, va, vaf)
        # _PM.con(pm, n, :conv_tf_p_fr)[i] = c1
        # _PM.con(pm, n, :conv_tf_q_fr)[i] = c2
        # _PM.con(pm, n, :conv_tf_p_to)[i] = c3
        # _PM.con(pm, n, :conv_tf_q_to)[i] = c4
    else
        # _PM.con(pm, n, :conv_tf_p_fr)[i] = JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        # _PM.con(pm, n, :conv_tf_q_fr)[i] = JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, va == vaf)
        JuMP.@constraint(pm.model, (1+phi) == (1+phi_vmf))
    end
end

"constraints for a voltage magnitude transformer + series impedance"

function lpac_power_flow_constraints(model, g, b, phi_fr, phi_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm, cs)

    c1 = JuMP.@constraint(model, p_fr ==  g/(tm^2)*(1.0 + 2*phi_fr) + (-g/tm)*(cs + phi_fr + phi_to) + (-b/tm)*(va_fr-va_to))
    c2 = JuMP.@constraint(model, q_fr == -b/(tm^2)*(1.0 + 2*phi_fr) - (-b/tm)*(cs + phi_fr + phi_to) + (-g/tm)*(va_fr-va_to))
    c3 = JuMP.@constraint(model, p_to ==  g*(1.0 + 2*phi_to) + (-g/tm)*(cs + phi_fr + phi_to) + (-b/tm)*-(va_fr-va_to))
    c4 = JuMP.@constraint(model, q_to == -b*(1.0 + 2*phi_to) - (-b/tm)*(cs + phi_fr + phi_to) + (-g/tm)*-(va_fr-va_to))
    return c1, c2, c3, c4
end


function constraint_conv_reactor(pm::_PM.AbstractLPACModel, n::Int, i::Int, rc, xc, reactor)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)
    ppr_to = -_PM.var(pm, n, :pconv_ac, i)
    qpr_to = -_PM.var(pm, n, :qconv_ac, i)
    phi_vmc = _PM.var(pm, n, :phi_vmc, i)
    phi_vmf = _PM.var(pm, n, :phi_vmf, i)
    vac = _PM.var(pm, n, :vac, i)
    vaf = _PM.var(pm, n, :vaf, i)
    cs = _PM.var(pm, n, :cs_vac,i)

    phi_vmc_ub = JuMP.upper_bound(phi_vmc)
    ppr_to_ub = JuMP.upper_bound(_PM.var(pm, n)[:pconv_ac][i])
    qpr_to_ub = JuMP.upper_bound(_PM.var(pm, n)[:qconv_ac][i])
    Smax = sqrt(ppr_to_ub^2 + qpr_to_ub^2)
    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        c1, c2, c3, c4 = lpac_power_flow_constraints(pm.model, gc, bc, phi_vmf, phi_vmc, vaf, vac, ppr_fr, ppr_to, qpr_fr, qpr_to, 1, cs)
        c5 = constraint_cos_angle_diff_PWL(pm, n, cs, vaf, vac)
        # _PM.con(pm, n, :conv_pr_p)[i] = c3
        # _PM.con(pm, n, :conv_pr_q)[i] = c4
        c6 = constraint_conv_capacity_PWL(pm, n, ppr_to, qpr_to, ppr_to_ub, qpr_to_ub, Smax)
   else
        # _PM.con(pm, n, :conv_pr_p)[i] = JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        # _PM.con(pm, n, :conv_pr_q)[i] = JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, (1+phi_vmf) == (1+phi_vmc))

    end
end

function constraint_conv_filter(pm::_PM.AbstractLPACModel, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)
    phi_vmf = _PM.var(pm, n, :phi_vmf, i)

    # _PM.con(pm, n, :conv_kcl_p)[i] = JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0 )
    # _PM.con(pm, n, :conv_kcl_q)[i] = JuMP.@constraint(pm.model, qpr_fr + qtf_to + -bv*filter*(1+2*phi_vmf) == 0)
    JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0 )
    JuMP.@constraint(pm.model, qpr_fr + qtf_to + -bv*filter*(1+2*phi_vmf) == 0)
end


function constraint_converter_current(pm::_PM.AbstractLPACModel, n::Int, i::Int, Umax, Imax)
    phi_vmc = _PM.var(pm, n, :phi_vmc, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)
    iconv = _PM.var(pm, n, :iconv_ac, i)

    JuMP.@constraint(pm.model, iconv <= Imax)
end


function variable_converter_filter_voltage(pm::_PM.AbstractLPACModel; kwargs...)
    variable_converter_filter_voltage_magnitude(pm; kwargs...)
    variable_converter_filter_voltage_angle_cs(pm; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end

function variable_converter_internal_voltage(pm::_PM.AbstractLPACModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle_cs(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end

function variable_converter_filter_voltage_angle_cs(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true, report = true)
    csvaf = _PM.var(pm, nw)[:cs_vaf] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_cs_vaf",
    start = 0
    )
    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(csvaf[c],  0)
            JuMP.set_upper_bound(csvaf[c],  1)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :cs_vaf, _PM.ids(pm, nw, :convdc), csvaf)
end

function variable_converter_internal_voltage_angle_cs(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true, report = true)
    csvac = _PM.var(pm, nw)[:cs_vac] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_cs_vac",
    start = 0
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(csvac[c],  0)
            JuMP.set_upper_bound(csvac[c],  1)
        end
    end

    report && _IM.sol_component_value(pm, nw, :convdc, :cs_vac, _PM.ids(pm, nw, :convdc), csvac)
end

function variable_converter_filter_voltage_magnitude(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true, report = true)
    phivmf = _PM.var(pm, nw)[:phi_vmf] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_phi_vmf",
            start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "phi_start")
        )

        if bounded
            for (c, convdc) in _PM.ref(pm, nw, :convdc)
                JuMP.set_lower_bound(phivmf[c],  convdc["Vmmin"] - 1.0)
                JuMP.set_upper_bound(phivmf[c],  convdc["Vmmax"] - 1.0)
            end
        end

        report && _IM.sol_component_value(pm, nw, :convdc, :phi_vmf, _PM.ids(pm, nw, :convdc), phivmf)
end

function variable_converter_internal_voltage_magnitude(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true, report = true)
    phivmc = _PM.var(pm, nw)[:phi_vmc] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_phi_vmc",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "phi_start")
        )

        if bounded
            for (c, convdc) in _PM.ref(pm, nw, :convdc)
                JuMP.set_lower_bound(phivmc[c],  convdc["Vmmin"] - 1.0)
                JuMP.set_upper_bound(phivmc[c],  convdc["Vmmax"] - 1.0)
            end
        end

        report && _IM.sol_component_value(pm, nw, :convdc, :phi_vmc, _PM.ids(pm, nw, :convdc), phivmc)
end

function constraint_conv_capacity_PWL(pm::_PM.AbstractLPACModel, n::Int, ppr_to, qpr_to, Umax, Imax, Smax)
    np = 20 #no. of segments, can be passed as an argument later
    l = 0
    for i = 1:np
        a= Smax*sin(l)
        b = Smax*cos(l)
        c6 = JuMP.@constraint(pm.model, a*ppr_to + b*qpr_to <= Smax^2) #current and voltage bounds to be proper to use Umax*Imax because Umax*Imax == Smax
        l = l + 2*pi/np
    end
end

function constraint_cos_angle_diff_PWL(pm::_PM.AbstractLPACModel, n::Int, cs, va_fr, va_to)
    nb = 20 #no. of segments, can be passed as an argument later
    l = -pi/6
    h = pi/6
    inc = (h-l)/(nb+1)
    a = l + inc
    diff = va_fr - va_to
    for i = 1:nb
        c5 = JuMP.@constraint(pm.model, cs <= -sin(a)*(diff-a) + cos(a))
        a = a + inc
    end
end

function add_dcconverter_voltage_setpoint(sol, pm::_PM.AbstractLPACModel)
    _PM.add_setpoint!(sol, pm, "convdc", "vmconv", :phi_vmc, status_name="islcc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
    _PM.add_setpoint!(sol, pm, "convdc", "vmfilt", :phi_vmf, status_name="islcc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
    _PM.add_setpoint!(sol, pm, "convdc", "vaconv", :vac, status_name="islcc", inactive_status_value = 4)
    _PM.add_setpoint!(sol, pm, "convdc", "vafilt", :vaf, status_name="islcc", inactive_status_value = 4)
end



############ TNEP constraints ###############
function constraint_converter_losses_ne(pm::_PM.AbstractLPACModel, n::Int, i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne, i)
    iconv = _PM.var(pm, n, :iconv_ac_ne, i)
    z = _PM.var(pm, n, :conv_ne, i)

    JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a*z + b*iconv)
end

function constraint_conv_transformer_ne(pm::_PM.AbstractLPACModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr_ne, i)
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to_ne, i)

    phi = _PM.var(pm, n, :phi, acbus)
    phi_du = _PM.var(pm, n, :phi_du, i)
    phi_vmf = _PM.var(pm, n, :phi_vmf_ne, i)
    va = _PM.var(pm, n, :va, acbus)
    va_du = _PM.var(pm, n, :va_du, i)
    JuMP.set_upper_bound(va, pi/2)
    JuMP.set_lower_bound(va, -pi/2)
    vaf = _PM.var(pm, n, :vaf_ne, i)
    cs = _PM.var(pm, n, :cs_vaf_ne,i)
    z = _PM.var(pm, n, :conv_ne)[i]

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        c1, c2, c3, c4 = lpac_power_flow_constraints(pm.model, gtf, btf, phi_du, phi_vmf, va_du, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm, cs, z)
        c5 = constraint_cos_angle_diff_PWL(pm, n, cs, va, vaf)
        # _PM.con(pm, n, :conv_tf_p_fr_ne)[i] = c1
        # _PM.con(pm, n, :conv_tf_q_fr_ne)[i] = c2
        # _PM.con(pm, n, :conv_tf_p_to_ne)[i] = c3
        # _PM.con(pm, n, :conv_tf_q_to_ne)[i] = c4
        relaxation_semicont_variable_on_off(pm.model, cs, z) # cos not yet semicont. but once put ub and lb acc. to angle difference, it can be semi-cont
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, va_du == vaf)
        JuMP.@constraint(pm.model, (1*z+phi_du) == (1*z+phi_vmf))
    end

    relaxation_variable_on_off(pm.model, phi, phi_du, z)
    _IM.relaxation_equality_on_off(pm.model, phi, phi_du, z)

    relaxation_variable_on_off(pm.model, va, va_du, z)
    _IM.relaxation_equality_on_off(pm.model, va, va_du, z)

    relaxation_semicont_variable_on_off(pm.model, phi_vmf, z)
    relaxation_semicont_variable_on_off(pm.model, vaf, z)
end

"constraints for a voltage magnitude transformer + series impedance"

function lpac_power_flow_constraints(model, g, b, phi_fr, phi_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm, cs, z)

    c1 = JuMP.@constraint(model, p_fr ==  g/(tm^2)*(1.0*z + 2*phi_fr) + (-g/tm)*(cs + phi_fr + phi_to) + (-b/tm)*(va_fr-va_to))
    c2 = JuMP.@constraint(model, q_fr == -b/(tm^2)*(1.0*z + 2*phi_fr) - (-b/tm)*(cs + phi_fr + phi_to) + (-g/tm)*(va_fr-va_to))
    c3 = JuMP.@constraint(model, p_to ==  g*(1.0*z + 2*phi_to) + (-g/tm)*(cs + phi_fr + phi_to) + (-b/tm)*-(va_fr-va_to))
    c4 = JuMP.@constraint(model, q_to == -b*(1.0*z + 2*phi_to) - (-b/tm)*(cs + phi_fr + phi_to) + (-g/tm)*-(va_fr-va_to))
    return c1, c2, c3, c4
end


function constraint_conv_reactor_ne(pm::_PM.AbstractLPACModel, n::Int, i::Int, rc, xc, reactor)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr_ne, i)
    ppr_to = -_PM.var(pm, n, :pconv_ac_ne, i)
    qpr_to = -_PM.var(pm, n, :qconv_ac_ne, i)
    phi_vmc = _PM.var(pm, n, :phi_vmc_ne, i)
    phi_vmf = _PM.var(pm, n, :phi_vmf_ne, i)
    vac = _PM.var(pm, n, :vac_ne, i)
    vaf = _PM.var(pm, n, :vaf_ne, i)
    cs = _PM.var(pm, n, :cs_vac_ne,i)
    z = _PM.var(pm, n, :conv_ne)[i]


    phi_vmc_ub = JuMP.upper_bound(phi_vmc)
    ppr_to_ub = JuMP.upper_bound(_PM.var(pm, n)[:pconv_ac_ne][i])
    qpr_to_ub = JuMP.upper_bound(_PM.var(pm, n)[:qconv_ac_ne][i])
    Smax = sqrt(ppr_to_ub^2 + qpr_to_ub^2)
    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        c1, c2, c3, c4 = lpac_power_flow_constraints(pm.model, gc, bc, phi_vmf, phi_vmc, vaf, vac, ppr_fr, ppr_to, qpr_fr, qpr_to, 1, cs, z)
        c5 = constraint_cos_angle_diff_PWL(pm, n, cs, vaf, vac)
        # _PM.con(pm, n, :conv_pr_p_ne)[i] = c3
        # _PM.con(pm, n, :conv_pr_q_ne)[i] = c4
        relaxation_semicont_variable_on_off(pm.model, cs, z) # cos not yet semicont. but once put ub and lb acc. to angle difference, it can be semi-cont
    else
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, vac == vaf)
        JuMP.@constraint(pm.model, (1*z+phi_vmf) == (1*z+phi_vmc))
   end
    c6 = constraint_conv_capacity_PWL(pm, n, ppr_to, qpr_to, ppr_to_ub, qpr_to_ub, Smax)
    relaxation_semicont_variable_on_off(pm.model, phi_vmc, z)
    relaxation_semicont_variable_on_off(pm.model, vac, z)
end

function constraint_conv_filter_ne(pm::_PM.AbstractLPACModel, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to_ne, i)
    phi_vmf = _PM.var(pm, n, :phi_vmf_ne, i)
    z = _PM.var(pm, n, :conv_ne)[i]

    JuMP.@constraint(pm.model, ppr_fr + ptf_to == 0 )
    JuMP.@constraint(pm.model, qpr_fr + qtf_to + -bv*filter*(1*z+2*phi_vmf) == 0)
end


function constraint_converter_current_ne(pm::_PM.AbstractLPACModel, n::Int, i::Int, Umax, Imax)
    phi_vmc = _PM.var(pm, n, :phi_vmc_ne, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne, i)
    iconv = _PM.var(pm, n, :iconv_ac_ne, i)
    # @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (1.0+phi_vmc)^2 * (iconv)^2)
    JuMP.@constraint(pm.model, iconv <= Imax)
end


function variable_converter_filter_voltage_ne(pm::_PM.AbstractLPACModel; kwargs...)
    variable_converter_filter_voltage_magnitude_ne(pm; kwargs...)
    variable_converter_filter_voltage_angle_cs_ne(pm; kwargs...)
    variable_converter_filter_voltage_angle_ne(pm; kwargs...)
end

function variable_converter_internal_voltage_ne(pm::_PM.AbstractLPACModel; kwargs...)
    variable_converter_internal_voltage_magnitude_ne(pm; kwargs...)
    variable_converter_internal_voltage_angle_cs_ne(pm; kwargs...)
    variable_converter_internal_voltage_angle_ne(pm; kwargs...)
end

function variable_converter_filter_voltage_angle_cs_ne(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true)
    _PM.var(pm, nw)[:cs_vaf_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_cs_vaf_ne",
    lower_bound =  0, # using the maximum bound allowed in cosine linearization. can be changed to bus angle +/- 10 degree?
    upper_bound =  1,
    start = 0
    )
end

function variable_converter_internal_voltage_angle_cs_ne(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true)
    _PM.var(pm, nw)[:cs_vac_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_cs_vac_ne",
    lower_bound =  0, # using the maximum bound allowed in cosine linearization. can be changed to bus angle +/- 10 degree?
    upper_bound =  1,
    start = 0
    )
end

function variable_converter_filter_voltage_magnitude_ne(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true)
    _PM.var(pm, nw)[:phi_vmf_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_phi_vmf_ne",
    lower_bound = _PM.ref(pm, nw, :convdc_ne, i, "Vmmin") - 1.0,
    upper_bound = _PM.ref(pm, nw, :convdc_ne, i, "Vmmax") - 1.0,
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "phi_start")
    )
end

function variable_converter_internal_voltage_magnitude_ne(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true)
    _PM.var(pm, nw)[:phi_vmc_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_phi_vmc_ne",
    lower_bound = _PM.ref(pm, nw, :convdc_ne, i, "Vmmin") - 1.0,
    upper_bound = _PM.ref(pm, nw, :convdc_ne, i, "Vmmax") - 1.0,
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc_ne, i), "phi_start")
    )
end

function variable_voltage_slack(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded::Bool = true)
    _PM.var(pm, nw)[:phi_du] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_phi_du",
    lower_bound = -0.2,
    upper_bound = 0.2,
    start = 0,
    )
    _PM.var(pm, nw)[:va_du] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc_ne)], base_name="$(nw)_va_du",
    lower_bound = -2*pi,
    upper_bound = 2*pi,
    start = 0,
    )
end


function add_dcconverter_voltage_setpoint_ne(sol, pm::_PM.AbstractLPACModel)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "vmconv", :phi_vmc_ne, status_name="islcc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "vmfilt", :phi_vmf_ne, status_name="islcc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "vaconv", :vac_ne, status_name="islcc", inactive_status_value = 4)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "vafilt", :vaf_ne, status_name="islcc", inactive_status_value = 4)

end
