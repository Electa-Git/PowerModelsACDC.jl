"""
    frequency.jl

Frequency-response primitives and constraints for inertia and FCR/FFR modelling.

This file provides:
- variable constructors to represent inertia, droop and HVDC contributions
  (generators, storage, converters, tie-lines, zones/areas),
- helpers to collect per-network/per-zone aggregated variables for reporting,
- constraint builders that encode preventive frequency-security inequalities
  used in FCUC/SCOPF/contingency builders.

Design notes
- Functions accept an optional `nw::Int` network index (default `_PM.nw_id_default`)
  so they can be used in single-network, multi-network and multi-period contexts.
- Frequency constraints use parameters from `_PM.ref(pm, nw, :frequency_parameters)`.
- HVDC contribution functions assume converter time-constants (`t_hvdc`) are present
  in converter reference data.
"""
function variable_inertia(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
        """
    Create aggregated inertia inspection variables for network `nw`.

    Adds:
    - `htot[z]` per zone (total inertia from generators + storage contributions),
    - `htot_area[a]` per area (for tie-line based constraints).

    These variables are intended for reporting and to ease forming frequency inequalities.
    """
    variable_inertia_gen(pm, nw = nw)
    variable_inertia_tie_line(pm, nw = nw)
end

"""
    variable_inertia_gen(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create per-zone total-inertia variables `htot[z]`.

- Bounded by [0, 1e6] by default.
- Registers solution reporting when `report == true`.
"""
function variable_inertia_gen(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    htot = _PM.var(pm, nw)[:htot] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :zones)], base_name="$(nw)_htot",
    start = 0.0
    )

    if bounded
        for (z, zone) in _PM.ref(pm, nw, :zones)
            JuMP.set_lower_bound(htot[z],   0.0)
            JuMP.set_upper_bound(htot[z],   1e6)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :zones, :htot, _PM.ids(pm, nw, :zones), htot)
end
"""
    variable_inertia_tie_line(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create per-area total-inertia variables `htot_area[a]` used in tie-line frequency constraints.

- Bounded by [0, 1e6] by default.
"""
function variable_inertia_tie_line(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    htot_area = _PM.var(pm, nw)[:htot_area] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :areas)], base_name="$(nw)_htot_area",
    start = 0.0
    )

    if bounded
        for (a, area) in _PM.ref(pm, nw, :areas)
            JuMP.set_lower_bound(htot_area[a],   0.0)
            JuMP.set_upper_bound(htot_area[a],   1e6)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :areas, :htot, _PM.ids(pm, nw, :areas), htot_area)
end

"""
    variable_hvdc_contribution(pm; nw=_PM.nw_id_default)

Create HVDC-related frequency-response variables for network `nw`:

- converter contribution variables (Δpconv, absolute value),
- aggregated per-zone and per-area DC contributions.
"""
function variable_hvdc_contribution(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    variable_converter_inertia(pm, nw = nw)
    variable_converter_inertia_abs(pm, nw = nw)
    variable_total_hvdc_inertia(pm, nw = nw)
    variable_total_hvdc_inertia_tie_line(pm, nw = nw)
end

"""
    variable_converter_inertia(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create per-converter inertia-provision variable `pconv_in[c]` (change in AC power from converter c).
Bounds default to +/- 2 * Pacrated.
"""
function variable_converter_inertia(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    Δpconv = _PM.var(pm, nw)[:pconv_in] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_pconv_in",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 0.0)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(Δpconv[c],  -2 * convdc["Pacrated"])
            JuMP.set_upper_bound(Δpconv[c],   2 * convdc["Pacrated"])
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :convdc, :pconv_in, _PM.ids(pm, nw, :convdc), Δpconv)
end

"""
    variable_converter_droop(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create per-converter droop coefficient (rate) variable `rdc[c]`. Bounds default to [-rmax, rmax].
"""
function variable_converter_droop(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    rdc = _PM.var(pm, nw)[:rdc] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_rdc",
    start = 0
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(rdc[c],  -convdc["rmax"])
            JuMP.set_upper_bound(rdc[c],   convdc["rmax"])
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :convdc, :rdc, _PM.ids(pm, nw, :convdc), rdc)
end

"""
    variable_converter_inertia_abs(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create absolute-value proxy variables `pconv_in_abs[c]` for converter inertia provisioning
(used in objectives / absolute-value constraints). Bounds default to [0, 2*Pacrated].
"""
function variable_converter_inertia_abs(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    Δpconv_abs = _PM.var(pm, nw)[:pconv_in_abs] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_pconv_in_abs",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :convdc, i), "P_g", 1.0)
    )

    if bounded
        for (c, convdc) in _PM.ref(pm, nw, :convdc)
            JuMP.set_lower_bound(Δpconv_abs[c],  0)
            JuMP.set_upper_bound(Δpconv_abs[c],  2 * convdc["Pacrated"])
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :convdc, :pconv_in_abs, _PM.ids(pm, nw, :convdc), Δpconv_abs)
end

"""
    variable_total_hvdc_inertia(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create aggregated per-zone HVDC contribution variables `dc_contr[z]` (can be positive/negative).
"""
function variable_total_hvdc_inertia(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    dc_contr = _PM.var(pm, nw)[:dc_contr] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :zones)], base_name="$(nw)_dc_contr",
    start = 0.0
    )

    if bounded
        for (z, zone) in _PM.ref(pm, nw, :zones)
            JuMP.set_lower_bound(dc_contr[z], -1e6)
            JuMP.set_upper_bound(dc_contr[z],  1e6)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :zones, :dc_contr, _PM.ids(pm, nw, :zones), dc_contr)
