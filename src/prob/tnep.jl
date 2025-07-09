export solve_tnep

""
function solve_tnep(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    # If there are no AC candicates defined, add empty dictionary
    process_additional_data!(data; tnep = true)

    return solve_tnep(data, model_type, solver; kwargs...)
end

function solve_tnep(data::Dict, model_type::Type, solver; kwargs...)
    # Check if data in multiperiod!
    if haskey(data, "multinetwork") && data["multinetwork"] == true
        return _PM.solve_model(data, model_type, solver, build_mp_tnep; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!], kwargs...)
    else
        return _PM.solve_model(data, model_type, solver, build_tnep; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!], kwargs...) 
    end
end


function solve_tnep(data::Dict, model_type::Type{T}, solver; kwargs...) where T <: _PM.AbstractBFModel
    # Check if data in multiperiod!
    if haskey(data, "multinetwork") && data["multinetwork"] == true
        return _PM.solve_model(data, model_type, solver, build_mp_tnep_bf; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!, ref_add_pst!,ref_add_sssc!, ref_add_flex_load!], kwargs...)
    else
        return _PM.solve_model(data, model_type, solver, build_tnep_bf; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!], kwargs...)
    end
end

## TNEP problem with AC & DC candidates

function build_tnep(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_storage_power(pm)

    variable_voltage_slack(pm)
    variable_active_dcbranch_flow(pm)
    variable_dc_converter(pm)
    variable_dcbranch_current(pm)
    variable_dcgrid_voltage_magnitude(pm)
    variable_flexible_demand(pm)
    variable_pst(pm)
    variable_sssc(pm)

    # new variables for TNEP problem
    _PM.variable_ne_branch_indicator(pm)
    _PM.variable_ne_branch_power(pm)
    _PM.variable_ne_branch_voltage(pm)
    variable_active_dcbranch_flow_ne(pm)
    variable_branch_ne(pm)
    variable_dc_converter_ne(pm)
    variable_dcbranch_current_ne(pm)
    variable_dcgrid_voltage_magnitude_ne(pm)

    objective_min_operational_capex_cost(pm)

    _PM.constraint_model_voltage(pm)
    _PM.constraint_ne_model_voltage(pm)
    constraint_voltage_dc(pm)
    constraint_voltage_dc_ne(pm)
    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_acdc_ne(pm, i)
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

    for i in _PM.ids(pm, :sssc)
        constraint_ohms_y_from_sssc(pm, i)
        constraint_ohms_y_to_sssc(pm, i)
        constraint_limits_sssc(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i)
        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end
    for i in _PM.ids(pm, :ne_branch)
        _PM.constraint_ne_ohms_yt_from(pm, i)
        _PM.constraint_ne_ohms_yt_to(pm, i)
        _PM.constraint_ne_voltage_angle_difference(pm, i)
        _PM.constraint_ne_thermal_limit_from(pm, i)
        _PM.constraint_ne_thermal_limit_to(pm, i)
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
        if pm.ref[:it][:pm][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
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
        if pm.ref[:it][:pm][:nw][_PM.nw_id_default][:convdc_ne][i]["islcc"] == 1
            constraint_conv_firing_angle_ne(pm, i)
        end
    end
end

## Multi-period TNEP problem with AC & DC candidates

""
function build_mp_tnep(pm::_PM.AbstractPowerModel)
    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)

        variable_voltage_slack(pm; nw = n)
        variable_active_dcbranch_flow(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_flexible_demand(pm; nw = n)
        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)

        # new variables for TNEP problem
        _PM.variable_ne_branch_indicator(pm; nw = n)
        _PM.variable_ne_branch_power(pm; nw = n)
        _PM.variable_ne_branch_voltage(pm; nw = n)
        variable_active_dcbranch_flow_ne(pm; nw = n)
        variable_branch_ne(pm; nw = n)
        variable_dc_converter_ne(pm; nw = n)
        variable_dcbranch_current_ne(pm; nw = n)
        variable_dcgrid_voltage_magnitude_ne(pm; nw = n)
    end

    objective_min_operational_capex_cost(pm)

    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.constraint_model_voltage(pm; nw = n)
        _PM.constraint_ne_model_voltage(pm; nw = n)
        constraint_voltage_dc(pm; nw = n)
        constraint_voltage_dc_ne(pm; nw = n)
        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i, nw = n)
        end

        for i in _PM.ids(pm, n, :bus)
            constraint_power_balance_acdc_ne(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branch)
            _PM.constraint_ohms_yt_from(pm, i; nw = n)
            _PM.constraint_ohms_yt_to(pm, i; nw = n)
            _PM.constraint_voltage_angle_difference(pm, i; nw = n)
            _PM.constraint_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_thermal_limit_to(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :flex_load)
            constraint_total_flexible_demand(pm, i; nw = n)
        end
        
        for i in _PM.ids(pm, n, :fixed_load) 
            constraint_total_fixed_demand(pm, i; nw = n)
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

        for i in _PM.ids(pm, n, :ne_branch)
            _PM.constraint_ne_ohms_yt_from(pm, i; nw = n)
            _PM.constraint_ne_ohms_yt_to(pm, i; nw = n)
            _PM.constraint_ne_voltage_angle_difference(pm, i; nw = n)
            _PM.constraint_ne_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_ne_thermal_limit_to(pm, i; nw = n)
            if n > 1
                constraint_candidate_acbranches_mp(pm, n, i)
            end
        end

        for i in _PM.ids(pm, n, :busdc)
            constraint_power_balance_dc_dcne(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :busdc_ne)
            constraint_power_balance_dcne_dcne(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branchdc)
            constraint_ohms_dc_branch(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :branchdc_ne)
            constraint_ohms_dc_branch_ne(pm, i; nw = n)
            constraint_branch_limit_on_off(pm, i; nw = n)
            if n > 1
                constraint_candidate_dcbranches_mp(pm, n, i)
            end
        end

        for i in _PM.ids(pm, n, :convdc)
            constraint_converter_losses(pm, i; nw = n)
            constraint_converter_current(pm, i; nw = n)
            constraint_conv_transformer(pm, i; nw = n)
            constraint_conv_reactor(pm, i; nw = n)
            constraint_conv_filter(pm, i; nw = n)
            if pm.ref[:it][:pm][:nw][n][:convdc][i]["islcc"] == 1
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
            if pm.ref[:it][:pm][:nw][n][:convdc_ne][i]["islcc"] == 1
                constraint_conv_firing_angle_ne(pm, i; nw = n)
            end
        end
        if haskey(_PM.ref(pm, n), :storage)
            storage_constraints(pm, n; uc = false)
        end
    end
