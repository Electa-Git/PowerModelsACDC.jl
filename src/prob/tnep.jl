export solve_tnep
"""
    solve_tnep(file::String, model_type::Type, solver; kwargs...)

File-based entrypoint to solve a Transmission Network Expansion Planning (TNEP)
problem. Parses the input file, applies package-specific preprocessing
(including candidate addition when `tnep = true`), and delegates to the data-
based entrypoint.

# Inputs
- `file::String` : Path to a PowerModels / MATPOWER style input file.
- `model_type::Type` : PowerModels model type used to build the JuMP model.
- `solver` : JuMP optimizer/solver (e.g., Ipopt, Gurobi).
- `kwargs...` : Forwarded keyword arguments to the PowerModels solve entrypoint
  (settings, `ref_extensions`, etc.).

# Returns
- PowerModels-style solution dictionary (variable values, objective, solver status).

# Behavior
- Calls `process_additional_data!(data; tnep = true)` to ensure TNEP candidate
  structures are present.
- Delegates to `solve_tnep(data::Dict, ...)`.
"""
function solve_tnep(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    # If there are no AC candicates defined, add empty dictionary
    process_additional_data!(data; tnep = true)

    return solve_tnep(data, model_type, solver; kwargs...)
end
"""
    solve_tnep(data::Dict, model_type::Type, solver; kwargs...)

Data-based entrypoint that selects the appropriate TNEP builder for single-
period or multi-period problems and calls the PowerModels solve pipeline.

# Inputs
- `data::Dict` : Parsed PowerModels data dictionary (may include `multinetwork` flag).
- `model_type::Type` : PowerModels model type used to build the JuMP model.
- `solver` : JuMP optimizer/solver.
- `kwargs...` : Forwarded keyword arguments.

# Returns
- Solution dictionary from `_PM.solve_model`.

# Behavior
- If `data["multinetwork"] == true` uses the multi-period builder `build_mp_tnep`,
  otherwise uses the single-period builder `build_tnep`.
- Adds default reference extensions required for TNEP (AC/DC references, candidate
  handling, NE branch primitives, PST/SSSC, flexible loads, DC generators).
"""
function solve_tnep(data::Dict, model_type::Type, solver; kwargs...)
    # Check if data in multiperiod!
    if haskey(data, "multinetwork") && data["multinetwork"] == true
        return _PM.solve_model(data, model_type, solver, build_mp_tnep; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
    else
        return _PM.solve_model(data, model_type, solver, build_tnep; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...) 
    end
end
"""
    solve_tnep(data::Dict, model_type::Type{T}, solver; kwargs...) where T <: _PM.AbstractBFModel

BF-specialized data entrypoint for TNEP when the chosen model is a Branch-Flow
variant. Selects BF-specific builders that include branch-current variables and
BF constraints.

# Inputs
- `data::Dict` : Parsed data dictionary.
- `model_type::Type{T}` : BF-compatible PowerModels model type.
- `solver` : JuMP optimizer/solver.
- `kwargs...` : Forwarded keyword arguments.

# Returns
- Solution dictionary from `_PM.solve_model` using BF builders (`build_tnep_bf`
  or `build_mp_tnep_bf`).
"""
function solve_tnep(data::Dict, model_type::Type{T}, solver; kwargs...) where T <: _PM.AbstractBFModel
    # Check if data in multiperiod!
    if haskey(data, "multinetwork") && data["multinetwork"] == true
        return _PM.solve_model(data, model_type, solver, build_mp_tnep_bf; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!, ref_add_pst!,ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
    else
        return _PM.solve_model(data, model_type, solver, build_tnep_bf; ref_extensions = [add_ref_dcgrid!, add_candidate_dcgrid!, _PM.ref_add_on_off_va_bounds!, _PM.ref_add_ne_branch!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
    end
end
"""
    build_tnep(pm::_PM.AbstractPowerModel)

Build a single-period Transmission Network Expansion Planning (TNEP) JuMP model.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder (parsed data, settings, JuMP model).

# Details
- Adds AC and DC operational variables (bus voltages, generator powers, branch
  powers, DC flows/currents, converters, DC grid voltages, flexible demand).
- Adds TNEP candidate variables (NE branch indicators, candidate branch power,
  voltage variables, DC candidate variables) and related NE primitives.
- Applies model constraints:
  - normal AC/DC power balance and device constraints,
  - NE-specific Ohm/limit constraints for candidate elements,
  - PST/SSSC device constraints and limits,
  - converter losses, current limits and special-device constraints.
- Sets the combined operational + CAPEX objective via `objective_min_operational_capex_cost(pm)`.

# Notes
- Candidate-device on/off and cost linking is handled by NE primitives added via
  `_PM.variable_ne_branch_indicator` and related functions.
"""
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
    variable_dcgenerator_power(pm)
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
"""
    build_mp_tnep(pm::_PM.AbstractPowerModel)

Build a multi-period / multi-network TNEP JuMP model.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder containing `pm.ref[:it][:pm][:nw]`.

# Details
- For each network/time index `n` creates network-scoped operational variables
  and TNEP candidate variables (same primitives as single-period builder but
  with `nw = n` scope).
- Adds per-network constraints (AC/DC power balance, branch/NE constraints,
  PST/SSSC/device limits).
- Optionally enforces multi-period candidate linking (candidate availability /
  construction timing) via NE primitives and additional constraints where
  implemented.
- Assembles the combined operational + CAPEX objective via `objective_min_operational_capex_cost(pm)`.
"""
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
        variable_dcgenerator_power(pm; nw = n)
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

"""
    build_tnep_bf(pm::_PM.AbstractPowerModel)

Branch-Flow variant of the single-period TNEP builder. Adds BF-specific
variables (branch currents) and BF constraint primitives in place of standard
Ohm/admittance constraints.

# Notes
- Mirrors `build_tnep` but uses `_PM.constraint_model_current` and BF primitives.
"""
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
    variable_dcgenerator_power(pm)
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

"""
    build_mp_tnep_bf(pm::_PM.AbstractPowerModel)

Branch-Flow variant of the multi-period TNEP builder. Adds BF-specific
variables and constraints for each network/time `nw` and mirrors the logic of
`build_mp_tnep` with BF primitives and candidate handling per period.

# Notes
- Mirrors `build_mp_tnep` but adds `_PM.constraint_model_current(pm; nw = n)` and
  other BF-specific variable/constraint primitives per network.
"""
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
        variable_dcgenerator_power(pm; nw = n)
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