end
"""
    variable_total_hvdc_inertia_tie_line(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create aggregated per-area HVDC contribution variables `dc_contr_area[a]`.
"""
function variable_total_hvdc_inertia_tie_line(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    dc_contr_area = _PM.var(pm, nw)[:dc_contr_area] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :areas)], base_name="$(nw)_dc_contr_area",
    start = 0.0
    )

    if bounded
        for (a, area) in _PM.ref(pm, nw, :areas)
            JuMP.set_lower_bound(dc_contr_area[a], -1e6)
            JuMP.set_upper_bound(dc_contr_area[a],  1e6)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :areas, :dc_contr, _PM.ids(pm, nw, :areas), dc_contr_area)
end
"""
    variable_generator_contribution(pm; nw=_PM.nw_id_default)

Create droop contribution variables for generators: `pg_droop[g]` and absolute proxies.
"""
function variable_generator_contribution(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    variable_generator_droop(pm, nw = nw)
    variable_generator_droop_abs(pm, nw = nw)
end

"""
    variable_generator_droop(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create per-generator droop contribution variable `pg_droop[g]`.

- If generator has `fcr_contribution == true` bounds are +/- 2*pmax.
- Otherwise variable is fixed to 0.
"""
function variable_generator_droop(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    pg_droop = _PM.var(pm, nw)[:pg_droop] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_droop",
    start = 0
    )

    if bounded
        for (g, gen) in _PM.ref(pm, nw, :gen)
            if gen["fcr_contribution"] == true
                JuMP.set_lower_bound(pg_droop[g],  - 2 * gen["pmax"])
                JuMP.set_upper_bound(pg_droop[g],    2 * gen["pmax"])
            else
                JuMP.set_lower_bound(pg_droop[g],  0)
                JuMP.set_upper_bound(pg_droop[g],  0)
            end
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :gen, :pg_droop, _PM.ids(pm, nw, :gen), pg_droop)
end

"""
    variable_generator_droop(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create per-generator droop contribution variable `pg_droop[g]`.

- If generator has `fcr_contribution == true` bounds are +/- 2*pmax.
- Otherwise variable is fixed to 0.
"""
function variable_generator_inertia_response(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    dpg_in = _PM.var(pm, nw)[:dpg_in] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_dpg_in",
    start = 0
    )

    if bounded
        for (g, gen) in _PM.ref(pm, nw, :gen)
            if gen["fcr_contribution"] == true
                JuMP.set_lower_bound(dpg_in[g],  0)
                JuMP.set_upper_bound(dpg_in[g],  gen["pmax"])
            else
                JuMP.set_lower_bound(dpg_in[g],  0)
                JuMP.set_upper_bound(dpg_in[g],  0)
            end
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :gen, :dpg_in, _PM.ids(pm, nw, :gen), dpg_in)
end
"""
    variable_generator_droop_abs(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create absolute-value proxy variables `pg_droop_abs[g]` for generator droop contributions.
"""
function variable_generator_droop_abs(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    Δpg_abs = _PM.var(pm, nw)[:pg_droop_abs] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_pg_droop_abs",
    start = 0
    )

    if bounded
        for (g, gen) in _PM.ref(pm, nw, :gen)
            JuMP.set_lower_bound(Δpg_abs[g],  0)
            JuMP.set_upper_bound(Δpg_abs[g],  2 * gen["pmax"])
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :gen, :pg_droop_abs, _PM.ids(pm, nw, :gen), Δpg_abs)
end

"""
    variable_storage_contribution(pm; nw=_PM.nw_id_default)

Create storage droop variables and absolute-value proxies.
"""
function variable_storage_contribution(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    variable_storage_droop(pm, nw = nw)
    variable_storage_droop_abs(pm, nw = nw)
end

"""
    variable_storage_droop(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create per-storage droop variable `ps_droop[s]`. Bounds use storage discharge_rating when enabled.
"""
function variable_storage_droop(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    ps_droop = _PM.var(pm, nw)[:ps_droop] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_ps_droop",
    start = 0
    )

    if bounded
        for (s, storage) in _PM.ref(pm, nw, :storage)
            if storage["fcr_contribution"] == true
                JuMP.set_lower_bound(ps_droop[s],  - 2 * storage["discharge_rating"])
                JuMP.set_upper_bound(ps_droop[s],    2 * storage["discharge_rating"])
            else
                JuMP.set_lower_bound(ps_droop[s],  0)
                JuMP.set_upper_bound(ps_droop[s],  0)
            end
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :storage, :ps_droop, _PM.ids(pm, nw, :storage), ps_droop)
end
"""
    variable_storage_droop_abs(pm; nw=_PM.nw_id_default; bounded=true, report=true)

Create absolute-value proxy `ps_droop_abs[s]` for storage droop contributions.
"""
function variable_storage_droop_abs(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    Δps_abs = _PM.var(pm, nw)[:ps_droop_abs] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_ps_droop_abs",
    start = 0
    )

    if bounded
        for (s, storage) in _PM.ref(pm, nw, :storage)
            JuMP.set_lower_bound(Δps_abs[s],  0)
            JuMP.set_upper_bound(Δps_abs[s],  2 * storage["discharge_rating"])
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :storage, :ps_droop_abs, _PM.ids(pm, nw, :storage), Δps_abs)
end



