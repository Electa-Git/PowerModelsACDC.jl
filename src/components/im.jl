# collect all converter variables
"All converter variables"
function variable_im(pm::_PM.AbstractPowerModel; kwargs...)
    variable_im_stator_flow(pm; kwargs...)
    variable_im_rotor_inductance_flow(pm; kwargs...)

    variable_im_active_power(pm; kwargs...) # 
    variable_im_reactive_power(pm; kwargs...) # To be checked if necessary (simply equal to 0)
    variable_im_slip(pm; kwargs...)

    variable_im_magnetisation_voltage(pm; kwargs...)
    variable_im_airgap_voltage(pm; kwargs...)

    variable_im_to_grid_active_power(pm; kwargs...)
    variable_im_to_grid_reactive_power(pm; kwargs...)
end

function variable_im_stator_flow(pm::_PM.AbstractPowerModel; kwargs...)
    variable_im_stator_active_power_to(pm; kwargs...)
    variable_im_stator_reactive_power_to(pm; kwargs...)
end

function variable_im_rotor_inductance_flow(pm::_PM.AbstractPowerModel; kwargs...)
    variable_im_rotor_inductance_active_power_from(pm; kwargs...)
    variable_im_rotor_inductance_reactive_power_from(pm; kwargs...)
end

"variable: `p_im[j]` for `j` in `im`"
function variable_im_active_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    pim = _PM.var(pm, nw)[:p_im_ag] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_p_im",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :im, i), "P_ag", 1.0)
    )

    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(pim[c],  im["Pacmin"])
            JuMP.set_upper_bound(pim[c],  im["Pacmax"])
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :p_im, _PM.ids(pm, nw, :im), pim)
end

"variable: `qconv_ac[j]` for `j` in `im`"
function variable_im_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    qim = _PM.var(pm, nw)[:q_im_ag] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_q_im",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :im, i), "Q_ag", 0.0)
    )

    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(qim[c],  im["Qacmin"])
            JuMP.set_upper_bound(qim[c],  im["Qacmax"])
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :q_im, _PM.ids(pm, nw, :im), qim)
end