end


# BRANCHFLOW TNEP problem with AC & DC candidates
function build_tnep_bf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    -PM.variable_storage_power(pm)

    _PM.variable_branch_current(pm)
    variable_voltage_slack(pm)
    _PM.constraint_model_current(pm)

    variable_active_dcbranch_flow(pm)
    variable_dc_converter(pm)
    variable_dcbranch_current(pm)
    variable_dcgrid_voltage_magnitude(pm)
    variable_flexible_demand(pm)
    variable_pst(pm)
    variable_sssc(pm)

    # new variables for TNEP problem
    _PM.variable_ne_branch_indicator(pm)
    _PM.variable_ne_branch_power(pm)
    variable_active_dcbranch_flow_ne(pm)
    variable_branch_ne(pm)
    variable_dc_converter_ne(pm)
    variable_dcbranch_current_ne(pm)
    variable_dcgrid_voltage_magnitude_ne(pm)
    
    objective_min_operational_capex_cost(pm)

    _PM.constraint_model_voltage(pm)
    _PM.constraint_ne_model_voltage(pm)
    constraint_voltage_dc(pm)
    constraint_voltage_dc_ne(pm)
    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end
    for i in _PM.ids(pm, :bus)
        constraint_power_balance_acne_dcne(pm, i)
    end
    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)
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

    for i in _PM.ids(pm, :sssc)
        constraint_ohms_y_from_sssc(pm, i)
        constraint_ohms_y_to_sssc(pm, i)
        constraint_limits_sssc(pm, i)
    end

    for i in _PM.ids(pm, :ne_branch)
        _PM.constraint_ne_ohms_yt_from(pm, i)
        _PM.constraint_ne_ohms_yt_to(pm, i)
        _PM.constraint_ne_voltage_angle_difference(pm, i)
        _PM.constraint_ne_thermal_limit_from(pm, i)
        _PM.constraint_ne_thermal_limit_to(pm, i)
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
        if pm.ref[:it][:pm][:nw][_PM.nw_id_default][:convdc][i]["islcc"] == 1
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
        if pm.ref[:it][:pm][:nw][_PM.nw_id_default][:convdc_ne][i]["islcc"] == 1
            constraint_conv_firing_angle_ne(pm, i)
        end
    end
