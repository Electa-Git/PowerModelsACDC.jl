""
function solve_acdcopf_iv(file::String, model_type, optimizer; kwargs...)
    data = _PM.parse_file(file)
    process_additional_data!(data)
    return solve_acdcopf_iv(data, model_type, optimizer; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!], kwargs...)
end

function solve_acdcopf_iv(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_acdcopf_iv; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!], kwargs...)
end

""
function build_acdcopf_iv(pm::_PM.AbstractIVRModel)
    _PM.variable_bus_voltage(pm)
    _PM.variable_branch_current(pm)
    _PM.variable_storage_power(pm)
    _PM.variable_gen_current(pm)
    _PM.variable_dcline_current(pm)

    _PM.objective_min_fuel_and_flow_cost(pm)

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dcgrid_voltage_magnitude(pm)
    variable_dc_converter(pm)
    variable_flexible_demand(pm)
    variable_load_current(pm)
    variable_pst(pm)
    variable_sssc(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_current_balance_ac(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_current_from(pm, i)
        _PM.constraint_current_to(pm, i)

        _PM.constraint_voltage_drop(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    for i in _PM.ids(pm, :flex_load)
        constraint_total_flexible_demand(pm, i)
    end
    
    for i in _PM.ids(pm, :fixed_load) 
        constraint_total_fixed_demand(pm, i)
    end

    for i in _PM.ids(pm, :pst)
        Memento.warn(_PM._LOGGER,"IVR formulation is not yet implemented for PSTs")
    end

    for i in _PM.ids(pm, :sssc)
        Memento.warn(_PM._LOGGER,"IVR formulation is not yet implemented for SSSCs")
    end

    for i in _PM.ids(pm, :busdc)
        constraint_current_balance_dc(pm, i)
    end
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for i in _PM.ids(pm, :convdc)
        constraint_converter_limits(pm, i)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
    end
end