########################################
### Frequency Constraints ##############
########################################
"""
    constraint_frequency_generator_contingency(pm, zone_id; nw=_PM.nw_id_default, hvdc_contribution=false)

High-level wrapper that builds frequency security constraints for a generator-type contingency
in `zone_id`. It collects generator/storage/converter properties in the zone and calls the
lower-level constraint builder that encodes the inertial / FCR / FFR inequalities.
"""
function constraint_frequency_generator_contingency(pm::_PM.AbstractPowerModel, zone_id; nw::Int = _PM.nw_id_default, hvdc_contribution = false)
    ref_id = get_reference_network_id(pm, nw; uc = true)
    generator_properties = Dict()
    zone_convs = Dict()
    storage_properties = Dict()
    zone = _PM.ref(pm, nw, :zones, zone_id)["zone"]

    for (g, gen) in _PM.ref(pm, nw, :gen)
        if haskey(gen, "zone")
            gen_zone = gen["zone"]
            if !haskey(generator_properties, gen_zone)
                generator_properties[gen_zone] = Dict()
            end
        push!(generator_properties[gen_zone], g => Dict("inertia" => gen["inertia_constants"], "rating" => gen["pmax"]))
        end
    end

    for (s, storage) in _PM.ref(pm, nw, :storage)
        if haskey(storage, "zone")
            st_zone = storage["zone"]
            if !haskey(storage_properties, st_zone)
                storage_properties[st_zone] = Dict()
            end
        push!(storage_properties[st_zone], s => Dict("inertia" => storage["inertia_constants"], "rating" => storage["thermal_rating"]))
        end
    end

    for (c, conv) in _PM.ref(pm, nw, :convdc)
        if haskey(conv, "zone")
            conv_zone = conv["zone"] 
            if !haskey(zone_convs, conv_zone)
                zone_convs[conv_zone] = Dict()
            end
            push!(zone_convs[conv_zone], c => Dict("t_hvdc" => _PM.ref(pm, nw, :frequency_parameters)["t_hvdc"]))
        end
    end

    frequency_parameters = _PM.ref(pm, nw, :frequency_parameters)
    ΔTin = frequency_parameters["t_fcr"]
    ΔTdroop = frequency_parameters["t_fcrd"]
    fmin = frequency_parameters["fmin"]
    fmax = frequency_parameters["fmax"]
    f0 = frequency_parameters["f0"]
    Δfss = frequency_parameters["delta_fss"]
    if haskey(frequency_parameters, "fdb")
        fdb = frequency_parameters["fdb"]
    else
        fdb = 0
    end
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    zones = [z["zone"] for (i,z) in _PM.ref(pm, nw, :zones) if !any(z["zone"] .== excluded_zones)]
    zone_ids = [i for (i,z) in _PM.ref(pm, nw, :zones) if !any(z["zone"] .== excluded_zones)]
    if any(zone .== zones)
        if haskey(generator_properties, zone)
            g_properties = generator_properties[zone]
        else
            g_properties = Dict()
        end
        if haskey(storage_properties, zone)
            s_properties = storage_properties[zone]
        else
            s_properties = 0
        end
        if haskey(zone_convs, zone)
            z_convs = zone_convs[zone]
        else
            z_convs = Dict()
        end
        constraint_frequency_generator_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, zone_id, zone_cont = true)
        for j in setdiff(zone_ids, zone_id)
            zone_ = _PM.ref(pm, nw, :zones, j)["zone"]
            if haskey(generator_properties, zone_)
                g_properties = generator_properties[zone_]
            else
                g_properties = Dict()
            end
            if haskey(storage_properties, zone)
                s_properties = storage_properties[zone_]
            else
                s_properties = 0
            end
            if haskey(zone_convs, zone_)
                z_convs = zone_convs[zone_]
            else
                z_convs = Dict()
            end
            constraint_frequency_generator_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, j, zone_cont = false)
        end
    end