end

# BRANCHFLOW Multi-period TNEP problem with AC & DC candidates
""
function build_mp_tnep_bf(pm::_PM.AbstractPowerModel)
    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        _PM.variable_branch_current(pm; nw = n)
        variable_voltage_slack(pm; nw = n)
        _PM.constraint_model_current(pm; nw = n)
        _PM.varaiable_storage_power(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_flexible_demand(pm; nw = n)
        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)
        
        # new variables for TNEP problem
        _PM.variable_ne_branch_indicator(pm; nw = n)
        _PM.variable_ne_branch_power(pm; nw = n)
        _PM.variable_ne_branch_voltage(pm; nw = n)
        variable_active_dcbranch_flow_ne(pm; nw = n)
        variable_branch_ne(pm; nw = n)
        variable_dc_converter_ne(pm; nw = n) # add more variables in variableconv.jl
        variable_dcbranch_current_ne(pm; nw = n)
        variable_dcgrid_voltage_magnitude_ne(pm; nw = n)
    end
    
    objective_min_operational_capex_cost(pm)

    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.constraint_model_voltage(pm; nw = n)
        _PM.constraint_ne_model_voltage(pm; nw = n)
        constraint_voltage_dc(pm; nw = n)
        constraint_voltage_dc_ne(pm; nw = n)
        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i, nw = n)
        end

        for i in _PM.ids(pm, n, :bus)
            constraint_power_balance_acne_dcne(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branch)
            _PM.constraint_ohms_yt_from(pm, i; nw = n)
            _PM.constraint_ohms_yt_to(pm, i; nw = n)
            _PM.constraint_voltage_angle_difference(pm, i; nw = n)
            _PM.constraint_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_thermal_limit_to(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :flex_load)
            constraint_total_flexible_demand(pm, i; nw = n)
        end
        
        for i in _PM.ids(pm, n, :fixed_load) 
            constraint_total_fixed_demand(pm, i; nw = n)
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

        for i in _PM.ids(pm, n, :ne_branch)
            _PM.constraint_ne_ohms_yt_from(pm, i; nw = n)
            _PM.constraint_ne_ohms_yt_to(pm, i; nw = n)
            _PM.constraint_ne_voltage_angle_difference(pm, i; nw = n)
            _PM.constraint_ne_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_ne_thermal_limit_to(pm, i; nw = n)
            if n > 1
                constraint_candidate_acbranches_mp(pm, n, i)
            end
        end

        for i in _PM.ids(pm, n, :busdc)
            constraint_power_balance_dc_dcne(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :busdc_ne)
            constraint_power_balance_dcne_dcne(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branchdc)
            PowerModelsACDC.constraint_ohms_dc_branch(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :branchdc_ne)
            constraint_ohms_dc_branch_ne(pm, i; nw = n)
            constraint_branch_limit_on_off(pm, i; nw = n)
            if n > 1
                constraint_candidate_dcbranches_mp(pm, n, i)
            end
        end

        for i in _PM.ids(pm, n, :convdc)
            constraint_converter_losses(pm, i; nw = n)
            constraint_converter_current(pm, i; nw = n)
            constraint_conv_transformer(pm, i; nw = n)
            constraint_conv_reactor(pm, i; nw = n)
            constraint_conv_filter(pm, i; nw = n)
            if pm.ref[:it][:pm][:nw][n][:convdc][i]["islcc"] == 1
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
            if pm.ref[:it][:pm][:nw][n][:convdc_ne][i]["islcc"] == 1
                constraint_conv_firing_angle_ne(pm, i; nw = n)
            end
        end

        if haskey(_PM.ref(pm, n), :storage)
            storage_constraints(pm, n; uc = false)
        end
    end
end

