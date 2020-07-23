export run_tnepopf

""
function run_tnepopf(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    process_additional_data!(data)
    return run_tnepopf(data, model_type, solver; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!], kwargs...)
end

""
function run_tnepopf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.run_model(data, model_type, solver, post_tnepopf; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!], kwargs...)
end

""
function post_tnepopf(pm::_PM.AbstractPowerModel)
    # PowerModelsACDC.add_ref_dcgrid!(pm)
    # add_candidate_dcgrid!(pm)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    variable_voltage_slack(pm)

    variable_active_dcbranch_flow(pm)
    variable_dc_converter(pm)
    variable_dcbranch_current(pm)
    variable_dcgrid_voltage_magnitude(pm)

    # new variables for TNEP problem
    variable_active_dcbranch_flow_ne(pm)
    variable_branch_ne(pm)
    variable_dc_converter_ne(pm)# add more variables in variableconv.jl
    variable_dcbranch_current_ne(pm)
    variable_dcgrid_voltage_magnitude_ne(pm)
    objective_min_cost(pm)

    _PM.constraint_model_voltage(pm)
    constraint_voltage_dc(pm)
    constraint_voltage_dc_ne(pm)
    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end
    for i in _PM.ids(pm, :bus)
        constraint_power_balance_ac_dcne(pm, i)
    end
    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i)
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    for i in _PM.ids(pm, :busdc)
        constraint_power_balance_dc_dcne(pm, i)
    end
    for i in _PM.ids(pm, :busdc_ne)
        constraint_power_balance_dcne_dcne(pm, i)
    end

    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for i in _PM.ids(pm, :branchdc_ne)
        constraint_ohms_dc_branch_ne(pm, i)
        constraint_branch_limit_on_off(pm, i)
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

    for i in _PM.ids(pm, :convdc_ne)
        constraint_converter_losses_ne(pm, i)
        constraint_converter_current_ne(pm, i)
        constraint_converter_limit_on_off(pm, i)
        constraint_conv_transformer_ne(pm, i)
        constraint_conv_reactor_ne(pm, i)
        constraint_conv_filter_ne(pm, i)
        if pm.ref[:nw][pm.cnw][:convdc_ne][i]["islcc"] == 1
            constraint_conv_firing_angle_ne(pm, i)
        end
    end
end