"variable: `p_im_s_to[j]` for `j` in `im`" # TODO: Ask Hakan purpose of using Pacrated instead of Pacmin
function variable_im_stator_active_power_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    p_s_to = _PM.var(pm, nw)[:p_im_s_to] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_p_im_s_to",
    start = -_PM.comp_start_value(_PM.ref(pm, nw, :im, i), "P_ag", 1.0)
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(p_s_to[c],  -im["Pacrated"] * bigM)
            JuMP.set_upper_bound(p_s_to[c],   im["Pacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :p_im_s_to, _PM.ids(pm, nw, :im), p_s_to)
end

"variable: `q_im_s_to[j]` for `j` in `im`"
function variable_im_stator_reactive_power_to(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    q_s_to = _PM.var(pm, nw)[:q_im_s_to] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_q_im_s_to",
    start = -_PM.comp_start_value(_PM.ref(pm, nw, :im, i), "P_ag", 1.0) # Reactive power flow is approx air-gap power 
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(q_s_to[c],  -im["Qacrated"] * bigM)
            JuMP.set_upper_bound(q_s_to[c],   im["Qacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :q_im_s_to, _PM.ids(pm, nw, :im), q_s_to)
end


"variable: `p_im_ri_f[j]` for `j` in `im`"
function variable_im_rotor_inductance_active_power_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    p_ri_f = _PM.var(pm, nw)[:p_im_ri_f] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_p_im_ri_f",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :im, i), "P_ag", 1.0)
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(p_ri_f[c],  -im["Pacrated"] * bigM)
            JuMP.set_upper_bound(p_ri_f[c],   im["Pacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :p_im_ri_f, _PM.ids(pm, nw, :im), p_ri_f)
end

"variable: `q_im_ri_f[j]` for `j` in `im`"
function variable_im_rotor_inductance_reactive_power_from(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    q_ri_f = _PM.var(pm, nw)[:q_im_ri_f] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_q_im_ri_f",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :im, i), "P_ag", 1.0) # Reactive power flow is approx air-gap power (Q_ag = 0.0)
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(q_ri_f[c],  -im["Qacrated"] * bigM)
            JuMP.set_upper_bound(q_ri_f[c],   im["Qacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :q_im_ri_f, _PM.ids(pm, nw, :im), q_ri_f)
end

"variable: `p_im_tf_fr[j]` for `j` in `im`"
function variable_im_to_grid_active_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    p_s_fr = _PM.var(pm, nw)[:p_im_s_fr] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_p_im_s_fr",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :im, i), "P_ag", 1.0)
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(p_s_fr[c],  -im["Pacrated"] * bigM)
            JuMP.set_upper_bound(p_s_fr[c],   im["Pacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :pg, _PM.ids(pm, nw, :im), p_s_fr)
end

"variable: `q_im_s_fr[j]` for `j` in `im`"
function variable_im_to_grid_reactive_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 2;
    q_s_fr = _PM.var(pm, nw)[:q_im_s_fr] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_q_im_s_fr",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :im, i), "P_ag", 1.0) # Reactive power flow is approx air-gap power (Q_ag = 0.0)
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(q_s_fr[c],  -im["Qacrated"] * bigM)
            JuMP.set_upper_bound(q_s_fr[c],   im["Qacrated"] * bigM)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :qg, _PM.ids(pm, nw, :im), q_s_fr)
end


"variable: `pconv_dc[j]` for `j` in `im`"
function variable_im_slip(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    
    slip = _PM.var(pm, nw)[:slip_im] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_slip_im",
    start = 0.0 # Start with slip to zero
    )
    # Always bound slip bcs there is no application where you would want unstable equil point
    for (c, im) in _PM.ref(pm, nw, :im)
        s_kip = im["r_r"] / (im["x_sl"]) + im["x_rl"]
        println(s_kip)
        JuMP.set_lower_bound(slip[c], -s_kip) # Generator 
        JuMP.set_upper_bound(slip[c],  s_kip) # Motor
    end
    

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :slip, _PM.ids(pm, nw, :im), slip)
end



function variable_im_magnetisation_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_im_magnetisation_voltage_magnitude(pm; kwargs...)
    variable_im_magnetisation_voltage_angle(pm; kwargs...)
end


"variable: `vm_m[j]` for `j` in `im`"
function variable_im_magnetisation_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    vm_m = _PM.var(pm, nw)[:vm_m] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_vm_m",
    start = 1.0 #_PM.ref(pm, nw, :im, i, ""), no voltage control or information IM
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(vm_m[c], im["Vmmin"] / bigM)
            JuMP.set_upper_bound(vm_m[c], im["Vmmax"] * bigM)
        end
    end
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :vm_m, _PM.ids(pm, nw, :im), vm_m)
end


"variable: `va_m[j]` for `j` in `im`"
function variable_im_magnetisation_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 2*pi; #
    va_m = _PM.var(pm, nw)[:va_m] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_va_m",
    start = 0
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(va_m[c], -bigM)
            JuMP.set_upper_bound(va_m[c],  bigM)
        end
    end
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :va_m, _PM.ids(pm, nw, :im), va_m)
end


function variable_im_magnetisation_voltage(pm::_PM.AbstractACRModel; kwargs...)
    variable_im_magnetisation_voltage_real(pm; kwargs...)
    variable_im_magnetisation_voltage_imaginary(pm; kwargs...)
end


"real part of the voltage variable `vr_m[j]` for `j` in `im`"
function variable_im_magnetisation_voltage_real(pm::_PM.AbstractACRModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    vr_m = _PM.var(pm, nw)[:vr_m] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_vr_m",
    start = 1.0  #_PM.ref(pm, nw, :im, i, "Vtar")
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(vr_m[c],  -im["Vmmax"] * bigM)   
            JuMP.set_upper_bound(vr_m[c],  im["Vmmax"] * bigM)   
        end
    end
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :vr_m, _PM.ids(pm, nw, :im), vr_m)
end

"imaginary part of the voltage variable `vi_m[j]` for `j` in `im`"
function variable_im_magnetisation_voltage_imaginary(pm::_PM.AbstractACRModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 1.2; 
    vi_m = _PM.var(pm, nw)[:vi_m] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_vi_m",
    start = 0.0
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(vi_m[c], -im["Vmmax"] * bigM)
            JuMP.set_upper_bound(vi_m[c],  im["Vmmax"] * bigM)
        end
    end
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :vi_m, _PM.ids(pm, nw, :im), vi_m)
end


function variable_im_airgap_voltage(pm::_PM.AbstractPowerModel; kwargs...)
    variable_im_airgap_voltage_magnitude(pm; kwargs...)
    variable_im_airgap_voltage_angle(pm; kwargs...)
end


"variable: `vm_ag[j]` for `j` in `im`"
function variable_im_airgap_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    vm_ag = _PM.var(pm, nw)[:vm_ag] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_vm_ag",
    start = 1.0 # _PM.ref(pm, nw, :im, i, "Vtar")
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(vm_ag[c], im["Vmmin"])
            JuMP.set_upper_bound(vm_ag[c], im["Vmmax"])
        end
    end
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :vm_ag, _PM.ids(pm, nw, :im), vm_ag)
end

"variable: `va_ag[j]` for `j` in `im`"
function variable_im_airgap_voltage_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    bigM = 2*pi; #
    va_ag = _PM.var(pm, nw)[:va_ag] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_va_ag",
    start = 0
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(va_ag[c], -bigM)
            JuMP.set_upper_bound(va_ag[c],  bigM)
        end
    end
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :va_ag, _PM.ids(pm, nw, :im), va_ag)
end



function variable_im_airgap_voltage(pm::_PM.AbstractACRModel; kwargs...)
    variable_im_airgap_voltage_real(pm; kwargs...)
    variable_im_airgap_voltage_imaginary(pm; kwargs...)
end

"real part of the voltage variable `vr_ag[j]` for `j` in `im`"
function variable_im_airgap_voltage_real(pm::_PM.AbstractACRModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    vr_ag = _PM.var(pm, nw)[:vr_ag] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_vr_ag",
    start = 1.0 # _PM.ref(pm, nw, :im, i, "Vtar")
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(vr_ag[c], -im["Vmmax"])
            JuMP.set_upper_bound(vr_ag[c],  im["Vmmax"])
        end
    end
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :vr_ag, _PM.ids(pm, nw, :im), vr_ag)
end

"imaginary part of the voltage variable `vi_ag[j]` for `j` in `im`"
function variable_im_airgap_voltage_imaginary(pm::_PM.AbstractACRModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    vi_ag = _PM.var(pm, nw)[:vi_ag] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_vi_ag",
    start = 0.0
    )
    if bounded
        for (c, im) in _PM.ref(pm, nw, :im)
            JuMP.set_lower_bound(vi_ag[c], -im["Vmmax"])
            JuMP.set_upper_bound(vi_ag[c],  im["Vmmax"])
        end
    end
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :vi_ag, _PM.ids(pm, nw, :im), vi_ag)
end



# "variable: `wrf_ac[j]` and `wif_ac`  for `j` in `im`"
# function variable_converter_filter_voltage_cross_products(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
#     bigM = 1.2; # only internal converter voltage is strictly regulated
#     wrfac = _PM.var(pm, nw)[:wrf_ac] = JuMP.@variable(pm.model,
#     [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_wrf_ac",
#     start = _PM.ref(pm, nw, :im, i, "Vtar")^2
#     )
#     wifac = _PM.var(pm, nw)[:wif_ac] = JuMP.@variable(pm.model,
#     [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_wif_ac",
#     start = _PM.ref(pm, nw, :im, i, "Vtar")^2
#     )
#     if bounded
#         for (c, im) in _PM.ref(pm, nw, :im)
#             JuMP.set_lower_bound(wrfac[c],  0)
#             JuMP.set_upper_bound(wrfac[c],  (im["Vmmax"] * bigM)^2)
#             JuMP.set_lower_bound(wifac[c], -(im["Vmmax"] * bigM)^2)
#             JuMP.set_upper_bound(wifac[c],  (im["Vmmax"] * bigM)^2)
#         end
#     end

#     report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :wrfilt, _PM.ids(pm, nw, :im), wrfac)
#     report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :wifilt, _PM.ids(pm, nw, :im), wifac)
# end

# "variable: `wf_ac` for `j` in `im`"
# function variable_converter_filter_voltage_magnitude_sqr(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
#     bigM = 1.2; # only internal converter voltage is strictly regulated
#     wfac = _PM.var(pm, nw)[:wf_ac] = JuMP.@variable(pm.model,
#     [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_wf_ac",
#     start = 1.0 #_PM.ref(pm, nw, :im, i, "Vtar")^2
#     )
#     if bounded
#         for (c, im) in _PM.ref(pm, nw, :im)
#             JuMP.set_lower_bound(wfac[c], (im["Vmmin"] / bigM)^2)
#             JuMP.set_upper_bound(wfac[c], (im["Vmmax"] * bigM)^2)
#         end
#     end
#     report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :wfilt, _PM.ids(pm, nw, :im), wfac)
# end


# "variable: `wrc_ac[j]` and `wic_ac[j]`  for `j` in `im`"
# function variable_converter_internal_voltage_cross_products(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
#     bigM = 1.2; # only internal converter voltage is strictly regulated
#     wrcac = _PM.var(pm, nw)[:wrc_ac] = JuMP.@variable(pm.model,
#     [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_wrc_ac",
#     start = _PM.ref(pm, nw, :im, i, "Vtar")^2
#     )
#     wicac = _PM.var(pm, nw)[:wic_ac] = JuMP.@variable(pm.model,
#     [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_wic_ac",
#     start = _PM.ref(pm, nw, :im, i, "Vtar")^2
#     )
#     if bounded
#         for (c, im) in _PM.ref(pm, nw, :im)
#             JuMP.set_lower_bound(wrcac[c],  0)
#             JuMP.set_upper_bound(wrcac[c],  (im["Vmmax"] * bigM)^2)
#             JuMP.set_lower_bound(wicac[c], -(im["Vmmax"] * bigM)^2)
#             JuMP.set_upper_bound(wicac[c],  (im["Vmmax"] * bigM)^2)
#         end
#     end

#     report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :wrconv, _PM.ids(pm, nw, :im), wrcac)
#     report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :wiconv, _PM.ids(pm, nw, :im), wicac)
# end

# "variable: `wc_ac[j]` for `j` in `im`"
# function variable_converter_internal_voltage_magnitude_sqr(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
#     wcac = _PM.var(pm, nw)[:wc_ac] = JuMP.@variable(pm.model,
#     [i in _PM.ids(pm, nw, :im)], base_name="$(nw)_wc_ac",
#     start = _PM.ref(pm, nw, :im, i, "Vtar")^2
#     )
#     if bounded
#         for (c, im) in _PM.ref(pm, nw, :im)
#             JuMP.set_lower_bound(wcac[c], (im["Vmmin"])^2)
#             JuMP.set_upper_bound(wcac[c], (im["Vmmax"])^2)
#         end
#     end
#     report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :im, :wconv, _PM.ids(pm, nw, :im), wcac)
# end

############## Constraint template for IMs ###################################################

function constraint_im_rotor_inductance(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    im = _PM.ref(pm, nw, :im, i)
    constraint_im_rotor_inductance(pm, nw, i, im["x_rl"])
end

#
function constraint_im_magnetisation(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    im = _PM.ref(pm, nw, :im, i)
    constraint_im_magnetisation(pm, nw, i, im["x_m"])
end

#
function constraint_im_stator(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    im = _PM.ref(pm, nw, :im, i)
    constraint_im_stator(pm, nw, i, im["r_s"], im["x_sl"], im["im_bus"])
end

#
function constraint_im_slip(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    im = _PM.ref(pm, nw, :im, i)
    T_0 = im["torque"]["T_0"]
    A = im["torque"]["A"]
    B = im["torque"]["B"]
    C = im["torque"]["C"]
    m = im["torque"]["m"]
    
    
    constraint_im_slip(pm, nw, i, T_0, A, B, C, m, im["r_r"] )
end


########## ACP formulation ####################################################################


"""
Im stator constraints (keep same code as transformer)
```
p_im_s_fr ==  g*vm_fr^2 + -g*vm_fr*vm_to * cos(va_fr-va_to) + -b*vm_fr*vm_to*sin(va_fr-va_to)
q_im_s_fr == -b*vm_fr^2 +  b*vm_fr*vm_to * cos(va_fr-va_to) + -g*vm_fr*vm_to*sin(va_fr-va_to)
p_im_s_to ==  g*vm_to^2 + -g*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b*vm_to*vm_fr    *sin(va_to - va_fr)
q_im_s_to == -b*vm_to^2 +  b*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g*vm_to*vm_fr    *sin(va_to - va_fr)
```
"""
function constraint_im_stator(pm::_PM.AbstractACPModel, n::Int, i::Int, rtf, xtf, acbus)
    ptf_fr = _PM.var(pm, n, :p_im_s_fr, i)
    qtf_fr = _PM.var(pm, n, :q_im_s_fr, i)
    ptf_to = _PM.var(pm, n, :p_im_s_to, i)
    qtf_to = _PM.var(pm, n, :q_im_s_to, i)

    vm = _PM.var(pm, n, :vm, acbus)
    va = _PM.var(pm, n, :va, acbus)
    vmf = _PM.var(pm, n, :vm_m, i)
    vaf = _PM.var(pm, n, :va_m, i)

    ztf = rtf + 1im*xtf
    ytf = 1/(rtf + 1im*xtf)
    gtf = real(ytf)
    btf = imag(ytf)
    gtf_sh = 0 # No shunt impedance
    c1, c2, c3, c4 = ac_power_flow_constraints(pm.model, gtf, btf, gtf_sh, vm, vmf, va, vaf, ptf_fr, ptf_to, qtf_fr, qtf_to)
end
"constraints for a voltage magnitude transformer + series impedance"
function ac_power_flow_constraints(model, g, b, gsh_fr, vm_fr, vm_to, va_fr, va_to, p_fr, p_to, q_fr, q_to)
    c1 = JuMP.@constraint(model, p_fr ==  g*vm_fr^2 + -g*vm_fr*vm_to * cos(va_fr-va_to) + -b*vm_fr*vm_to*sin(va_fr-va_to))
    c2 = JuMP.@constraint(model, q_fr == -b*vm_fr^2 +  b*vm_fr*vm_to * cos(va_fr-va_to) + -g*vm_fr*vm_to*sin(va_fr-va_to))
    c3 = JuMP.@constraint(model, p_to ==  g*vm_to^2 + -g*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b*vm_to*vm_fr    *sin(va_to - va_fr))
    c4 = JuMP.@constraint(model, q_to == -b*vm_to^2 +  b*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g*vm_to*vm_fr    *sin(va_to - va_fr))
    return c1, c2, c3, c4
end
"""
IM rotor inductance constraints (copy conv reactor code)
```
-pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf)
-qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf)
p_pr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac)
q_pr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac)
```
"""
function constraint_im_rotor_inductance(pm::_PM.AbstractACPModel, n::Int, i::Int, xc)
    pconv_ac = _PM.var(pm, n,  :p_im_ag, i)
    qconv_ac = _PM.var(pm, n,  :q_im_ag, i)
    ppr_to = - pconv_ac
    qpr_to = - qconv_ac
    ppr_fr = _PM.var(pm, n,  :p_im_ri_f, i)
    qpr_fr = _PM.var(pm, n,  :q_im_ri_f, i)

    vmf = _PM.var(pm, n, :vm_m, i)
    vaf = _PM.var(pm, n, :va_m, i)
    vmc = _PM.var(pm, n, :vm_ag, i)
    vac = _PM.var(pm, n, :va_ag, i)

    zc = im*xc
   
    yc = 1/(zc)
    gc = real(yc)
    bc = imag(yc)
    JuMP.@constraint(pm.model, - pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf)) # JuMP doesn't allow affine expressions in NL constraints
    JuMP.@constraint(pm.model, - qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf)) # JuMP doesn't allow affine expressions in NL constraints
    JuMP.@constraint(pm.model, ppr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac))
    JuMP.@constraint(pm.model, qpr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac))

end
"""
IM magnetisation constraint (copy from conv filter)
```
ppr_fr + ptf_to == 0
qpr_fr + qtf_to +  (-bv)  *vmf^2 == 0
```
"""
function constraint_im_magnetisation(pm::_PM.AbstractACPModel, n::Int, i::Int, x_m)
    ppr_fr = _PM.var(pm, n, :p_im_ri_f, i)
    qpr_fr = _PM.var(pm, n, :q_im_ri_f, i)
    ptf_to = _PM.var(pm, n, :p_im_s_to, i)
    qtf_to = _PM.var(pm, n, :q_im_s_to, i)

    vmf = _PM.var(pm, n, :vm_m, i)

    bv = 1/(x_m)
    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
    JuMP.@constraint(pm.model, qpr_fr + qtf_to +  (bv) *(vmf^2) == 0)
end
"""
IM slip constraints (slip out balance air-gap power with mechanical torque, see Van Cutsem Voltage stability)
```
T_0*(A*(1-slip)^m+B*(1-slip)+C) == (vm_ag^2)*slip/r_r
p_im_ag == (vm_ag^2)*slip/r_r
q_im_ag == 0.0
```
"""
function constraint_im_slip(pm::_PM.AbstractACPModel, n::Int, i::Int,T_0, A, B, C, m, r_r)
    p = _PM.var(pm, n, :p_im_ag, i)
    q = _PM.var(pm, n, :q_im_ag, i)
    slip = _PM.var(pm, n, :slip_im, i)
    vm_ag = _PM.var(pm, n, :vm_ag, i)

    JuMP.@constraint(pm.model,   T_0*(A*(1-slip)^m+B*(1-slip)+C) == (vm_ag^2)*slip/r_r)
    JuMP.@constraint(pm.model,   p == (vm_ag^2)*slip/r_r)
    JuMP.@constraint(pm.model,   q == 0.0)
end