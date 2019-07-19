"All converter variables"
function variable_dc_converter(pm::GenericPowerModel; kwargs...)
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

function variable_conv_tranformer_flow(pm::GenericPowerModel; kwargs...)
    variable_conv_transformer_active_power_to(pm; kwargs...)
    variable_conv_transformer_reactive_power_to(pm; kwargs...)
end

function variable_conv_reactor_flow(pm::GenericPowerModel; kwargs...)
    variable_conv_reactor_active_power_from(pm; kwargs...)
    variable_conv_reactor_reactive_power_from(pm; kwargs...)
end

"variable: `pconv_ac[j]` for `j` in `convdc`"
function variable_converter_active_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_ac] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_ac",
        lower_bound = PowerModels.ref(pm, nw, :convdc, i, "Pacmin", cnd),
        upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Pacmax", cnd),
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_ac] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_ac",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    end
end

"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_converter_reactive_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:qconv_ac] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_qconv_ac",
        lower_bound = PowerModels.ref(pm, nw, :convdc, i, "Qacmin", cnd),
        upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Qacmax", cnd),
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:qconv_ac] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_qconv_ac",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    end
end


"variable: `pconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_active_power_to(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_tf_to] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_tf_to",
        lower_bound = -PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        upper_bound =  PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_tf_to] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_tf_to",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    end
end

"variable: `qconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_reactive_power_to(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:qconv_tf_to] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_qconv_tf_to",
        lower_bound = -PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        upper_bound =  PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:qconv_tf_to] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_qconv_tf_to",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    end
end


"variable: `pconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_active_power_from(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_pr_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_pr_fr",
        lower_bound = -PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        upper_bound =  PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_pr_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_pr_fr",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    end
end

"variable: `qconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_reactive_power_from(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:qconv_pr_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_qconv_pr_fr",
        lower_bound = -PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        upper_bound =  PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:qconv_pr_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_qconv_pr_fr",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    end
end



"variable: `pconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_active_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_tf_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_tf_fr",
        lower_bound = -PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        upper_bound =  PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_tf_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_tf_fr",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    end
end

"variable: `qconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_reactive_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:qconv_tf_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_qconv_tf_fr",
        lower_bound = -PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        upper_bound =  PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:qconv_tf_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_qconv_tf_fr",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    end
end


"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # to account for losses, maximum losses to be derived
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_dc] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_dc",
        lower_bound = -PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        upper_bound =  PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pdcset", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_dc] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_pconv_dc",
        start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pdcset", cnd, 1.0)
        )
    end
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_converter_firing_angle(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:phiconv] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_phiconv",
        lower_bound = 0,
        upper_bound = pi,
        start = acos(PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pdcset", cnd, 1.0) / sqrt((PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pacrated", cnd, 1.0))^2 + (PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Qacrated", cnd, 1.0))^2))
        )
    else
        PowerModels.var(pm, nw, cnd)[:phiconv] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_phiconv",
        start = acos(PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pdcset", cnd, 1.0) / sqrt((PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Pacrated", cnd, 1.0))^2 + (PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "Qacrated", cnd, 1.0))^2))
        )
    end
end

"variable: `iconv_ac[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    PowerModels.var(pm, nw, cnd)[:iconv_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_iconv_ac",
    lower_bound = 0,
    upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd),
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
    )
end

"variable: `iconv_ac[j]` and `iconv_ac_sq[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel{T}; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true) where {T <: PowerModels.AbstractWForms}
    PowerModels.var(pm, nw, cnd)[:iconv_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_iconv_ac",
    lower_bound = 0,
    upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd),
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
    )
    PowerModels.var(pm, nw, cnd)[:iconv_ac_sq] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_iconv_ac_sq",
    lower_bound = 0,
    upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd)^2,
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
    )
end

"variable: `itf_sq[j]` for `j` in `convdc`"
function variable_conv_transformer_current_sqr(pm::GenericPowerModel{T}; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true) where {T <: PowerModels.AbstractWForms}
    bigM = 2; #TODO derive exact bound
    PowerModels.var(pm, nw, cnd)[:itf_sq] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_itf_sq",
    lower_bound = 0,
    upper_bound = (bigM * PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd))^2,
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)^2
    )
end


"variable: `irc_sq[j]` for `j` in `convdc`"
function variable_conv_reactor_current_sqr(pm::GenericPowerModel{T}; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true) where {T <: PowerModels.AbstractWForms}
    bigM = 2; #TODO derive exact bound
    PowerModels.var(pm, nw, cnd)[:irc_sq] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_irc_sq",
    lower_bound = 0,
    upper_bound = (bigM * PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd))^2,
    start = PowerModels.comp_start_value(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)^2
    )
end


function variable_converter_filter_voltage(pm::GenericPowerModel; kwargs...)
    variable_converter_filter_voltage_magnitude(pm; kwargs...)
    variable_converter_filter_voltage_angle(pm; kwargs...)
end


"variable: `vmf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    PowerModels.var(pm, nw, cnd)[:vmf] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_vmf",
    lower_bound = PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd) / bigM,
    upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM,
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar", cnd)
    )
end


"variable: `vaf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_angle(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2*pi; #
    PowerModels.var(pm, nw, cnd)[:vaf] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_vaf",
    lower_bound = -bigM,
    upper_bound =  bigM,
    start = 0
    )
end


function variable_converter_internal_voltage(pm::GenericPowerModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end


"variable: `vmc[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    PowerModels.var(pm, nw, cnd)[:vmc] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_vmc",
    lower_bound = PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd),
    upper_bound = PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd),
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar", cnd)
    )
end

"variable: `vac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_angle(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2*pi; #
    PowerModels.var(pm, nw, cnd)[:vac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_vac",
    lower_bound = -bigM,
    upper_bound =  bigM,
    start = 0
    )
end



"variable: `wrf_ac[j]` and `wif_ac`  for `j` in `convdc`"
function variable_converter_filter_voltage_cross_products(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    PowerModels.var(pm, nw, cnd)[:wrf_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_wrf_ac",
    lower_bound = 0,
    upper_bound = (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar", cnd)^2
    )
    PowerModels.var(pm, nw, cnd)[:wif_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_wif_ac",
    lower_bound = -(PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    upper_bound =  (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar", cnd)^2
    )
end

"variable: `wf_ac` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude_sqr(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    PowerModels.var(pm, nw, cnd)[:wf_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_wf_ac",
    lower_bound =  (PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd) / bigM)^2,
    upper_bound =  (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar", cnd)^2
    )
end


"variable: `wrc_ac[j]` and `wic_ac[j]`  for `j` in `convdc`"
function variable_converter_internal_voltage_cross_products(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    PowerModels.var(pm, nw, cnd)[:wrc_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_wrc_ac",
    lower_bound =  0,
    upper_bound =  (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar", cnd)^2
    )
    PowerModels.var(pm, nw, cnd)[:wic_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_wic_ac",
    lower_bound =  -(PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    upper_bound =   (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar", cnd)^2
    )
end

"variable: `wc_ac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude_sqr(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    PowerModels.var(pm, nw, cnd)[:wc_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], base_name="$(nw)_$(cnd)_wc_ac",
    lower_bound =  PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd)^2,
    upper_bound =  PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd)^2,
    start = PowerModels.ref(pm, nw, :convdc, i, "Vtar", cnd)^2
    )
end
