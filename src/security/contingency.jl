
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


########################################
### Generator Constraints ##############
########################################

function constraint_generator_contingencies(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    constraint_generator_contingency(pm; nw = nw)
    constraint_select_generator_contingency(pm; nw = nw)
    for i in _PM.ids(pm, nw, :gen)
        constraint_generator_contingency_indicator(pm, i; nw = nw)
    end
end

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

function constraint_converter_contingencies(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    constraint_converter_contingency(pm; nw = nw)
    constraint_select_converter_contingency(pm; nw = nw)
    for i in _PM.ids(pm, nw, :convdc)
        constraint_converter_contingency_indicator(pm, i; nw = nw)
    end
end

function constraint_converter_contingency(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
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
                constraint_converter_contingency(pm, c, reference_network_idx, zone)
            end
        end
    end
end

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

function constraint_converter_contingency(pm::_PM.AbstractPowerModel, i::Int, n::Int, zone)
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

########################################
### Tieline Constraints ################
########################################

function constraint_tieline_contingencies(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    constraint_tieline_contingency(pm; nw = nw)
    constraint_select_tieline_contingency(pm; nw = nw)
    for i in _PM.ids(pm, nw, :tie_lines)
        constraint_tieline_contingency_indicator(pm, i; nw = nw)
    end
end


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

function constraint_storage_contingencies(pm::_PM.AbstractPowerModel; nw::Int = _PM.nw_id_default)
    constraint_storage_contingency(pm; nw = nw)
    constraint_select_storage_contingency(pm; nw = nw)
    for i in _PM.ids(pm, nw, :storage)
        constraint_storage_contingency_indicator(pm, i; nw = nw)
    end
end


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