end
"""
    constraint_frequency_generator_contingency(pm, n, ref_id, generator_properties, storage_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, zone_convs, hvdc_contribution, zone; zone_cont=false)

Core constraint builder implementing the frequency inequalities for a generator contingency.

- Uses variables registered in the reference stage (`ref_id`) such as αg/δg/ΔPg and
  per-contingency-stage droop/inertia variables from `n`.
- Adds four inequalities bounding the frequency nadir and settling frequency using
  generator/storage inertia and HVDC contributions.
- Sets reporting variables `htot` and `dc_contr`.
"""
function constraint_frequency_generator_contingency(pm::_PM.AbstractPowerModel, n::Int, ref_id, generator_properties, storage_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, zone_convs, hvdc_contribution, zone; zone_cont = false)
    ΔPg = _PM.var(pm, ref_id, :gen_cont, zone)
    αg = _PM.var(pm, ref_id, :alpha_g)
    δg = _PM.var(pm, ref_id, :delta_g)
    pg_droop = _PM.var(pm, n, :pg_droop)

    pconv_in = _PM.var(pm, n, :pconv_in)
    dc_contr = _PM.var(pm, n, :dc_contr, zone)
    αs = _PM.var(pm, ref_id, :alpha_s)
    ps_droop = _PM.var(pm, n, :ps_droop)
    
    htot = _PM.var(pm, n, :htot, zone)


    if isempty(zone_convs) || hvdc_contribution == false
        JuMP.@constraint(pm.model, [(c, conv) in zone_convs], pconv_in[c] == 0)
    end
  
    dc_contribution_in = calculate_hvdc_ffr_contribution(pconv_in, ΔTin, zone_convs)
    dc_contribution_droop = calculate_hvdc_fcr_contribution(pconv_in, ΔTin, ΔTdroop, zone_convs)

    gen_contribution_droop = calculate_generator_fcr_contribution(pg_droop, ΔTin, ΔTdroop, generator_properties)
    storage_contribution_droop = calculate_storage_fcr_contribution(ps_droop, ΔTin, ΔTdroop, storage_properties)

    if zone_cont == true
        ΔPg_ =  JuMP.@expression(pm.model, ΔPg)
    else
        ΔPg_ =  JuMP.@expression(pm.model, 0)
    end

    if storage_properties == 0 || isempty(storage_properties)
        str_cont =  JuMP.@expression(pm.model, 0)
    else
        str_cont =  JuMP.@expression(pm.model, sum([properties["inertia"] * properties["rating"] * αs[s] for (s, properties) in storage_properties]))
    end

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * (αg[g] - δg[g]) for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmin - (f0-fdb))) <= 
     - f0 * (ΔPg_ *  ΔTin - dc_contribution_in)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * (αg[g] - δg[g]) for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmax - (f0+fdb))) >= 
     - f0 * (ΔPg_ *  ΔTin - dc_contribution_in)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * (αg[g] - δg[g]) for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmin - (f0-fdb))) <= 
     - f0 * (ΔPg_ * ΔTdroop - dc_contribution_in - dc_contribution_droop - gen_contribution_droop - storage_contribution_droop)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * (αg[g] - δg[g]) for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmax - (f0+fdb))) >= 
     - f0 * (ΔPg_ * ΔTdroop - dc_contribution_in - dc_contribution_droop - gen_contribution_droop - storage_contribution_droop)
    )

    #JuMP.@constraint(pm.model,  sum([pg_droop[g]  for (g, gen) in generator_properties]) + sum([ps_droop[s]  for (s, storage) in storage_properties]) >= ΔPg_) # make sure that there is neough reserve......

    JuMP.@constraint(pm.model, htot == sum([properties["inertia"] * properties["rating"] * (αg[g] - δg[g]) for (g, properties) in generator_properties]) + str_cont)
    JuMP.@constraint(pm.model, dc_contr == dc_contribution_in + dc_contribution_droop)
end
"""
    constraint_frequency_converter_contingency(pm, zone_id; nw=_PM.nw_id_default, hvdc_contribution=false)

High-level wrapper to build frequency constraints when a converter outage is the contingency.
Adds plus/minus direction checks (positive / negative converter power severities).
"""
function constraint_frequency_converter_contingency(pm::_PM.AbstractPowerModel, zone_id; nw::Int = _PM.nw_id_default, hvdc_contribution = false)
    ref_id = get_reference_network_id(pm, nw; uc = true)
    zone = _PM.ref(pm, nw, :zones, zone_id)["zone"]
    generator_properties = Dict()
    storage_properties = Dict()
    zone_convs = Dict()
    for (g, gen) in _PM.ref(pm, nw, :gen)
        if haskey(gen, "zone")
            zone = gen["zone"]
            if !haskey(generator_properties, zone)
                generator_properties[zone] = Dict()
            end
        push!(generator_properties[zone], g => Dict("inertia" => gen["inertia_constants"], "rating" => gen["pmax"]))
        end
    end

    for (s, storage) in _PM.ref(pm, nw, :storage)
        if haskey(storage, "zone")
            st_zone = storage["zone"]
            if !haskey(storage_properties, st_zone)
                storage_properties[st_zone] = Dict()
            end
        push!(storage_properties[st_zone], s => Dict("inertia" => storage["inertia_constants"], "rating" => storage["thermal_rating"]))
        end
    end

    for (c, conv) in _PM.ref(pm, nw, :convdc)
        if haskey(conv, "zone")
            zone = conv["zone"] 
            if !haskey(zone_convs, zone)
                zone_convs[zone] = Dict()
            end
            push!(zone_convs[zone], c => Dict("t_hvdc" => _PM.ref(pm, nw, :frequency_parameters)["t_hvdc"]))
        end
    end

    frequency_parameters = _PM.ref(pm, nw, :frequency_parameters)
    ΔTin = frequency_parameters["t_fcr"]
    ΔTdroop = frequency_parameters["t_fcrd"]
    fmin = frequency_parameters["fmin"]
    fmax = frequency_parameters["fmax"]
    f0 = frequency_parameters["f0"]
    Δfss = frequency_parameters["delta_fss"]
    if haskey(frequency_parameters, "fdb")
        fdb = frequency_parameters["fdb"]
    else
        fdb = 0
    end
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    
    zones = [z["zone"] for (i,z) in _PM.ref(pm, nw, :zones) if !any(z["zone"] .== excluded_zones)]
    zone_ids = [i for (i,z) in _PM.ref(pm, nw, :zones) if !any(z["zone"] .== excluded_zones)]
    if any(zone .== zones)
        if haskey(generator_properties, zone)
            g_properties = generator_properties[zone]
        else
            g_properties = Dict()
        end
        if haskey(storage_properties, zone)
            s_properties = storage_properties[zone]
        else
            s_properties = 0
        end
        if haskey(zone_convs, zone)
            z_convs = zone_convs[zone]
        else
            z_convs = Dict()
        end
        
        constraint_frequency_converter_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, zone_id, zone_cont = true, direction = "plus")
        constraint_frequency_converter_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, zone_id, zone_cont = true, direction = "minus")
        for j in setdiff(zone_ids, zone_id)
            zone_ = _PM.ref(pm, nw, :zones, j)["zone"]
            if haskey(generator_properties, zone_)
                g_properties = generator_properties[zone_]
            else
                g_properties = Dict()
            end
            if haskey(storage_properties, zone_)
                s_properties = storage_properties[zone_]
            else
                s_properties = Dict()
            end
            if haskey(zone_convs, zone_)
                z_convs = zone_convs[zone_]
            else
                z_convs = Dict()
            end
            constraint_frequency_converter_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, j, zone_cont = false, direction = "plus")
            constraint_frequency_converter_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, j, zone_cont = false, direction = "minus")
        end
    end
