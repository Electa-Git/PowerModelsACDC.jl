function solve_fcuc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_fcuc; ref_extensions = [add_ref_dcgrid!, ref_add_flex_load!, ref_add_pst!, ref_add_sssc!], kwargs...)
end

""
function build_fcuc(pm::_PM.AbstractPowerModel)

    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)

        _PM.constraint_model_voltage(pm; nw = n)
        constraint_voltage_dc(pm; nw = n)

        variable_inertia(pm; nw = n)
        variable_hvdc_contribution(pm; nw = n)
        variable_generator_contribution(pm; nw = n)
        variable_storage_contribution(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
    end

    for n in pm.ref[:it][:pm][:hour_ids]
        uc_model!(pm, n)
    end

    for n in pm.ref[:it][:pm][:cont_ids]
        contingency_contraints!(pm, n)
    end

    objective_min_cost_fcuc(pm; droop = true)    
end


function uc_model!(pm, n)
    _PM.variable_branch_power(pm; nw = n)
    _PM.variable_storage_power(pm; nw = n)
    variable_generator_states(pm; nw = n, uc = true)
    variable_flexible_demand(pm; nw = n)
    variable_pst(pm; nw = n)
    variable_sssc(pm; nw = n)
    variable_storage_on_off(pm; nw = n)
    variable_contingencies(pm, nw = n)

    for i in _PM.ids(pm, n, :ref_buses)
        _PM.constraint_theta_ref(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :bus)
        constraint_power_balance_ac(pm, i; nw = n) # add storage
    end
    
    for i in _PM.ids(pm, n, :branch)
        _PM.constraint_ohms_yt_from(pm, i; nw = n)
        _PM.constraint_ohms_yt_to(pm, i; nw = n)
        _PM.constraint_voltage_angle_difference(pm, i; nw = n)
        _PM.constraint_thermal_limit_from(pm, i; nw = n)
        _PM.constraint_thermal_limit_to(pm, i; nw = n)
    end
    for i in _PM.ids(pm, n, :busdc)
        constraint_power_balance_dc(pm, i; nw = n)
    end
    for i in _PM.ids(pm, n, :branchdc)
        constraint_ohms_dc_branch(pm, i; nw = n)
    end
    for i in _PM.ids(pm, n, :convdc)
        constraint_converter_losses(pm, i; nw = n)
        constraint_converter_current(pm, i; nw = n)
        constraint_conv_transformer(pm, i; nw = n)
        constraint_conv_reactor(pm, i; nw = n)
        constraint_conv_filter(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :flex_load)
        constraint_total_flexible_demand(pm, i; nw = n)
    end

    if haskey(pm.setting, "fix_cross_border_flows") && pm.setting["fix_cross_border_flows"] == true
        if !haskey(pm.setting, "borders")
            borders = [i for i in _PM.ids(pm, n, :borders)]
        else
            borders = [i for i in pm.setting["borders"]]
        end
        for i in borders
            constraint_fixed_xb_flows(pm, i; nw = n)
        end
    end

    gen_status = haskey(pm.setting, "use_gen_status") && pm.setting["use_gen_status"] == true
    for i in _PM.ids(pm, n, :gen)
        constraint_generator_on_off(pm, i; nw = n, use_status = gen_status)
        contstraint_unit_commitment(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :pst)
        constraint_ohms_y_from_pst(pm, i; nw = n)
        constraint_ohms_y_to_pst(pm, i; nw = n)
        constraint_limits_pst(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :sssc)
        constraint_ohms_y_from_sssc(pm, i; nw = n)
        constraint_ohms_y_to_sssc(pm, i; nw = n)
        constraint_limits_sssc(pm, i; nw = n)
    end

    constraint_generator_contingencies(pm; nw = n)
    constraint_converter_contingencies(pm; nw = n)

    if haskey(_PM.ref(pm, n), :tie_lines)
        constraint_tieline_contingencies(pm; nw = n)
    end

    if haskey(_PM.ref(pm, n), :storage)
        constraint_storage_contingencies(pm; nw = n)
    end

    if haskey(_PM.ref(pm, n), :storage)
        storage_constraints(pm, n; uc = true)
    end
end


function contingency_contraints!(pm, n)
    rn_idx = (n - get_reference_network_id(pm, n; uc = true))

    for i in _PM.ids(pm, n, :busdc)
        constraint_power_balance_dc(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :branchdc)
        constraint_ohms_dc_branch(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :convdc)
        constraint_converter_losses(pm, i; nw = n)
        constraint_converter_current(pm, i; nw = n)
        constraint_conv_transformer(pm, i; nw = n)
        constraint_conv_reactor(pm, i; nw = n)
        constraint_conv_filter(pm, i; nw = n)
        constraint_converter_power_balance(pm, i; nw = n)
    end
    
    gen_status = haskey(pm.setting, "use_gen_status") && pm.setting["use_gen_status"] == true
    for i in _PM.ids(pm, n, :gen)
        constraint_generator_on_off(pm, i; nw = n, use_status = gen_status, second_stage = true)
        constraint_generator_fcr_power_balance(pm, i; nw = n)
        constraint_generator_fcr_contribution(pm, i; nw = n)
        constraint_generator_fcr_contribution_abs(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :convdc)
        constraint_converter_reserve_contribution_absolute(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :storage)
        constraint_storage_fcr_contribution(pm, i; nw = n)
        constraint_storage_fcr_contribution_abs(pm, i; nw = n)
    end

    zone, area, cont_type = determine_zone_area_type_of_contingency(pm, rn_idx, n)

    if cont_type == "gen"
        if haskey(pm.setting, "hvdc_inertia_contribution")
            constraint_frequency_generator_contingency(pm, zone; nw = n, hvdc_contribution = pm.setting["hvdc_inertia_contribution"])
        else
            constraint_frequency_generator_contingency(pm, zone; nw = n, hvdc_contribution = false)
        end
    end

    if cont_type == "conv"
        if haskey(pm.setting, "hvdc_inertia_contribution")
            constraint_frequency_converter_contingency(pm, zone; nw = n, hvdc_contribution = pm.setting["hvdc_inertia_contribution"])
        else
            constraint_frequency_converter_contingency(pm, zone; nw = n, hvdc_contribution = false)
        end
    end

    if haskey(_PM.ref(pm, n), :storage) && cont_type == "storage"
        if haskey(pm.setting, "hvdc_inertia_contribution")
            constraint_frequency_storage_contingency(pm, zone; nw = n, hvdc_contribution = pm.setting["hvdc_inertia_contribution"])
        else
            constraint_frequency_storage_contingency(pm, zone; nw = n, hvdc_contribution = false)
        end
    end

    if haskey(_PM.ref(pm, n), :tie_lines) && cont_type == "tie_line" && !isempty(_PM.ref(pm, n, :areas))
        if haskey(pm.setting, "hvdc_inertia_contribution") 
            constraint_frequency_tieline_contingency(pm, area; nw = n, hvdc_contribution = pm.setting["hvdc_inertia_contribution"] == true)
        else
            constraint_frequency_tieline_contingency(pm, area; nw = n, hvdc_contribution = false)
        end
    end
end

function determine_zone_area_type_of_contingency(pm, rn_idx, n)
    zones = length(_PM.ref(pm, n, :zones))
    areas = length(_PM.ref(pm, n, :areas))

    zone_id = 0
    area_id = 0
    zone_ids = [z for z in _PM.ids(pm, n, :zones)]
    area_ids = [z for z in _PM.ids(pm, n, :areas)]
    if rn_idx <= zones * 3
        zone = Int(ceil(rn_idx / 3))
        if zone * 3 - rn_idx == 2
            type = "gen"
        elseif zone * 3 - rn_idx == 1
            type = "conv"
        elseif zone * 3 - rn_idx == 0
            type = "storage" 
        end
        zone_id = zone_ids[zone]
    else
        area = rn_idx - 3 * zones       
        type = "tie_line"
        area_id = 1
    end

    return zone_id, area_id, type
end
