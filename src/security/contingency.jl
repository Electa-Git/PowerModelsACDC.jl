
"""
    contingency.jl

Contingency variable and constraint primitives for security-aware formulations.

This file provides:
- variable creation helpers for contingency modelling (generators, converters,
  tie-lines, storage and DC-branches),
- binary indicator variables used to select outage elements,
- constraints that enforce outage behaviour, selection and linking between
  reference (pre-contingency) and contingency (post-contingency) stages,
- utilities to build zone/area based contingency severity and selection rules.

Intended usage:
- Called from multi-stage builders (UC/SCOPF/FCUC/SCOPF) to add variables and
  constraints for contingency stages.
- Functions accept an optional `nw` network index (default `_PM.nw_id_default`)
  to support multinetwork / multi-period models.
"""
# ...existing code...

"""
    variable_contingencies(pm; nw=_PM.nw_id_default)

Create all high-level contingency variables for network `nw`.

This calls the lower-level variable constructors for:
- generator contingencies and indicators
- converter contingencies and indicators
- tieline contingencies and indicators
- storage contingencies and indicators

All variables are registered in `_PM.var(pm, nw)` and prepared for reporting.
"""
function variable_contingencies(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    variable_generator_contingency(pm, nw = nw)
    variable_generator_contingency_indicator(pm, nw = nw)
    variable_converter_contingency(pm, nw = nw)
    variable_converter_contingency_indicator(pm, nw = nw)
    variable_tieline_contingency(pm, nw = nw)
    variable_tieline_contingency_indicator(pm, nw = nw)
    variable_storage_contingency(pm, nw = nw)
    variable_storage_contingency_indicator(pm, nw = nw)
end
"""
    variable_generator_contingency(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create continuous variables δPg[z] representing the selected generator contingency
severity per zone `z`. Bounds are set using the maximum generator pmax when
`bounded == true`. Reporting attaches values to solution output when `report`.
"""
function variable_generator_contingency(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    δPg = _PM.var(pm, nw)[:gen_cont] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :zones)], base_name="$(nw)_gen_cont",
    start = 0.0
    )

    if bounded
        pg_max = maximum([gen["pmax"] for (g, gen) in _PM.ref(pm, nw, :gen)])
        for (z, zone) in _PM.ref(pm, nw, :zones)
            JuMP.set_lower_bound(δPg[z], 0)
            JuMP.set_upper_bound(δPg[z],  pg_max)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :contingency, :gen_cont, _PM.ids(pm, nw, :zones), δPg)
end
"""
    variable_generator_contingency_indicator(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create binary indicator variables δg[g] per generator used to mark the selected
contingency generator within its zone. These binaries are used to linearise
selection constraints between reference and contingency stages.
"""
function variable_generator_contingency_indicator(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    delta_g = _PM.var(pm, nw)[:delta_g] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_delta_g",
        binary = true,
        start = 0,
        lower_bound = 0,
        upper_bound = 1
    )
    report && _PM.sol_component_value(pm, nw, :gen, :delta_g, _PM.ids(pm, nw, :gen), delta_g)
end
"""
    variable_converter_contingency(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create continuous converter-contingency variables δPc_plus and δPc_minus per zone.
These track positive and negative converter power severities for frequency and
reserve calculations. Bounds are set from converter Pacrated when `bounded == true`.
"""
function variable_converter_contingency(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    δPc_plus = _PM.var(pm, nw)[:conv_cont_plus] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :zones)], base_name="$(nw)_conv_cont_plus",
    start = 0.0
    )

    δPc_minus = _PM.var(pm, nw)[:conv_cont_minus] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :zones)], base_name="$(nw)_conv_cont_minus",
    start = 0.0
    )

    if bounded
        pc_max = maximum([conv["Pacrated"] for (c, conv) in _PM.ref(pm, nw, :convdc)])
        for (z, zone) in _PM.ref(pm, nw, :zones)
            JuMP.set_lower_bound(δPc_plus[z], -pc_max)
            JuMP.set_lower_bound(δPc_minus[z], -pc_max)
            JuMP.set_upper_bound(δPc_plus[z],  pc_max)
            JuMP.set_upper_bound(δPc_minus[z],  0)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :contingency, :conv_cont_plus, _PM.ids(pm, nw, :zones), δPc_plus)
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :contingency, :conv_cont_minus, _PM.ids(pm, nw, :zones), δPc_minus)
end

