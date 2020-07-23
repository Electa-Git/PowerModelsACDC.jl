export run_acdcopf_bf

""
function run_acdcopf_bf(file::String, model_type::Type{T}, solver; kwargs...) where T <: _PM.AbstractBFModel
    data = _PM.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_acdcopf_bf(data, model_type, solver; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function run_acdcopf_bf(data::Dict{String,Any}, model_type::Type{T}, solver; kwargs...) where T <: _PM.AbstractBFModel
    return _PM.run_model(data, model_type, solver, post_acdcopf_bf; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

function post_acdcopf_bf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_branch_current(pm)

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dc_converter(pm)
    variable_dcgrid_voltage_magnitude(pm)

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
        if pm.ref[:nw][pm.cnw][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i)
        end
    end
end
