export solve_acdcopf_bf

""
function solve_acdcopf_bf(file::String, model_type::Type{T}, solver; kwargs...) where T <: _PM.AbstractBFModel
    data = _PM.parse_file(file)
    process_additional_data!(data)
    return solve_acdcopf_bf(data, model_type, solver; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_flex_load!], kwargs...)
end

""
function solve_acdcopf_bf(data::Dict{String,Any}, model_type::Type{T}, solver; kwargs...) where T <: _PM.AbstractBFModel
    return _PM.solve_model(data, model_type, solver, build_acdcopf_bf; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_flex_load!], kwargs...)
end

function build_acdcopf_bf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_storage_power(pm)
    _PM.variable_branch_current(pm)

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dc_converter(pm)
    variable_dcgrid_voltage_magnitude(pm)
    variable_flexible_demand(pm)
    variable_pst(pm)

    _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_current(pm)
    constraint_voltage_dc(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_ac(pm, i)
    end

    for i in _PM.ids(pm, :branch)

        _PM.constraint_power_losses(pm, i)
        _PM.constraint_voltage_magnitude_difference(pm, i)


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
        constraint_ohms_y_from_pst(pm, i)
        constraint_ohms_y_to_pst(pm, i)
        constraint_limits_pst(pm, i)
    end

    for i in _PM.ids(pm, :busdc)
        constraint_power_balance_dc(pm, i)
    end
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
        constraint_dc_branch_current(pm, i)
    end
    for i in _PM.ids(pm, :convdc)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
        if pm.ref[:it][:pm][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i)
        end
    end
end