"""
    variable_converter_contingency_indicator(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create binary indicator variables δc_plus and δc_minus per converter used to
select contingency converters within their zones.
"""
function variable_converter_contingency_indicator(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    delta_c_plus = _PM.var(pm, nw)[:delta_c_plus] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_delta_c_plus",
        binary = true,
        start = 0,
        lower_bound = 0,
        upper_bound = 1
    )

    delta_c_minus = _PM.var(pm, nw)[:delta_c_minus] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :convdc)], base_name="$(nw)_delta_c_minus",
    binary = true,
    start = 0,
    lower_bound = 0,
    upper_bound = 1
    )

    report && _PM.sol_component_value(pm, nw, :convdc, :delta_c_plus, _PM.ids(pm, nw, :convdc), delta_c_plus)
    report && _PM.sol_component_value(pm, nw, :convdc, :delta_c_minus, _PM.ids(pm, nw, :convdc), delta_c_minus)
end
"""
    variable_storage_contingency(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create continuous storage contingency variables δPs[z] per zone. Bounds use
storage thermal_rating when available.
"""
function variable_storage_contingency(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    δPs = _PM.var(pm, nw)[:storage_cont] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :zones)], base_name="$(nw)_storage_cont",
    start = 0.0
    )

    if bounded
        if !isempty([storage["thermal_rating"] for (s, storage) in _PM.ref(pm, nw, :storage)])
            ps_max = maximum([storage["thermal_rating"] for (s, storage) in _PM.ref(pm, nw, :storage)])
        else
            ps_max = 0
        end
        for (z, zone) in _PM.ref(pm, nw, :zones)
            JuMP.set_lower_bound(δPs[z], 0)
            JuMP.set_upper_bound(δPs[z],  ps_max)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :contingency, :storage_cont, _PM.ids(pm, nw, :zones), δPs)
end
"""
    variable_storage_contingency_indicator(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create binary indicator variables δs[s] per storage device to select a storage
contingency candidate.
"""
function variable_storage_contingency_indicator(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    delta_s = _PM.var(pm, nw)[:delta_s] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_delta_s",
        binary = true,
        start = 0,
        lower_bound = 0,
        upper_bound = 1
    )
    report && _PM.sol_component_value(pm, nw, :storage, :delta_s, _PM.ids(pm, nw, :storage), delta_s)
end
"""
    variable_tieline_contingency(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create continuous tieline contingency variables δPl_plus and δPl_minus per area.
Bounds are derived from branch rate limits when `bounded == true`.
"""
function variable_tieline_contingency(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    δPl_plus = _PM.var(pm, nw)[:tieline_cont_plus] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :areas)], base_name="$(nw)_tieline_cont_plus",
    start = 0.0
    )

    δPl_minus = _PM.var(pm, nw)[:tieline_cont_minus] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :areas)], base_name="$(nw)_tieline_cont_minus",
    start = 0.0
    )

    if bounded
        pl_max = maximum([branch["rate_a"] for (b, branch) in _PM.ref(pm, nw, :branch)])
        for (a, area) in _PM.ref(pm, nw, :areas)
            JuMP.set_lower_bound(δPl_plus[a], 0)
            JuMP.set_lower_bound(δPl_minus[a], -pl_max)
            JuMP.set_upper_bound(δPl_plus[a],  pl_max)
            JuMP.set_upper_bound(δPl_minus[a],  0)
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :contingency_l, :tieline_cont_plus, _PM.ids(pm, nw, :areas), δPl_plus)
    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :contingency_l, :tieline_cont_minus, _PM.ids(pm, nw, :areas), δPl_minus)
end
"""
    variable_tieline_contingency_indicator(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create binary indicator variables δl_plus and δl_minus for tie-line contingency
selection across tie-line candidates.
"""
function variable_tieline_contingency_indicator(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    delta_l_plus = _PM.var(pm, nw)[:delta_l_plus] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :tie_lines)], base_name="$(nw)_delta_l_plus",
        binary = true,
        start = 0,
        lower_bound = 0,
        upper_bound = 1
    )

    delta_l_minus = _PM.var(pm, nw)[:delta_l_minus] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :tie_lines)], base_name="$(nw)_delta_l_minus",
        binary = true,
        start = 0,
        lower_bound = 0,
        upper_bound = 1
    )

    report && _PM.sol_component_value(pm, nw, :tie_lines, :delta_l_plus, _PM.ids(pm, nw, :tie_lines), delta_l_plus)
    report && _PM.sol_component_value(pm, nw, :tie_lines, :delta_l_minus, _PM.ids(pm, nw, :tie_lines), delta_l_minus)
