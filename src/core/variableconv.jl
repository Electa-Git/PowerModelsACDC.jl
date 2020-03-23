"All converter variables"
function variable_dc_converter(pm::AbstractPowerModel; kwargs...)
    variable_conv_tranformer_flow(pm; kwargs...)
    variable_conv_reactor_flow(pm; kwargs...)

    variable_converter_active_power(pm; kwargs...)
    variable_converter_reactive_power(pm; kwargs...)
    variable_acside_current(pm; kwargs...)
    variable_dcside_power(pm; kwargs...)
    variable_converter_firing_angle(pm; kwargs...)

    variable_converter_filter_voltage(pm; kwargs...)
    variable_converter_internal_voltage(pm; kwargs...)

    variable_converter_to_grid_active_power(pm; kwargs...)
    variable_converter_to_grid_reactive_power(pm; kwargs...)
end

function variable_conv_tranformer_flow(pm::AbstractPowerModel; kwargs...)
    variable_conv_transformer_active_power_to(pm; kwargs...)
    variable_conv_transformer_reactive_power_to(pm; kwargs...)
end

function variable_conv_reactor_flow(pm::AbstractPowerModel; kwargs...)
    variable_conv_reactor_active_power_from(pm; kwargs...)
    variable_conv_reactor_reactive_power_from(pm; kwargs...)
end

"variable: `pconv_ac[j]` for `j` in `convdc`"
function variable_converter_active_power(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    pc = PowerModels.var(pm, nw)[:pconv_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_pconv_ac",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)
    )

    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(pc[c],  convdc["Pacmin"])
            JuMP.set_upper_bound(pc[c],  convdc["Pacmax"])
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :pconv, ids(pm, nw, :convdc), pc)
end

"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_converter_reactive_power(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    qc = PowerModels.var(pm, nw)[:qconv_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_qconv_ac",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", 1.0)
    )

    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(qc[c],  convdc["Qacmin"])
            JuMP.set_upper_bound(qc[c],  convdc["Qacmax"])
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :qconv, ids(pm, nw, :convdc), qc)
end


