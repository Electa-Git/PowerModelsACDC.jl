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
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_ac",
        lowerbound = PowerModels.ref(pm, nw, :convdc, i, "Pacmin", cnd),
        upperbound = PowerModels.ref(pm, nw, :convdc, i, "Pacmax", cnd)
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_ac] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_ac",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    end
end

"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_converter_reactive_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:qconv_ac] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_qconv_ac",
        lowerbound = PowerModels.ref(pm, nw, :convdc, i, "Qacmin", cnd),
        upperbound = PowerModels.ref(pm, nw, :convdc, i, "Qacmax", cnd)
        )
    else
        PowerModels.var(pm, nw, cnd)[:qconv_ac] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_qconv_ac",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    end
end


"variable: `pconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_active_power_to(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_tf_to] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_tf_to",
        lowerbound = -PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        upperbound =  PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_tf_to] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_tf_to",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    end
end

"variable: `qconv_grid_ac_to[j]` for `j` in `convdc`"
function variable_conv_transformer_reactive_power_to(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:qconv_tf_to] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_qconv_tf_to",
        lowerbound = -PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        upperbound =  PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM
        )
    else
        PowerModels.var(pm, nw, cnd)[:qconv_tf_to] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_qconv_tf_to",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    end
end


"variable: `pconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_active_power_from(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_pr_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_pr_fr",
        lowerbound = -PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        upperbound =  PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_pr_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_pr_fr",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    end
end

"variable: `qconv_pr_from[j]` for `j` in `convdc`"
function variable_conv_reactor_reactive_power_from(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:qconv_pr_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_qconv_pr_fr",
        lowerbound = -PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        upperbound =  PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM
        )
    else
        PowerModels.var(pm, nw, cnd)[:qconv_pr_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_qconv_pr_fr",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    end
end



"variable: `pconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_active_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_tf_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_tf_fr",
        lowerbound = -PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        upperbound =  PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_tf_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_tf_fr",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "P_g", cnd, 1.0)
        )
    end
end

"variable: `qconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_reactive_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2;
    if bounded
        PowerModels.var(pm, nw, cnd)[:qconv_tf_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_qconv_tf_fr",
        lowerbound = -PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM,
        upperbound =  PowerModels.ref(pm, nw, :convdc, i, "Qacrated", cnd) * bigM
        )
    else
        PowerModels.var(pm, nw, cnd)[:qconv_tf_fr] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_qconv_tf_fr",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "Q_g", cnd, 1.0)
        )
    end
end


"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # to account for losses, maximum losses to be derived
    if bounded
        PowerModels.var(pm, nw, cnd)[:pconv_dc] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_dc",
        lowerbound = -PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM,
        upperbound =  PowerModels.ref(pm, nw, :convdc, i, "Pacrated", cnd) * bigM
        )
    else
        PowerModels.var(pm, nw, cnd)[:pconv_dc] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_pconv_dc",
        start = PowerModels.getval(ref(pm, nw, :convdc, i), "Pdcset", cnd, 1.0)
        )
    end
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_converter_firing_angle(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:phiconv] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_phiconv",
        lowerbound = 0,
        upperbound = pi
        )
    else
        PowerModels.var(pm, nw, cnd)[:phiconv] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_phiconv",
        start = acos(PowerModels.getval(ref(pm, nw, :convdc, i), "Pdcset", cnd, 1.0) / sqrt((PowerModels.getval(ref(pm, nw, :convdc, i), "Pacrated", cnd, 1.0))^2 + (PowerModels.getval(ref(pm, nw, :convdc, i), "Pacrated", cnd, 1.0))^2))
        )
    end
end

"variable: `iconv_ac[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    PowerModels.var(pm, nw, cnd)[:iconv_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_iconv_ac",
    lowerbound = 0,
    upperbound = PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd)
    )
end

