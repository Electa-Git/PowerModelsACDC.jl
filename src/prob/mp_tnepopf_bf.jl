export run_mp_tnepopf_bf

""
function run_mp_tnepopf_bf(file::String, model_type::Type{T}, solver; setting = s, kwargs...)  where T <: _PM.AbstractBFModel
    data = _PM.parse_file(file)
    return run_mp_tnepopf_bf(data, model_type, solver; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!], kwargs...)
end

""
function run_mp_tnepopf_bf(data::Dict{String,Any}, model_type::Type{T}, solver; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!], setting = s, kwargs...) where T <: _PM.AbstractBFModel
    if setting["process_data_internally"] == true
        # PowerModelsACDC.process_additional_data!(data)
        process_additional_data!(data)
    end
    s = setting
    return _PM.run_model(data, model_type, solver, post_mp_tnepopf_bf; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!], setting = s, kwargs...)
end

""
function post_mp_tnepopf_bf(pm::_PM.AbstractPowerModel)
    # for (n, networks) in pm.ref[:nw]
    #     PowerModelsACDC.add_ref_dcgrid!(pm, n)
    #     add_candidate_dcgrid!(pm, n)
    # end
    for (n, networks) in pm.ref[:nw]
        _PM.variable_voltage(pm; nw = n)
        _PM.variable_generation(pm; nw = n)
        _PM.variable_branch_flow(pm; nw = n)

        _PM.variable_branch_current(pm; nw = n)
        variable_voltage_slack(pm; nw = n)
        _PM.constraint_model_current(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        # new variables for TNEP problem
        variable_active_dcbranch_flow_ne(pm; nw = n)
        variable_branch_ne(pm; nw = n)
        variable_dc_converter_ne(pm; nw = n) # add more variables in variableconv.jl
        variable_dcbranch_current_ne(pm; nw = n)
        variable_dcgrid_voltage_magnitude_ne(pm; nw = n)
    end
    objective_min_cost(pm)
    for (n, networks) in pm.ref[:nw]
        _PM.constraint_model_voltage(pm; nw = n)
        constraint_voltage_dc(pm)
        constraint_voltage_dc_ne(pm)
        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i, nw = n)
        end

        for i in _PM.ids(pm, n, :bus)
            constraint_kcl_shunt_ne(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branch)
            _PM.constraint_flow_losses(pm, i; nw = n)
            _PM.constraint_voltage_magnitude_difference(pm, i; nw = n)
            _PM.constraint_voltage_angle_difference(pm, i; nw = n)
            _PM.constraint_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_thermal_limit_to(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :busdc)
            constraint_kcl_shunt_dcgrid_ne(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :busdc_ne)
            constraint_kcl_shunt_dcgrid_ne_bus(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branchdc)
            PowerModelsACDC.constraint_ohms_dc_branch(pm, i; nw = n)
        end
        for i in _PM.ids(pm, :branchdc_ne)
            constraint_ohms_dc_branch_ne(pm, i; nw = n)
            constraint_branch_limit_on_off(pm, i; nw = n)
            if n > 1
                constraint_candidate_branches_mp(pm, n, i)
            end
        end

        for i in _PM.ids(pm, :convdc)
            constraint_converter_losses(pm, i; nw = n)
            constraint_converter_current(pm, i; nw = n)
            constraint_conv_transformer(pm, i; nw = n)
            constraint_conv_reactor(pm, i; nw = n)
            constraint_conv_filter(pm, i; nw = n)
            if pm.ref[:nw][n][:convdc][i]["islcc"] == 1
                constraint_conv_firing_angle(pm, i; nw = n)
            end
        end
        for i in _PM.ids(pm, n, :convdc_ne)
            constraint_converter_losses_ne(pm, i; nw = n)
            constraint_converter_current_ne(pm, i; nw = n)
            constraint_converter_limit_on_off(pm, i; nw = n)
            if n > 1
                constraint_candidate_converters_mp(pm, n, i)
            end
            constraint_conv_transformer_ne(pm, i; nw = n)
            constraint_conv_reactor_ne(pm, i; nw = n)
            constraint_conv_filter_ne(pm, i; nw = n)
            if pm.ref[:nw][n][:convdc_ne][i]["islcc"] == 1
                constraint_conv_firing_angle_ne(pm, i; nw = n)
            end
        end
    end
end