"variable: `pconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_active_power_to(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    ptfto = PowerModels.var(pm, nw)[:pconv_tf_to] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_pconv_tf_to",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ptfto[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound(ptfto[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :ptf_to, ids(pm, nw, :convdc), ptfto)
end

"variable: `qconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_reactive_power_to(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    qtfto = PowerModels.var(pm, nw)[:qconv_tf_to] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_qconv_tf_to",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(qtfto[c],  -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound(qtfto[c],   convdc["Qacrated"] * bigM)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :qtf_to, ids(pm, nw, :convdc), qtfto)
end


"variable: `pconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_active_power_from(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    pprfr = PowerModels.var(pm, nw)[:pconv_pr_fr] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_pconv_pr_fr",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(pprfr[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound(pprfr[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :ppr_fr, ids(pm, nw, :convdc), pprfr)
end

"variable: `qconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_reactive_power_from(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    qprfr = PowerModels.var(pm, nw)[:qconv_pr_fr] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_qconv_pr_fr",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(qprfr[c],  -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound(qprfr[c],   convdc["Qacrated"] * bigM)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :qpr_fr, ids(pm, nw, :convdc), qprfr)
end

"variable: `pconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_active_power(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    ptffr = PowerModels.var(pm, nw)[:pconv_tf_fr] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_pconv_tf_fr",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ptffr[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound(ptffr[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :ptf_fr, ids(pm, nw, :convdc), ptffr)
end

"variable: `qconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_reactive_power(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    qtffr = PowerModels.var(pm, nw)[:qconv_tf_fr] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_qconv_tf_fr",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(qtffr[c],  -convdc["Qacrated"] * bigM)
            JuMP.set_upper_bound(qtffr[c],   convdc["Qacrated"] * bigM)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :qtf_fr, ids(pm, nw, :convdc), qtffr)
end


"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # to account for losses, maximum losses to be derived
    pcdc = PowerModels.var(pm, nw)[:pconv_dc] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_pconv_dc",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pdcset", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(pcdc[c],  -convdc["Pacrated"] * bigM)
            JuMP.set_upper_bound(pcdc[c],   convdc["Pacrated"] * bigM)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :pdc, ids(pm, nw, :convdc), pcdc)
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_converter_firing_angle(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    phic = PowerModels.var(pm, nw)[:phiconv] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_phiconv",
    start = acos(PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pdcset", 1.0) / sqrt((PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pacrated", 1.0))^2 + (PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Qacrated", 1.0))^2))
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(phic[c],  0)
            JuMP.set_upper_bound(phic[c],  pi)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :phiconv, ids(pm, nw, :convdc), phic)
end

"variable: `iconv_ac[j]` for `j` in `convdc`"
function variable_acside_current(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    ic = PowerModels.var(pm, nw)[:iconv_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_iconv_ac",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ic[c],  0)
            JuMP.set_upper_bound(ic[c],  convdc["Imax"])
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :iconv_ac, ids(pm, nw, :convdc), ic)
end

"variable: `iconv_ac[j]` and `iconv_ac_sq[j]` for `j` in `convdc`"
function variable_acside_current(pm::AbstractWModels; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    ic = PowerModels.var(pm, nw)[:iconv_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_iconv_ac",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    icsq = PowerModels.var(pm, nw)[:iconv_ac_sq] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_iconv_ac_sq",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(ic[c],  0)
            JuMP.set_upper_bound(ic[c],  convdc["Imax"])
            JuMP.set_lower_bound(icsq[c],  0)
            JuMP.set_upper_bound(icsq[c],  convdc["Imax"]^2)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :iconv_ac, ids(pm, nw, :convdc), ic)
    report && PowerModels.sol_component_value(pm, nw, :convdc, :iconv_ac_sq, ids(pm, nw, :convdc), icsq)
end

"variable: `itf_sq[j]` for `j` in `convdc`"
function variable_conv_transformer_current_sqr(pm::AbstractWModels; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2; #TODO derive exact bound
    itfsq = PowerModels.var(pm, nw)[:itf_sq] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_itf_sq",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)^2
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(itfsq[c],  0)
            JuMP.set_upper_bound(itfsq[c], (bigM * convdc["Imax"])^2)
        end
    end
    report && PowerModels.sol_component_value(pm, nw, :convdc, :itf_sq, ids(pm, nw, :convdc), itfsq)
end


"variable: `irc_sq[j]` for `j` in `convdc`"
function variable_conv_reactor_current_sqr(pm::AbstractWModels; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2; #TODO derive exact bound
    iprsq = PowerModels.var(pm, nw)[:irc_sq] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_irc_sq",
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", 1.0)^2
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(iprsq[c],  0)
            JuMP.set_upper_bound(iprsq[c], (bigM * convdc["Imax"])^2)
        end
    end
    report && PowerModels.sol_component_value(pm, nw, :convdc, :ipr_sq, ids(pm, nw, :convdc), iprsq)
end


function variable_converter_filter_voltage(pm::AbstractPowerModel; kwargs...)
    variable_converter_filter_voltage_magnitude(pm; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end


"variable: `vmf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    vmf = PowerModels.var(pm, nw)[:vmf] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_vmf",
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar")
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vmf[c], convdc["Vmmin"] / bigM)
            JuMP.set_upper_bound(vmf[c], convdc["Vmmax"] * bigM)
        end
    end
    report && PowerModels.sol_component_value(pm, nw, :convdc, :vmfilt, ids(pm, nw, :convdc), vmf)
end


"variable: `vaf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_angle(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2*pi; #
    vaf = PowerModels.var(pm, nw)[:vaf] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_vaf",
    start = 0
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vaf[c], -bigM)
            JuMP.set_upper_bound(vaf[c],  bigM)
        end
    end
    report && PowerModels.sol_component_value(pm, nw, :convdc, :vafilt, ids(pm, nw, :convdc), vaf)
end


function variable_converter_internal_voltage(pm::AbstractPowerModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end


"variable: `vmc[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vmc = PowerModels.var(pm, nw)[:vmc] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_vmc",
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar")
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vmc[c], convdc["Vmmin"])
            JuMP.set_upper_bound(vmc[c], convdc["Vmmax"])
        end
    end
    report && PowerModels.sol_component_value(pm, nw, :convdc, :vmconv, ids(pm, nw, :convdc), vmc)
end

"variable: `vac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_angle(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 2*pi; #
    vac = PowerModels.var(pm, nw)[:vac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_vac",
    start = 0
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(vac[c], -bigM)
            JuMP.set_upper_bound(vac[c],  bigM)
        end
    end
    report && PowerModels.sol_component_value(pm, nw, :convdc, :vaconv, ids(pm, nw, :convdc), vac)
end



"variable: `wrf_ac[j]` and `wif_ac`  for `j` in `convdc`"
function variable_converter_filter_voltage_cross_products(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wrfac = PowerModels.var(pm, nw)[:wrf_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_wrf_ac",
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar")^2
    )
    wifac = PowerModels.var(pm, nw)[:wif_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_wif_ac",
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar")^2
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(wrfac[c],  0)
            JuMP.set_upper_bound(wrfac[c],  (convdc["Vmmax"] * bigM)^2)
            JuMP.set_lower_bound(wifac[c], -(convdc["Vmmax"] * bigM)^2)
            JuMP.set_upper_bound(wifac[c],  (convdc["Vmmax"] * bigM)^2)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :wrfilt, ids(pm, nw, :convdc), wrfac)
    report && PowerModels.sol_component_value(pm, nw, :convdc, :wifilt, ids(pm, nw, :convdc), wifac)
end

"variable: `wf_ac` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude_sqr(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wfac = PowerModels.var(pm, nw)[:wf_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_wf_ac",
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar")^2
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(wfac[c], (convdc["Vmmin"] / bigM)^2)
            JuMP.set_upper_bound(wfac[c], (convdc["Vmmax"] * bigM)^2)
        end
    end
    report && PowerModels.sol_component_value(pm, nw, :convdc, :wfilt, ids(pm, nw, :convdc), wfac)
end


"variable: `wrc_ac[j]` and `wic_ac[j]`  for `j` in `convdc`"
function variable_converter_internal_voltage_cross_products(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    wrcac = PowerModels.var(pm, nw)[:wrc_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_wrc_ac",
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar")^2
    )
    wicac = PowerModels.var(pm, nw)[:wic_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_wic_ac",
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar")^2
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(wrcac[c],  0)
            JuMP.set_upper_bound(wrcac[c],  (convdc["Vmmax"] * bigM)^2)
            JuMP.set_lower_bound(wicac[c], -(convdc["Vmmax"] * bigM)^2)
            JuMP.set_upper_bound(wicac[c],  (convdc["Vmmax"] * bigM)^2)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :convdc, :wrconv, ids(pm, nw, :convdc), wrcac)
    report && PowerModels.sol_component_value(pm, nw, :convdc, :wiconv, ids(pm, nw, :convdc), wicac)
end

"variable: `wc_ac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude_sqr(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    wcac = PowerModels.var(pm, nw)[:wc_ac] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_wc_ac",
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar")^2
    )
    if bounded
        for (c, convdc) in ref(pm, nw, :convdc)
            JuMP.set_lower_bound(wcac[c], (convdc["Vmmin"])^2)
            JuMP.set_upper_bound(wcac[c], (convdc["Vmmax"])^2)
        end
    end
    report && PowerModels.sol_component_value(pm, nw, :convdc, :wconv, ids(pm, nw, :convdc), wcac)
end

function variable_cos_voltage(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    #only for lpac
end