end


"""
    constraint_frequency_converter_contingency(pm, n, ref_id, generator_properties, storage_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, zone_convs, hvdc_contribution, zone; zone_cont=false, direction="plus")

Core converter-frequency constraint builder. Similar to generator-version but uses
converter severity ΔPc_plus and sign handling for direction.
"""

function constraint_frequency_converter_contingency(pm::_PM.AbstractPowerModel, n::Int, ref_id, generator_properties, storage_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, zone_convs, hvdc_contribution, zone; zone_cont = false, direction = "plus")
    ΔPc_plus = _PM.var(pm, ref_id, :conv_cont_plus, zone)
    αg = _PM.var(pm, ref_id, :alpha_g)
    pconv_in = _PM.var(pm, n, :pconv_in)
    pg_droop = _PM.var(pm, n, :pg_droop)


    αs = _PM.var(pm, ref_id, :alpha_s)
    ps_droop = _PM.var(pm, n, :ps_droop)

    htot = _PM.var(pm, n, :htot, zone)
    dc_contr = _PM.var(pm, n, :dc_contr, zone)

    if isempty(zone_convs) || hvdc_contribution == false
        JuMP.@constraint(pm.model, [(c, conv) in zone_convs], pconv_in[c] == 0)
    end
  
    dc_contribution_in = calculate_hvdc_ffr_contribution(pconv_in, ΔTin, zone_convs)
    dc_contribution_droop = calculate_hvdc_fcr_contribution(pconv_in, ΔTin, ΔTdroop, zone_convs)

    gen_contribution_droop = calculate_generator_fcr_contribution(pg_droop, ΔTin, ΔTdroop, generator_properties)
    storage_contribution_droop = calculate_storage_fcr_contribution(ps_droop, ΔTin, ΔTdroop, storage_properties)

    if zone_cont == true && direction == "plus"
        ΔPc_ =  JuMP.@expression(pm.model, ΔPc_plus)
    elseif zone_cont == true && direction == "minus"
        ΔPc_ =  JuMP.@expression(pm.model, -ΔPc_plus)
    else
        ΔPc_ =  JuMP.@expression(pm.model, 0)
    end

    if storage_properties == 0 || isempty(storage_properties)
        str_cont =  JuMP.@expression(pm.model, 0)
    else
        str_cont =  JuMP.@expression(pm.model, sum([properties["inertia"] * properties["rating"] * αs[s] for (s, properties) in storage_properties]))
    end

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmin - (f0-fdb))) <= 
     - f0 * (ΔPc_ *  ΔTin - dc_contribution_in)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmax - (f0+fdb))) >= 
     - f0 * (ΔPc_ *  ΔTin - dc_contribution_in)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmin - (f0-fdb))) <= 
     - f0 * (ΔPc_ * ΔTdroop - dc_contribution_in - dc_contribution_droop - gen_contribution_droop - storage_contribution_droop)
    )


    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmax - (f0+fdb))) >= 
     - f0 * (ΔPc_ * ΔTdroop - dc_contribution_in - dc_contribution_droop - gen_contribution_droop - storage_contribution_droop)
    )

    #JuMP.@constraint(pm.model,  sum([pg_droop[g]  for (g, gen) in generator_properties]) + sum([ps_droop[s]  for (s, storage) in storage_properties]) >= ΔPc_) # make sure that there is neough reserve......

    JuMP.@constraint(pm.model, htot == sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont)
    JuMP.@constraint(pm.model, dc_contr == dc_contribution_in + dc_contribution_droop)
