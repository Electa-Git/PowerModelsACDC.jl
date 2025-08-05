function solve_rdopf(file::String, model_type::Type, optimizer; kwargs...)
    data = PowerModels.parse_file(file)
    process_additional_data!(data)
    return _PM.solve_model(data, model_type, optimizer, build_rdopf; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
end

function solve_rdopf(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_rdopf; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
end

""
function build_rdopf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_storage_power(pm)
    _PM.constraint_model_voltage(pm)

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dc_converter(pm)
    variable_dcgrid_voltage_magnitude(pm)
    variable_dcgenerator_power(pm)
    constraint_voltage_dc(pm)
    variable_pst(pm)
    variable_sssc(pm)
    variable_flexible_demand(pm)
    variable_generator_redispatch(pm)

    if haskey(pm.setting, "inertia_limit") && pm.setting["inertia_limit"] == true
        variable_generator_state(pm)
    end

    if haskey(pm.setting, "inertia_limit") && pm.setting["inertia_limit"] == true
        objective_min_rd_cost_inertia(pm)
    else
        objective_min_rd_cost(pm)
    end

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
         constraint_power_balance_ac(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    for i in _PM.ids(pm, :busdc)
        constraint_power_balance_dc(pm, i)
    end
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for i in _PM.ids(pm, :convdc)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
        if pm.ref[:it][:pm][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            _PMACDC.constraint_conv_firing_angle(pm, i)
        end
        if haskey(pm.setting, "fix_converter_setpoints") && pm.setting["fix_converter_setpoints"] == true
            constraint_active_conv_setpoint(pm, i; slack = 0.01)
        end
    end

    for i in _PM.ids(pm, :pst)
        constraint_ohms_y_from_pst(pm, i)
        constraint_ohms_y_to_pst(pm, i)
        constraint_limits_pst(pm, i)
    end

    for i in _PM.ids(pm, :sssc)
        constraint_ohms_y_from_sssc(pm, i)
        constraint_ohms_y_to_sssc(pm, i)
        constraint_limits_sssc(pm, i)
    end

    for i in _PM.ids(pm, :flex_load)
        constraint_total_flexible_demand(pm, i)
    end

    for i in _PM.ids(pm, :gen)
        if haskey(pm.setting, "inertia_limit") && pm.setting["inertia_limit"] == true
            constraint_generator_on_off(pm, i)
        else
            constraint_generator_redispatch(pm, i)
        end
    end

    if haskey(pm.setting, "fix_cross_border_flows") && pm.setting["fix_cross_border_flows"] == true
        if !haskey(pm.setting, "borders")
            borders = [i for i in _PM.ids(pm, :borders)]
        else
            borders = [i for i in pm.setting["borders"]]
        end
        for i in borders
            constraint_fixed_xb_flows(pm, i)
        end
    end

    if haskey(pm.setting, "inertia_limit") && pm.setting["inertia_limit"] == true
        zones = [i for i in _PM.ids(pm, :inertia_limit)]
        for i in zones
            constraint_inertia_limit(pm, i)
        end
    end
end