"variable: `iconv_ac[j]` and `iconv_ac_sq[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel{T}; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true) where {T <: PowerModels.AbstractWForms}
    PowerModels.var(pm, nw, cnd)[:iconv_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_iconv_ac",
    lowerbound = 0,
    upperbound = PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd)
    )
    PowerModels.var(pm, nw, cnd)[:iconv_ac_sq] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_iconv_ac_sq",
    lowerbound = 0,
    upperbound = PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd)^2
    )
end

"variable: `itf_sq[j]` for `j` in `convdc`"
function variable_conv_transformer_current_sqr(pm::GenericPowerModel{T}; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true) where {T <: PowerModels.AbstractWForms}
    bigM = 2; #TODO derive exact bound
    PowerModels.var(pm, nw, cnd)[:itf_sq] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_itf_sq",
    lowerbound = 0,
    upperbound = PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd)^2
    )
end


"variable: `irc_sq[j]` for `j` in `convdc`"
function variable_conv_reactor_current_sqr(pm::GenericPowerModel{T}; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true) where {T <: PowerModels.AbstractWForms}
    bigM = 2; #TODO derive exact bound
    PowerModels.var(pm, nw, cnd)[:irc_sq] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_irc_sq",
    lowerbound = 0,
    upperbound = PowerModels.ref(pm, nw, :convdc, i, "Imax", cnd)^2
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
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_vmf",
    lowerbound = PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd) / bigM,
    upperbound = PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM
    )
end


"variable: `vaf[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_angle(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2*pi; #
    PowerModels.var(pm, nw, cnd)[:vaf] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_vaf",
    lowerbound = -bigM,
    upperbound =  bigM
    )
end


function variable_converter_internal_voltage(pm::GenericPowerModel; kwargs...)
    variable_converter_internal_voltage_magnitude(pm; kwargs...)
    variable_converter_internal_voltage_angle(pm; kwargs...)
end


"variable: `vmc[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    PowerModels.var(pm, nw, cnd)[:vmc] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_vmc",
    lowerbound = PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd),
    upperbound = PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd)
    )
end

"variable: `vac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_angle(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 2*pi; #
    PowerModels.var(pm, nw, cnd)[:vac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_vac",
    lowerbound = -bigM,
    upperbound =  bigM
    )
end



"variable: `wrf_ac[j]` and `wif_ac`  for `j` in `convdc`"
function variable_converter_filter_voltage_cross_products(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    PowerModels.var(pm, nw, cnd)[:wrf_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_wrf_ac",
    lowerbound = 0,
    upperbound = (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2
    )
    PowerModels.var(pm, nw, cnd)[:wif_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_wif_ac",
    lowerbound = -(PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    upperbound =  (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2
    )
end

"variable: `wf_ac` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude_sqr(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    PowerModels.var(pm, nw, cnd)[:wf_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_wf_ac",
    lowerbound =  (PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd) / bigM)^2,
    upperbound =  (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2
    )
end


"variable: `wrc_ac[j]` and `wic_ac[j]`  for `j` in `convdc`"
function variable_converter_internal_voltage_cross_products(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    PowerModels.var(pm, nw, cnd)[:wrc_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_wrc_ac",
    lowerbound =  0,
    upperbound =  (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2
    )
    PowerModels.var(pm, nw, cnd)[:wic_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_wic_ac",
    lowerbound =  -(PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2,
    upperbound =   (PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd) * bigM)^2
    )
end

"variable: `wc_ac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude_sqr(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    PowerModels.var(pm, nw, cnd)[:wc_ac] = @variable(pm.model,
    [i in PowerModels.ids(pm, nw, :convdc)], basename="$(nw)_$(cnd)_wc_ac",
    lowerbound =  PowerModels.ref(pm, nw, :convdc, i, "Vmmin", cnd)^2,
    upperbound =  PowerModels.ref(pm, nw, :convdc, i, "Vmmax", cnd)^2
    )
end