end
"""
    constraint_generator_contingencies(pm; nw=_PM.nw_id_default)

High-level wrapper that adds generator-contingency constraints for network `nw`.
Adds:
- δPg linking constraints,
- selection constraints (one selected generator per zone),
- per-generator indicator coupling constraints.
"""
function constraint_generator_contingencies(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    constraint_generator_contingency(pm; nw = nw)
    constraint_select_generator_contingency(pm; nw = nw)
    for i in _PM.ids(pm, nw, :gen)
        constraint_generator_contingency_indicator(pm, i; nw = nw)
    end
end
"""
    constraint_generator_contingency(pm; nw=_PM.nw_id_default)

Build δPg >= pg constraints per zone and generator that belongs to that zone.
Uses `get_reference_network_id(pm, nw; uc=true)` to index reference variables.
"""
function constraint_generator_contingency(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for zone in zones
        for (g, gen) in _PM.ref(pm, nw, :gen)
            if haskey(gen, "zone") && _PM.ref(pm, nw, :zones, zone)["zone"] == gen["zone"]
                constraint_generator_contingency(pm, g, reference_network_idx, zone)
            end
        end
    end 
end
"""
    constraint_generator_contingency_indicator(pm, i; nw=_PM.nw_id_default)

Add big-M linking constraints between generator power `pg` and zone severity
variable δPg using the generator indicator δg. Ensures selected generator maps
its dispatch into the contingency severity variable.
"""
function constraint_generator_contingency_indicator(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)

    bigM = 2 * maximum([gen["pmax"] for (g, gen) in _PM.ref(pm, nw, :gen)])
    gen = _PM.ref(pm, nw, :gen, i)
    gen_zone = gen["zone"]
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for z in zones
        zone = _PM.ref(pm, nw, :zones, z)["zone"]
        if gen_zone == zone
            constraint_generator_contingency_indicator(pm, i, reference_network_idx, bigM, z)
        end
    end
end
"""
    constraint_select_generator_contingency(pm; nw=_PM.nw_id_default)

Enforce selection of exactly one generator contingency candidate per zone.
The constraint is currently equality to 1 (could be relaxed).
"""
function constraint_select_generator_contingency(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for zone in zones
        zone_gens = []
        for (g, gen) in _PM.ref(pm, nw, :gen)
            if haskey(gen, "zone") && _PM.ref(pm, nw, :zones, zone)["zone"] == gen["zone"]
                append!(zone_gens, g)
            end
        end
        constraint_select_generator_contingency(pm, reference_network_idx, zone_gens)
    end 
end

function constraint_generator_contingency(pm::_PM.AbstractPowerModel, i::Int, n::Int, zone)
    pg = _PM.var(pm, n, :pg, i)
    δPg = _PM.var(pm, n, :gen_cont, zone)

    JuMP.@constraint(pm.model, δPg >= pg)
end

function constraint_select_generator_contingency(pm::_PM.AbstractPowerModel, n::Int, zone_gens)
    δg = _PM.var(pm, n, :delta_g)

    JuMP.@constraint(pm.model, sum(δg[g] for g in zone_gens) == 1) # could probably be relaxed as >= 1, to be tested.
end

function constraint_generator_contingency_indicator(pm::_PM.AbstractPowerModel, i::Int, n::Int, bigM, zone)
    pg = _PM.var(pm, n, :pg, i)
    δg = _PM.var(pm, n, :delta_g, i)
    δPg = _PM.var(pm, n, :gen_cont, zone)

    JuMP.@constraint(pm.model, (δg- 1) * bigM <= δPg - pg)
    JuMP.@constraint(pm.model, δPg - pg <= (1-δg) * bigM)
end

########################################
### Converter Constraints ##############
########################################

"""
    constraint_converter_contingencies(pm; nw=_PM.nw_id_default)

High-level wrapper for converter contingency constraints. Adds severity,
selection and per-converter indicator linking constraints.
"""
function constraint_converter_contingencies(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
        constraint_converter_contingency_severity(pm; nw = nw)
        constraint_select_converter_contingency(pm; nw = nw)
        for i in _PM.ids(pm, nw, :convdc)
            constraint_converter_contingency_indicator(pm, i; nw = nw)
        end
end

function constraint_converter_contingencies(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
        constraint_converter_outage(pm, i; nw = nw)
end

"""
    constraint_converter_contingency_severity(pm; nw=_PM.nw_id_default)

Build δPc constraints (δPc_plus/δPc_minus) linking the reference converter active
power to the zone severity variables (absolute-value behaviour).
"""
function constraint_converter_contingency_severity(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for zone in zones
        for (c, conv) in _PM.ref(pm, nw, :convdc)
            if haskey(conv, "zone") && _PM.ref(pm, nw, :zones, zone)["zone"] == conv["zone"]
                constraint_converter_contingency_severity(pm, c, reference_network_idx, zone)
            end
        end
    end
end
"""
    constraint_converter_contingency_indicator(pm, i, n, bigM, zone)

Big-M constraints coupling per-converter active power `pconv_ac` with the zone
severity variables using the converter indicator binary variables.
"""
function constraint_converter_contingency_indicator(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    bigM = 2 * maximum([conv["Pacrated"] for (c, conv) in _PM.ref(pm, nw, :convdc)])

    conv = _PM.ref(pm, nw, :convdc, i)
    conv_zone = conv["zone"]
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for z in zones
        zone = _PM.ref(pm, nw, :zones, z)["zone"]
        if conv_zone == zone
            constraint_converter_contingency_indicator(pm, i, reference_network_idx, bigM, z)
        end
    end
end

"""
    constraint_select_converter_contingency(pm; nw=_PM.nw_id_default)

Select exactly one converter per zone for positive and negative contingency
severity (separate selection for plus/minus).
"""
function constraint_select_converter_contingency(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for zone in zones
        zone_convs = []
        for (c, conv) in _PM.ref(pm, nw, :convdc)
            if haskey(conv, "zone") && _PM.ref(pm, nw, :zones, zone)["zone"] == conv["zone"]
                append!(zone_convs, c)
            end
        end
        constraint_select_converter_contingency(pm, reference_network_idx, zone_convs)
    end 
end

function constraint_converter_contingency_severity(pm::_PM.AbstractPowerModel, i::Int, n::Int, zone)
    pc = _PM.var(pm, n, :pconv_ac, i)
    δPc_plus = _PM.var(pm, n, :conv_cont_plus, zone)
    δPc_minus = _PM.var(pm, n, :conv_cont_minus, zone)

    JuMP.@constraint(pm.model, δPc_plus >= pc)
    JuMP.@constraint(pm.model, δPc_plus >= -pc)
end

function constraint_select_converter_contingency(pm::_PM.AbstractPowerModel, n::Int, zone_convs)
    δc_plus = _PM.var(pm, n, :delta_c_plus)
    δc_minus = _PM.var(pm, n, :delta_c_minus)

    JuMP.@constraint(pm.model, sum(δc_plus[c] for c in zone_convs) == 1) # could probably be relaxed as >= 1, to be tested.
    JuMP.@constraint(pm.model, sum(δc_minus[c] for c in zone_convs) == 1) # could probably be relaxed as >= 1, to be tested.
end

function constraint_converter_contingency_indicator(pm::_PM.AbstractPowerModel, i::Int, n::Int, bigM, zone)
    pc = _PM.var(pm, n, :pconv_ac, i)
    δc_plus = _PM.var(pm, n, :delta_c_plus, i)
    δc_minus = _PM.var(pm, n, :delta_c_minus, i)
    δPc_plus = _PM.var(pm, n, :conv_cont_plus, zone)
    δPc_minus = _PM.var(pm, n, :conv_cont_minus, zone)

    JuMP.@constraint(pm.model, (δc_plus- 1) * bigM <= δPc_plus - pc)
    JuMP.@constraint(pm.model, δPc_plus - pc <= (1-δc_plus) * bigM)
end

function constraint_contingent_converter(pm::_PM.AbstractPowerModel, n::Int, ref_id::Int, zone_convs, direction)
    δc = _PM.var(pm, ref_id, :delta_c_plus)
    pconv_in = _PM.var(pm, n, :pconv_in)
    for (c, conv) in zone_convs
        JuMP.@constraint(pm.model, -2 * _PM.ref(pm, ref_id, :convdc, c)["Pacrated"] * (1 - δc[c]) <= pconv_in[c]) 
        JuMP.@constraint(pm.model,  2 * _PM.ref(pm, ref_id, :convdc, c)["Pacrated"] * (1 - δc[c]) >= pconv_in[c])
    end
end

"""
    constraint_converter_outage(pm, i; nw=_PM.nw_id_default)

Apply outage behaviour to converter `i` in network `nw` by forcing AC/DC power,
transformer and reactor flows and voltages to zero. Used when a converter is
selected as the outage element in a contingency stage.
"""
function constraint_converter_outage(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    constraint_active_power_converter_outage(pm::_PM.AbstractPowerModel, nw::Int, i::Int)
    constraint_reactive_power_converter_outage(pm::_PM.AbstractPowerModel, nw::Int, i::Int)
    constraint_voltage_converter_outage(pm::_PM.AbstractPowerModel, nw::Int, i::Int)
end


function constraint_active_power_converter_outage(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    pconv_tf_to = _PM.var(pm, n, :pconv_tf_to, i)
    pconv_pr_fr = _PM.var(pm, n, :pconv_pr_fr, i)
    pconv_tf_fr = _PM.var(pm, n, :pconv_tf_fr, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)

    JuMP.@constraint(pm.model, pconv_ac == 0)
    JuMP.@constraint(pm.model, pconv_tf_to == 0)
    JuMP.@constraint(pm.model, pconv_tf_fr == 0)
    JuMP.@constraint(pm.model, pconv_pr_fr == 0)
    JuMP.@constraint(pm.model, pconv_dc == 0)
end

function constraint_reactive_power_converter_outage(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)
    qconv_tf_to = _PM.var(pm, n, :qconv_tf_to, i)
    qconv_pr_fr = _PM.var(pm, n, :qconv_pr_fr, i)
    qconv_tf_fr = _PM.var(pm, n, :qconv_tf_fr, i)

    JuMP.@constraint(pm.model, qconv_ac == 0)
    JuMP.@constraint(pm.model, qconv_tf_to == 0)
    JuMP.@constraint(pm.model, qconv_tf_fr == 0)
    JuMP.@constraint(pm.model, qconv_pr_fr == 0)
end

function constraint_voltage_converter_outage(pm::_PM.AbstractPowerModel, nw::Int, i::Int)
    conv = _PM.ref(pm, nw, :convdc, i)
    acbus = conv["busac_i"]

    constraint_voltage_converter_outage(pm::_PM.AbstractPowerModel, nw::Int, i::Int, acbus)
end

function constraint_voltage_converter_outage(pm::_PM.AbstractACPModel, n::Int,  i::Int, acbus)
    vmc = _PM.var(pm, n,  :vmc, i)
    vac = _PM.var(pm, n,  :vac, i)

    vmf = _PM.var(pm, n,  :vmf, i)
    vaf = _PM.var(pm, n,  :vaf, i)

    vm = _PM.var(pm, n,  :vm, acbus)
    va = _PM.var(pm, n,  :va, acbus)

    JuMP.@constraint(pm.model, vmc == vmf)
    JuMP.@constraint(pm.model, vmf == vm)
    JuMP.@constraint(pm.model, vac == vaf)
    JuMP.@constraint(pm.model, vaf == va)
end

########################################
### Tieline Constraints ################
########################################
"""
    constraint_tieline_contingencies(pm; nw=_PM.nw_id_default)

High-level wrapper adding tie-line contingency severity, selection and per-tie
line indicator constraints.
"""
function constraint_tieline_contingencies(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    constraint_tieline_contingency(pm; nw = nw)
    constraint_select_tieline_contingency(pm; nw = nw)
    for i in _PM.ids(pm, nw, :tie_lines)
        constraint_tieline_contingency_indicator(pm, i; nw = nw)
    end
end
"""
    constraint_tieline_contingency(pm; nw=_PM.nw_id_default)

Build δPl constraints per area that capture the absolute tieline flow severity
(relative to the reference flow) used in frequency calculations.
"""
function constraint_tieline_contingency(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    areas = [i for i in _PM.ids(pm, nw, :areas)]
    for area in areas
        for (t, tieline) in _PM.ref(pm, nw, :tie_lines)
            if (haskey(tieline, "area_fr") && _PM.ref(pm, nw, :areas, area)["area"] == tieline["area_fr"])  || (haskey(tieline, "area_to") && _PM.ref(pm, nw, :areas, area)["area"] == tieline["area_to"]) 
                br_idx = tieline["br_idx"]
                fbus = _PM.ref(pm, nw, :branch, br_idx)["f_bus"]
                tbus = _PM.ref(pm, nw, :branch, br_idx)["t_bus"]
                constraint_tieline_contingency(pm, br_idx, fbus, tbus, reference_network_idx, area)
            end
        end
    end
end

function constraint_tieline_contingency_indicator(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    bigM = 2 * maximum([branch["rate_a"] for (b, branch) in _PM.ref(pm, nw, :branch)])

    tieline = _PM.ref(pm, nw, :tie_lines, i)
    br_idx = tieline["br_idx"]
    fbus = _PM.ref(pm, nw, :branch, br_idx)["f_bus"]
    tbus = _PM.ref(pm, nw, :branch, br_idx)["t_bus"]
    areas = [a for a in _PM.ids(pm, nw, :areas)]
    for a in areas
        area = _PM.ref(pm, nw, :areas, a)
        if (haskey(tieline, "area_fr") && _PM.ref(pm, nw, :areas, a)["area"] == tieline["area_fr"])  || (haskey(tieline, "area_to") && _PM.ref(pm, nw, :areas, a)["area"] == tieline["area_to"]) 
            constraint_tieline_contingency_indicator(pm, i, br_idx, fbus, tbus, reference_network_idx, bigM, a)
        end
    end
end

function constraint_select_tieline_contingency(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    areas = [i for i in _PM.ids(pm, nw, :areas)]
    for area in areas
        tielines = []
        for (t, tieline) in _PM.ref(pm, nw, :tie_lines)
            if (haskey(tieline, "area_fr") && _PM.ref(pm, nw, :areas, area)["area"] == tieline["area_fr"]) || (haskey(tieline, "area_to") && _PM.ref(pm, nw, :areas, area)["area"] == tieline["area_to"]) # one constraint should be enough per area: To be checked
                append!(tielines, t)
            end
        end
        if !isempty(tielines)
            println(area, " ", tielines)
            constraint_select_tieline_contingency(pm, reference_network_idx, tielines)
        end
    end 
end

function constraint_tieline_contingency(pm::_PM.AbstractPowerModel, br_idx, fbus, tbus, n::Int, area)
    pl = _PM.var(pm, n, :p)[(br_idx, fbus, tbus)]
    δPl_plus = _PM.var(pm, n, :tieline_cont_plus, area)
    δPl_minus = _PM.var(pm, n, :tieline_cont_minus, area)

    JuMP.@constraint(pm.model, δPl_plus >= pl)
    JuMP.@constraint(pm.model, δPl_plus >= -pl)
end

function constraint_select_tieline_contingency(pm::_PM.AbstractPowerModel, n::Int, tielines)
    δl_plus = _PM.var(pm, n, :delta_l_plus)

    JuMP.@constraint(pm.model, sum(δl_plus[l] for l in tielines) >= 1) # could probably be relaxed as >= 1, to be tested.
end

function constraint_tieline_contingency_indicator(pm::_PM.AbstractPowerModel, i, br_idx, fbus, tbus, n::Int, bigM, area)
    pl = _PM.var(pm, n, :p)[(br_idx, fbus, tbus)]
    δl_plus = _PM.var(pm, n, :delta_l_plus, i)
    δl_minus = _PM.var(pm, n, :delta_l_minus, i)
    δPl_plus = _PM.var(pm, n, :tieline_cont_plus, area)
    δPl_minus = _PM.var(pm, n, :tieline_cont_minus, area)

    JuMP.@constraint(pm.model, (δl_plus- 1) * bigM <= δPl_plus - pl)
    JuMP.@constraint(pm.model, δPl_plus - pl <= (1-δl_plus) * bigM)
end

########################################
### Storage Constraints ################
########################################
"""
    constraint_storage_contingencies(pm; nw=_PM.nw_id_default)

High-level wrapper for storage contingency variables and constraints.
"""
function constraint_storage_contingencies(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    constraint_storage_contingency(pm; nw = nw)
    constraint_select_storage_contingency(pm; nw = nw)
    for i in _PM.ids(pm, nw, :storage)
        constraint_storage_contingency_indicator(pm, i; nw = nw)
    end
end
"""
    constraint_storage_contingency(pm; nw=_PM.nw_id_default)

Link storage dispatch `ps` to the zone severity variable δPs with δPs >= ps.
"""
function constraint_storage_contingency(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)

    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for zone in zones
        for (s, storage) in _PM.ref(pm, nw, :storage)
            if haskey(storage, "zone") && _PM.ref(pm, nw, :zones, zone)["zone"] == storage["zone"]
                constraint_storage_contingency(pm, s, reference_network_idx, zone)
            end
        end
    end 
end

function constraint_storage_contingency_indicator(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)

    bigM = 2 * maximum([storage["thermal_rating"] for (s, storage) in _PM.ref(pm, nw, :storage)])
    storage = _PM.ref(pm, nw, :storage, i)
    storage_zone = storage["zone"]
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for z in zones
        zone = _PM.ref(pm, nw, :zones, z)["zone"]
        if storage_zone == zone
            constraint_storage_contingency_indicator(pm, i, reference_network_idx, bigM, z)
        end
    end
end

function constraint_select_storage_contingency(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    if haskey(_PM.ref(pm, nw), :excluded_zones)
        excluded_zones = _PM.ref(pm, nw, :excluded_zones)
    else
        excluded_zones = []
    end
    
    zones = [i for i in _PM.ids(pm, nw, :zones) if !any(i .== excluded_zones)]
    for zone in zones
        zone_storages = []
        for (s, storage) in _PM.ref(pm, nw, :storage)
            if haskey(storage, "zone") && _PM.ref(pm, nw, :zones, zone)["zone"] == storage["zone"]
                append!(zone_storages, s)
            end
        end
        constraint_select_storage_contingency(pm, reference_network_idx, zone_storages)
    end 
end

function constraint_storage_contingency(pm::_PM.AbstractPowerModel, i::Int, n::Int, zone)
    ps = _PM.var(pm, n, :ps, i)
    δPs = _PM.var(pm, n, :storage_cont, zone)

    JuMP.@constraint(pm.model, δPs >= ps)
end

function constraint_select_storage_contingency(pm::_PM.AbstractPowerModel, n::Int, zone_storages)
    δs = _PM.var(pm, n, :delta_s)

    JuMP.@constraint(pm.model, sum(δs[s] for s in zone_storages) == 1) # could probably be relaxed as >= 1, to be tested.
end

function constraint_storage_contingency_indicator(pm::_PM.AbstractPowerModel, i::Int, n::Int, bigM, zone)
    ps = _PM.var(pm, n, :ps, i)
    δs = _PM.var(pm, n, :delta_s, i)
    δPs = _PM.var(pm, n, :storage_cont, zone)

    JuMP.@constraint(pm.model, (δs- 1) * bigM <= δPs - ps)
    JuMP.@constraint(pm.model, δPs - ps <= (1-δs) * bigM)
end


############################################
### DC Branch Contingencies ################
############################################

"""
    variable_dcgrid_auxiliary_voltage_magnitude(pm; nw=_PM.nw_id_default, bounded=true, report=true)

Create auxiliary DC grid voltage variables (vdcm_star) used for outage models
to allow independent 'post-contingency' DC voltages while keeping bounds.
"""
function variable_dcgrid_auxiliary_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    vdcm = _PM.var(pm, nw)[:vdcm_star] = JuMP.JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :busdc)], base_name="$(nw)_vdcm_star",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", 1.0)
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(vdcm[i],  -2*busdc["Vdcmax"])
            JuMP.set_upper_bound(vdcm[i],   2*busdc["Vdcmax"])
        end
    end

    report && _IM.sol_component_value(pm, _PM.pm_it_sym, nw, :busdc, :vm_star, _PM.ids(pm, nw, :busdc), vdcm)
end
"""
    constraint_dc_branch_contingencies(pm, i; nw=_PM.nw_id_default)

High-level wrapper to apply DC branch outage behaviour for DC branch `i`.
For outages the DC branch flows are forced to zero and Ohm outage constraints
are applied to auxiliary variables.
"""
function constraint_dc_branch_contingencies(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    constraint_dc_branch_outage(pm::_PM.AbstractPowerModel, i; nw = nw)  
end
"""
    constraint_dc_branch_outage(pm, n, f_idx, t_idx)

Enforce p_fr == 0 and p_to == 0 for the specified DC branch incidence indices
in the contingency network `n`.
"""
function constraint_dc_branch_outage(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = PowerModels.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    constraint_dc_branch_outage(pm, nw, f_idx, t_idx)
end

function constraint_dc_branch_outage(pm::_PM.AbstractPowerModel, n::Int, f_idx, t_idx)
    p_fr = PowerModels.var(pm, n, :p_dcgrid, f_idx)
    p_to = PowerModels.var(pm, n, :p_dcgrid, t_idx)

    JuMP.@constraint(pm.model, p_fr == 0)
    JuMP.@constraint(pm.model, p_to == 0)
end

"""
    constraint_ohms_dc_branch_contingency(pm, i; nw=_PM.nw_id_default, online=1)

Create Ohm-law constraints for DC branch contingencies using auxiliary voltage
variables and add linking big-M constraints between the reference and auxiliary
voltages. The `online` flag controls whether the branch is considered online.
"""

function constraint_ohms_dc_branch_contingency(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_defaul, online = 1)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    r = branch["r"]
    p = _PM.ref(pm, nw, :dcpol)
    bigM = 2 *  _PM.ref(pm, nw, :busdc, f_bus)["Vdcmax"]

    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    constraint_ohms_dc_branch_outage(pm::_PM.AbstractPowerModel, nw, f_idx, t_idx, f_bus, t_bus, online, r, p, bigM)  
end

function constraint_ohms_dc_branch_outage(pm::_PM.AbstractPowerModel, n, f_idx, t_idx, f_bus, t_bus, online, r, p, bigM)
    p_fr = _PM.var(pm, n, :p_dcgrid, f_idx)
    p_to = _PM.var(pm, n, :p_dcgrid, t_idx)

    vm_fr = _PM.var(pm, n, :vdcm, f_bus)
    vm_to = _PM.var(pm, n, :vdcm, t_bus)   
    vm_fr_star = _PM.var(pm, n, :vdcm_star, f_bus)
    vm_to_star = _PM.var(pm, n, :vdcm_star, t_bus) 

    g = 1 / r
    JuMP.@constraint(pm.model, p_fr == p * g * vm_fr_star * (vm_fr_star - vm_to_star))
    JuMP.@constraint(pm.model, p_to == p * g * vm_to_star * (vm_to_star - vm_fr_star))


    JuMP.@constraint(pm.model, (online-1) * bigM <= vm_fr_star - vm_fr <= (1-online) * bigM)
    JuMP.@constraint(pm.model, (online-1) * bigM <= vm_to_star - vm_to <= (1-online) * bigM)
end

function constraint_fixed_converter_response(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    ref_id = get_reference_network_id(pm, nw; uc = true)
    
    pconv_ac_ref = _PM.var(pm, ref_id, :pconv_ac, i)
    pconv_ac = _PM.var(pm, nw, :pconv_ac, i)

    pconv_dc_ref = _PM.var(pm, ref_id, :pconv_dc, i)
    pconv_dc = _PM.var(pm, nw, :pconv_dc, i)

    JuMP.@constraint(pm.model, pconv_ac == pconv_ac_ref)
    JuMP.@constraint(pm.model, pconv_dc == pconv_dc_ref)
end

function constraint_fixed_demand_response(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    ref_id = get_reference_network_id(pm, nw; uc = true)
    
    pflex_ref = _PM.var(pm, ref_id, :pflex, i)
    pflex = _PM.var(pm, nw, :pflex, i)

    JuMP.@constraint(pm.model, pflex == pflex_ref)
end


function constraint_generator_inertial_response_to_contingency(pm::_PM.AbstractPowerModel, i::Int, gen_id; nw::Int = _PM.nw_id_default)
    # then calculate individual generator inertia of the particular generator i
    gen = _PM.ref(pm, nw, :gen, i)
    hg = gen["inertia_constants"] * gen["pmax"]
    pmin = gen["pmin"]
    pmax = gen["pmax"]

    constraint_generator_inertial_response_to_contingency(pm, i, gen_id, nw, hg, pmin, pmax)
end



function constraint_generator_inertial_response_to_contingency(pm, i, gen_id, nw, hg, pmin, pmax)
    ref_id = get_reference_network_id(pm, nw; uc = true)
    M = 2 * pmax  # big M value

    αg = _PM.var(pm, ref_id, :alpha_g, i)
    pgref = _PM.var(pm, ref_id, :pg, i)


    δPg = _PM.var(pm, ref_id, :pg, gen_id) # size of contingency
    δ = zeros(length(_PM.var(pm, ref_id, :alpha_g))) 
    δ[gen_id] = 1 #idx of generator outage
    
    pg = _PM.var(pm, nw, :pg, i)
    dpg_in = _PM.var(pm, nw, :dpg_in, i)

    α = _PM.var(pm, ref_id, :alpha_g)
    gens = _PM.ref(pm, nw, :gen)

    htot = JuMP.@expression(pm.model, sum([gens[g]["inertia_constants"] * gens[g]["pmax"] * (α[g] - δ[g]) for (g, gen) in gens]))



    # JuMP.@constraint(pm.model, pg == pgref + dpg_in)
    JuMP.@constraint(pm.model, dpg_in - (hg * (αg - δ[i]) / htot) * δPg  <=  M * (1 - (αg - δ[i])))
    JuMP.@constraint(pm.model, dpg_in - (hg * (αg - δ[i]) / htot) * δPg  >= -M * (1 - (αg - δ[i])))


    JuMP.@constraint(pm.model, pg <= pmax * (αg - δ[i]) * 3)
    JuMP.@constraint(pm.model, pg >= pmin * (αg - δ[i]) * 3)

    JuMP.@constraint(pm.model, pg - (pgref + dpg_in) <=  M * δ[i])
    JuMP.@constraint(pm.model, pg - (pgref + dpg_in) >= -M * δ[i])
end