end
"""
    constraint_frequency_storage_contingency(pm, zone_id; nw=_PM.nw_id_default, hvdc_contribution=false)

High-level wrapper for storage-type contingency frequency constraints.
"""
function constraint_frequency_storage_contingency(pm::_PM.AbstractPowerModel, zone_id; nw::Int = _PM.nw_id_default, hvdc_contribution = false)
    ref_id = get_reference_network_id(pm, nw; uc = true)
    zone = _PM.ref(pm, nw, :zones, zone_id)["zone"]
    generator_properties = Dict()
    storage_properties = Dict()
    zone_convs = Dict()
    for (g, gen) in _PM.ref(pm, nw, :gen)
        if haskey(gen, "zone")
            zone = gen["zone"]
            if !haskey(generator_properties, zone)
                generator_properties[zone] = Dict()
            end
        push!(generator_properties[zone], g => Dict("inertia" => gen["inertia_constants"], "rating" => gen["pmax"]))
        end
    end

    for (s, storage) in _PM.ref(pm, nw, :storage)
        if haskey(storage, "zone")
            st_zone = storage["zone"]
            if !haskey(storage_properties, st_zone)
                storage_properties[st_zone] = Dict()
            end
        push!(storage_properties[st_zone], s => Dict("inertia" => storage["inertia_constants"], "rating" => storage["thermal_rating"]))
        end
    end

    for (c, conv) in _PM.ref(pm, nw, :convdc)
        if haskey(conv, "zone")
            zone = conv["zone"] 
            if !haskey(zone_convs, zone)
                zone_convs[zone] = Dict()
            end
            push!(zone_convs[zone], c => Dict("t_hvdc" => _PM.ref(pm, nw, :frequency_parameters)["t_hvdc"]))
        end
    end

    frequency_parameters = _PM.ref(pm, nw, :frequency_parameters)
    ΔTin = frequency_parameters["t_fcr"]
    ΔTdroop = frequency_parameters["t_fcrd"]
    fmin = frequency_parameters["fmin"]
    fmax = frequency_parameters["fmax"]
    f0 = frequency_parameters["f0"]
    Δfss = frequency_parameters["delta_fss"]
    if haskey(frequency_parameters, "fdb")
        fdb = frequency_parameters["fdb"]
    else
        fdb = 0
    end
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    
    zones = [z["zone"] for (i,z) in _PM.ref(pm, nw, :zones) if !any(z["zone"] .== excluded_zones)]
    zone_ids = [i for (i,z) in _PM.ref(pm, nw, :zones) if !any(z["zone"] .== excluded_zones)]
    if any(zone .== zones)
        if haskey(generator_properties, zone)
            g_properties = generator_properties[zone]
        else
            g_properties = Dict()
        end
        if haskey(storage_properties, zone)
            s_properties = storage_properties[zone]
        else
            s_properties = 0
        end
        if haskey(zone_convs, zone)
            z_convs = zone_convs[zone]
        else
            z_convs = Dict()
        end
        
        constraint_frequency_storage_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, zone_id, zone_cont = true, direction = "plus")
        constraint_frequency_storage_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, zone_id, zone_cont = true, direction = "minus")
        for j in setdiff(zone_ids, zone_id)
            zone_ = _PM.ref(pm, nw, :zones, j)["zone"]
            if haskey(generator_properties, zone_)
                g_properties = generator_properties[zone_]
            else
                g_properties = Dict()
            end
            if haskey(storage_properties, zone_)
                s_properties = storage_properties[zone_]
            else
                s_properties = Dict()
            end
            if haskey(zone_convs, zone_)
                z_convs = zone_convs[zone_]
            else
                z_convs = Dict()
            end
            constraint_frequency_storage_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, j, zone_cont = false, direction = "plus")
            constraint_frequency_storage_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, z_convs, hvdc_contribution, j, zone_cont = false, direction = "minus")
        end
    end
end
"""
    constraint_frequency_storage_contingency(pm, n, ref_id, generator_properties, storage_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, zone_convs, hvdc_contribution, zone; zone_cont=false, direction="plus")

Core storage-frequency constraint builder. Uses storage severity ΔPs and includes storage-specific αs/δs terms.
"""
function constraint_frequency_storage_contingency(pm::_PM.AbstractPowerModel, n::Int, ref_id, generator_properties, storage_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, zone_convs, hvdc_contribution, zone; zone_cont = false, direction = "plus")
    ΔPs = _PM.var(pm, ref_id, :storage_cont, zone)
    αg = _PM.var(pm, ref_id, :alpha_g)
    pconv_in = _PM.var(pm, n, :pconv_in)
    pg_droop = _PM.var(pm, n, :pg_droop)


    αs = _PM.var(pm, ref_id, :alpha_s)
    δs = _PM.var(pm, ref_id, :delta_s)
    ps_droop = _PM.var(pm, n, :ps_droop)

    htot = _PM.var(pm, n, :htot, zone)
    dc_contr = _PM.var(pm, n, :dc_contr, zone)

    if isempty(zone_convs) || hvdc_contribution == false
        JuMP.@constraint(pm.model, [(c, conv) in zone_convs], pconv_in[c] == 0)
    end
  
    dc_contribution_in = calculate_hvdc_ffr_contribution(pconv_in, ΔTin, zone_convs)
    dc_contribution_droop = calculate_hvdc_fcr_contribution(pconv_in, ΔTin, ΔTdroop, zone_convs)

    gen_contribution_droop = calculate_generator_fcr_contribution(pg_droop, ΔTin, ΔTdroop, generator_properties)
    storage_contribution_droop = calculate_storage_fcr_contribution(ps_droop, ΔTin, ΔTdroop, storage_properties)

    if zone_cont == true && direction == "plus"
        ΔPs_ =  JuMP.@expression(pm.model, ΔPs)
    elseif zone_cont == true && direction == "minus"
        ΔPs_ =  JuMP.@expression(pm.model, -ΔPs)
    else
        ΔPs_ =  JuMP.@expression(pm.model, 0)
    end

    if storage_properties == 0 || isempty(storage_properties)
        str_cont =  JuMP.@expression(pm.model, 0)
    else
        str_cont =  JuMP.@expression(pm.model, sum([properties["inertia"] * properties["rating"] * (αs[s] - δs[s]) for (s, properties) in storage_properties]))
    end

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmin - (f0-fdb))) <= 
     - f0 * (ΔPs_ *  ΔTin - dc_contribution_in)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmax - (f0+fdb))) >= 
     - f0 * (ΔPs_ *  ΔTin - dc_contribution_in)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmin - (f0-fdb))) <= 
     - f0 * (ΔPs_ * ΔTdroop - dc_contribution_in - dc_contribution_droop - gen_contribution_droop - storage_contribution_droop)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmax - (f0+fdb))) >= 
     - f0 * (ΔPs_ * ΔTdroop - dc_contribution_in - dc_contribution_droop - gen_contribution_droop - storage_contribution_droop)
    )

    #JuMP.@constraint(pm.model,  sum([pg_droop[g]  for (g, gen) in generator_properties]) + sum([ps_droop[s]  for (s, storage) in storage_properties]) >= ΔPs_) # make sure that there is neough reserve......

    JuMP.@constraint(pm.model, htot == sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont)
    JuMP.@constraint(pm.model, dc_contr == dc_contribution_in + dc_contribution_droop)
