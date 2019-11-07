function constraint_converter_losses(pm::AbstractLPACModel, n::Int, cnd::Int, i::Int, a, b, c, plmax)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    pconv_dc = PowerModels.var(pm, n, cnd, :pconv_dc, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)

    PowerModels.con(pm, n, cnd, :conv_loss)[i] = @constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv)
end

function constraint_conv_transformer(pm::AbstractLPACModel, n::Int, cnd::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = PowerModels.var(pm, n, cnd, :pconv_tf_fr, i)
    qtf_fr = PowerModels.var(pm, n, cnd, :qconv_tf_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)
    qtf_to = PowerModels.var(pm, n, cnd, :qconv_tf_to, i)

    phi = PowerModels.var(pm, n, cnd, :phi, acbus)
    phi_vmf = PowerModels.var(pm, n, cnd, :phi_vmf, i)
    va = PowerModels.var(pm, n, cnd, :va, acbus)
    vaf = PowerModels.var(pm, n, cnd, :vaf, i)
    cs = PowerModels.var(pm, n, cnd, :cs_vaf,i)

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        c1, c2, c3, c4 = lpac_power_flow_constraints(pm.model, gtf, btf, phi, phi_vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to, tm, cs)
        c5 = constraint_cos_angle_diff_PWL(pm, n, cnd, cs, va, vaf)
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = c1
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = c2
        PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = c3
        PowerModels.con(pm, n, cnd, :conv_tf_q_to)[i] = c4
    else
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = @constraint(pm.model, ptf_fr + ptf_to == 0)
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = @constraint(pm.model, qtf_fr + qtf_to == 0)
        @constraint(pm.model, va == vaf)
        @constraint(pm.model, (1+phi) == (1+phi_vmf))
    end
end

"constraints for a voltage magnitude transformer + series impedance"

function lpac_power_flow_constraints(model, g, b, phi_fr, phi_to, va_fr, va_to, p_fr, p_to, q_fr, q_to, tm, cs)

    c1 = @constraint(model, p_fr ==  g/(tm^2)*(1.0 + 2*phi_fr) + (-g/tm)*(cs + phi_fr + phi_to) + (-b/tm)*(va_fr-va_to))
    c2 = @constraint(model, q_fr == -b/(tm^2)*(1.0 + 2*phi_fr) - (-b/tm)*(cs + phi_fr + phi_to) + (-g/tm)*(va_fr-va_to))
    c3 = @constraint(model, p_to ==  g*(1.0 + 2*phi_to) + (-g/tm)*(cs + phi_fr + phi_to) + (-b/tm)*-(va_fr-va_to))
    c4 = @constraint(model, q_to == -b*(1.0 + 2*phi_to) - (-b/tm)*(cs + phi_fr + phi_to) + (-g/tm)*-(va_fr-va_to))
    return c1, c2, c3, c4
end


function constraint_conv_reactor(pm::AbstractLPACModel, n::Int, cnd::Int, i::Int, rc, xc, reactor)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    qpr_fr = PowerModels.var(pm, n, cnd, :qconv_pr_fr, i)
    ppr_to = -PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qpr_to = -PowerModels.var(pm, n, cnd, :qconv_ac, i)
    phi_vmc = PowerModels.var(pm, n, cnd, :phi_vmc, i)
    phi_vmf = PowerModels.var(pm, n, cnd, :phi_vmf, i)
    vac = PowerModels.var(pm, n, cnd, :vac, i)
    vaf = PowerModels.var(pm, n, cnd, :vaf, i)
    cs = PowerModels.var(pm, n, cnd, :cs_vac,i)

    phi_vmc_ub = JuMP.upper_bound(phi_vmc)
    ppr_to_ub = JuMP.upper_bound(PowerModels.var(pm, n, cnd)[:pconv_ac][i])
    qpr_to_ub = JuMP.upper_bound(PowerModels.var(pm, n, cnd)[:qconv_ac][i])
    Smax = sqrt(ppr_to_ub^2 + qpr_to_ub^2)
    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        c1, c2, c3, c4 = lpac_power_flow_constraints(pm.model, gc, bc, phi_vmf, phi_vmc, vaf, vac, ppr_fr, ppr_to, qpr_fr, qpr_to, 1, cs)
        c5 = constraint_cos_angle_diff_PWL(pm, n, cnd, cs, vaf, vac)
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = c3
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = c4
        c6 = constraint_conv_capacity_PWL(pm, n, cnd, ppr_to, qpr_to, ppr_to_ub, qpr_to_ub, Smax)
   else
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = @constraint(pm.model, ppr_fr + ppr_to == 0)
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = @constraint(pm.model, qpr_fr + qpr_to == 0)
        @constraint(pm.model, vac == vaf)
        @constraint(pm.model, (1+phi_vmf) == (1+phi_vmc))

    end
end

function constraint_conv_filter(pm::AbstractLPACModel, n::Int, cnd::Int, i::Int, bv, filter)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    qpr_fr = PowerModels.var(pm, n, cnd, :qconv_pr_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)
    qtf_to = PowerModels.var(pm, n, cnd, :qconv_tf_to, i)
    phi_vmf = PowerModels.var(pm, n, cnd, :phi_vmf, i)

    PowerModels.con(pm, n, cnd, :conv_kcl_p)[i] = @constraint(pm.model, ppr_fr + ptf_to == 0 )
    PowerModels.con(pm, n, cnd, :conv_kcl_q)[i] = @constraint(pm.model, qpr_fr + qtf_to + -bv*filter*(1+2*phi_vmf) == 0)
end


function constraint_converter_current(pm::AbstractLPACModel, n::Int, cnd::Int, i::Int, Umax, Imax)
    phi_vmc = PowerModels.var(pm, n, cnd, :phi_vmc, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)

    # PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (1.0+phi_vmc)^2 * (iconv)^2)
    @constraint(pm.model, iconv <= Imax)
end


function variable_converter_filter_voltage(pm::AbstractLPACModel; kwargs...)
    variable_converter_filter_voltage_magnitude(pm; kwargs...)
    variable_converter_filter_voltage_angle_cs(pm; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end

function variable_converter_internal_voltage(pm::AbstractLPACModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle_cs(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end

function variable_converter_filter_voltage_angle_cs(pm::AbstractLPACModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    PowerModels.var(pm, nw, cnd)[:cs_vaf] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_cs_vaf",
    lower_bound =  0, # using the maximum bound allowed in cosine linearization. can be changed to bus angle +/- 10 degree?
    upper_bound =  1,
    start = 0
    )
end

function variable_converter_internal_voltage_angle_cs(pm::AbstractLPACModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    PowerModels.var(pm, nw, cnd)[:cs_vac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_cs_vac",
    lower_bound =  0, # using the maximum bound allowed in cosine linearization. can be changed to bus angle +/- 10 degree?
    upper_bound =  1,
    start = 0
    )
end

function variable_converter_filter_voltage_magnitude(pm::AbstractLPACModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    PowerModels.var(pm, nw, cnd)[:phi_vmf] = JuMP.@variable(pm.model,
            [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_phi_vmf",
            lower_bound = PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd) - 1.0,
            upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) - 1.0,
            start = comp_start_value(ref(pm, nw, :convdc, i), "phi_start", cnd)
        )
end

function variable_converter_internal_voltage_magnitude(pm::AbstractLPACModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
    PowerModels.var(pm, nw, cnd)[:phi_vmc] = JuMP.@variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_phi_vmc",
        lower_bound = PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd) - 1.0,
        upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) - 1.0,
        start = comp_start_value(ref(pm, nw, :convdc, i), "phi_start", cnd)
        )
end

function constraint_conv_capacity_PWL(pm::AbstractLPACModel, n::Int, cnd::Int, ppr_to, qpr_to, Umax, Imax, Smax)
    np = 20 #no. of segments, can be passed as an argument later
    l = 0
    for i = 1:np
        a= Smax*sin(l)
        b = Smax*cos(l)
        c6 = @constraint(pm.model, a*ppr_to + b*qpr_to <= Smax^2) #current and voltage bounds to be proper to use Umax*Imax because Umax*Imax == Smax
        # c6 = @constraint(pm.model, a*ppr_to + b*qpr_to <= (Umax*Imax)^2) #current and voltage bounds to be proper to use Umax*Imax because Umax*Imax == Smax
        l = l + 2*pi/np
    end
end

function constraint_cos_angle_diff_PWL(pm::AbstractLPACModel, n::Int, cnd::Int, cs, va_fr, va_to)
    nb = 20 #no. of segments, can be passed as an argument later
    l = -pi/6
    h = pi/6
    inc = (h-l)/(nb+1)
    a = l + inc
    diff = va_fr - va_to
    for i = 1:nb
        c5 = @constraint(pm.model, cs <= -sin(a)*(diff-a) + cos(a))
        a = a + inc
    end
end


# ## quadratic constraint for cos - used for debugging of PWL of cos
# function constraint_cos_voltage(pm::AbstractLPACModel, n::Int, cnd::Int, cs, va_fr, va_to)
#     vad_max = max(-pi/6,pi/6) # this shoudl be maximum of ac bus angle and converter station (filter, converter) bus angle. since cos is
#     #cosine is taken between maximum and minimum (pi,-pi) at the moment. to be changed in the future
#     c5 = @constraint(pm.model, cs <= 1 - (1-cos(vad_max))/vad_max^2*(va_fr - va_to)^2)
#     return c5
# end


function add_dcconverter_voltage_setpoint(sol, pm::AbstractLPACModel)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vmconv", :phi_vmc, status_name="islcc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vmfilt", :phi_vmf, status_name="islcc", inactive_status_value = 4, scale = (x,item,cnd) -> 1.0+x)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vaconv", :vac, status_name="islcc", inactive_status_value = 4)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vafilt", :vaf, status_name="islcc", inactive_status_value = 4)
end