end

"""
    constraint_frequency_tieline_contingency(pm, area_id; nw=_PM.nw_id_default, hvdc_contribution=false)

High-level wrapper for tie-line contingency frequency constraints (area-based).
"""
function constraint_frequency_tieline_contingency(pm::_PM.AbstractPowerModel, area_id; nw::Int = _PM.nw_id_default, hvdc_contribution = false)
    ref_id = get_reference_network_id(pm, nw; uc = true)
    area = _PM.ref(pm, nw, :areas, area_id)["area"]
    generator_properties = Dict()
    storage_properties = Dict()
    area_convs = Dict()
    for (g, gen) in _PM.ref(pm, nw, :gen)
        if haskey(gen, "area")
            area = gen["area"]
            if !haskey(generator_properties, area)
                generator_properties[area] = Dict()
            end
        push!(generator_properties[area], g => Dict("inertia" => gen["inertia_constants"], "rating" => gen["pmax"]))
        end
    end

    for (s, storage) in _PM.ref(pm, nw, :storage)
        if haskey(storage, "area")
            st_area = storage["area"]
            if !haskey(storage_properties, st_area)
                storage_properties[st_area] = Dict()
            end
        push!(storage_properties[st_area], s => Dict("inertia" => storage["inertia_constants"], "rating" => storage["thermal_rating"]))
        end
    end

    for (c, conv) in _PM.ref(pm, nw, :convdc)
        if haskey(conv, "area")
            area = conv["area"] 
            if !haskey(area_convs, area)
                area_convs[area] = Dict()
            end
            push!(area_convs[area], c => Dict("t_hvdc" => _PM.ref(pm, nw, :frequency_parameters)["t_hvdc"]))
        end
    end

    frequency_parameters = _PM.ref(pm, nw, :frequency_parameters)
    ΔTin = frequency_parameters["t_fcr"]
    ΔTdroop = frequency_parameters["t_fcrd"]
    fmin = frequency_parameters["fmin"]
    fmax = frequency_parameters["fmax"]
    f0 = frequency_parameters["f0"]
    Δfss = frequency_parameters["delta_fss"]
    if haskey(frequency_parameters, "fdb")
        fdb = frequency_parameters["fdb"]
    else
        fdb = 0
    end
    if haskey(_PM.ref(pm, nw), :excluded_areas)
        excluded_areas = _PM.ref(pm, nw, :excluded_areas)
    else
        excluded_areas = []
    end
    
    areas = [a["area"] for (i,a) in _PM.ref(pm, nw, :areas) if !any(a["area"] .== excluded_areas)]
    area_ids = [i for (i,a) in _PM.ref(pm, nw, :areas) if !any(a["area"] .== excluded_areas)]
    if any(area .== areas)
        if haskey(generator_properties, area)
            g_properties = generator_properties[area]
        else
            g_properties = Dict()
        end
        if haskey(storage_properties, area)
            s_properties = storage_properties[area]
        else
            s_properties = Dict()
        end
        if haskey(area_convs, area)
            a_convs = area_convs[area]
        else
            a_convs = Dict()
        end
        
        constraint_frequency_tieline_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, a_convs, hvdc_contribution, area_id, zone_cont = true, direction = "fr")
        constraint_frequency_tieline_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, a_convs, hvdc_contribution, area_id, zone_cont = true, direction = "to")

        for j in setdiff(area_ids, area_id)
            area_ = _PM.ref(pm, nw, :areas, j)["area"]
            if haskey(generator_properties, area_)
                g_properties = generator_properties[area_]
            else
                g_properties = Dict()
            end
            if haskey(storage_properties, area_)
                s_properties = storage_properties[area_]
            else
                s_properties = Dict()
            end
            if haskey(area_convs, area_)
                a_convs = area_convs[area_]
            else
                a_convs = Dict()
            end
            constraint_frequency_tieline_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, a_convs, hvdc_contribution, j, zone_cont = false, direction = "fr")
            constraint_frequency_tieline_contingency(pm, nw, ref_id, g_properties, s_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, a_convs, hvdc_contribution, j, zone_cont = false, direction = "to")
        end
    end
end
"""
    constraint_frequency_tieline_contingency(pm, n, ref_id, generator_properties, storage_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, area_convs, hvdc_contribution, area; zone_cont=false, direction="fr")

Core tie-line-frequency constraint builder. Uses ΔPl_plus and area aggregates.
"""
function constraint_frequency_tieline_contingency(pm::_PM.AbstractPowerModel, n::Int, ref_id, generator_properties, storage_properties, ΔTin, ΔTdroop, f0, fmin, fmax, fdb, Δfss, area_convs, hvdc_contribution, area; zone_cont = false, direction = "fr")
    ΔPl_plus = _PM.var(pm, ref_id, :tieline_cont_plus, area)
    αg = _PM.var(pm, ref_id, :alpha_g)
    pconv_in = _PM.var(pm, n, :pconv_in)
    pg_droop = _PM.var(pm, n, :pg_droop)

    αs = _PM.var(pm, ref_id, :alpha_s)
    ps_droop = _PM.var(pm, n, :ps_droop)

    htot = _PM.var(pm, n, :htot_area, area)
    dc_contr = _PM.var(pm, n, :dc_contr_area, area)

    if isempty(zone_convs) || hvdc_contribution == false
        JuMP.@constraint(pm.model, [(c, conv) in zone_convs], pconv_in[c] == 0)
    end
  
    dc_contribution_in = calculate_hvdc_ffr_contribution(pconv_in, ΔTin, zone_convs)
    dc_contribution_droop = calculate_hvdc_fcr_contribution(pconv_in, ΔTin, ΔTdroop, zone_convs)

    gen_contribution_droop = calculate_generator_fcr_contribution(pg_droop, ΔTin, ΔTdroop, generator_properties)
    storage_contribution_droop = calculate_storage_fcr_contribution(ps_droop, ΔTin, ΔTdroop, storage_properties)

    if zone_cont == true && direction == "fr"
        ΔPl_ =  JuMP.@expression(pm.model, ΔPl_plus)
    elseif zone_cont == true && direction == "to"
        ΔPl_ =  JuMP.@expression(pm.model, -ΔPl_plus)
    else
        ΔPl_ =  JuMP.@expression(pm.model, 0)
    end

    if storage_properties == 0 || isempty(storage_properties)
        str_cont =  JuMP.@expression(pm.model, 0)
    else
        str_cont =  JuMP.@expression(pm.model, sum([properties["inertia"] * properties["rating"] * αs[s] for (s, properties) in storage_properties]))
    end

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmin - (f0-fdb))) <= 
     - f0 * (ΔPl_ *  ΔTin - dc_contribution_in)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmax - (f0+fdb))) >= 
     - f0 * (ΔPl_ *  ΔTin - dc_contribution_in)
    )

    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmin - (f0-fdb))) <= 
     - f0 * (ΔPl_ * ΔTdroop - dc_contribution_in - dc_contribution_droop - gen_contribution_droop - storage_contribution_droop)
    )


    JuMP.@constraint(pm.model, 
    (sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont) *  (2 * (fmax - (f0+fdb))) >= 
     - f0 * (ΔPl_ * ΔTdroop - dc_contribution_in - dc_contribution_droop - gen_contribution_droop - storage_contribution_droop)
    )

    #JuMP.@constraint(pm.model,  sum([pg_droop[g]  for (g, gen) in generator_properties]) + sum([ps_droop[s]  for (s, storage) in storage_properties]) >= ΔPl_) # make sure that there is neough reserve......

    JuMP.@constraint(pm.model, htot == sum([properties["inertia"] * properties["rating"] * αg[g] for (g, properties) in generator_properties]) + str_cont)
    JuMP.@constraint(pm.model, dc_contr == dc_contribution_in + dc_contribution_droop)
end

"""
    calculate_hvdc_ffr_contribution(pconv_in, ΔT, zone_convs)

Helper to compute FFR contribution from per-converter AC power changes `pconv_in`
using converter time constants `t_hvdc`. Returns scalar expression summing contributions.
"""
function calculate_hvdc_ffr_contribution(pconv_in, ΔT, zone_convs)
    sum([(pconv_in[c] * min(1, ΔT / conv["t_hvdc"]) * min(ΔT, conv["t_hvdc"]) / 2 ) + (pconv_in[c] * max(0, ΔT - conv["t_hvdc"])) for (c, conv) in zone_convs])
end
"""
    calculate_hvdc_fcr_contribution(pconv_in, ΔTin, ΔTdroop, zone_convs)

Compute FCR contribution (droop timescale) from `pconv_in`.
"""
function calculate_hvdc_fcr_contribution(pconv_in, ΔTin, ΔTdroop, zone_convs)
    sum([pconv_in[c] * (ΔTdroop - ΔTin) for (c, conv) in zone_convs])
end

"""
    calculate_generator_fcr_contribution(pg_droop, ΔTin, ΔTdroop, zone_gens)

Helper summing generator FCR contribution from `pg_droop`.
"""
function calculate_generator_fcr_contribution(pg_droop, ΔTin, ΔTdroop, zone_gens)
    sum([pg_droop[g]/2 * (ΔTdroop - ΔTin)  for (g, gen) in zone_gens]) 
end
"""
    calculate_storage_fcr_contribution(ps_droop, ΔTin, ΔTdroop, zone_storage)

Helper summing storage FCR contribution from `ps_droop`.
"""
function calculate_storage_fcr_contribution(ps_droop, ΔTin, ΔTdroop, zone_storage)
    if zone_storage == 0 || isempty(zone_storage)
        str_contr = 0
    else
        str_contr = sum([ps_droop[s]/2 * (ΔTdroop - ΔTin)  for (s, storage) in zone_storage]) 
    end

    return str_contr
end