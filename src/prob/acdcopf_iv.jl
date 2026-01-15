export solve_acdcopf_iv

"""
    solve_acdcopf_iv(file::String, model_type::Type, optimizer; kwargs...)

Solve an AC/DC Optimal Power Flow (OPF) problem using the IVR (current-voltage,
IV) formulation for the AC network.

# Inputs
- `file::String` : Path to the input data file (e.g. MATPOWER `.m`).
- `model_type::Type` : PowerModels model type (e.g. `IVRPowerModel` or other
  compatible IV-formulation model types).
- `optimizer` : JuMP optimizer/solver (e.g. Ipopt).
- `kwargs...` : Forwarded keyword arguments (settings, `ref_extensions`, etc.).
  By default the function applies reference-extensions for DC grids, PST,
  SSSC and flexible loads.

# Returns
- PowerModels-style solution dictionary containing variable values, objective
  (if applicable) and solver termination status.

# Behavior
- Parses the file (if file-based entrypoint used), performs package-specific
  preprocessing via `process_additional_data!` and delegates to the data-based
  entrypoint. The data-based entrypoint calls `_PM.solve_model` with the IVR
  builder `build_acdcopf_iv` (or a multi-network variant when `data["multinetwork"]`
  is true).
"""
function solve_acdcopf_iv(file::String, model_type, optimizer; kwargs...)
    data = _PM.parse_file(file)
    process_additional_data!(data)
    return solve_acdcopf_iv(data, model_type, optimizer; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!], kwargs...)
end

"""
    solve_acdcopf_iv(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)

Data-based entrypoint for the IVR AC/DC OPF.

# Inputs
- `data::Dict{String,Any}` : Parsed PowerModels data dictionary.
- `model_type::Type` : PowerModels model type to build the JuMP model.
- `optimizer` : JuMP optimizer/solver.
- `kwargs...` : Forwarded keyword arguments.

# Returns
- Solution dictionary from `_PM.solve_model`.

# Behavior
Selects the single-network IV builder `build_acdcopf_iv` or the multi-network
builder `mp_build_acdcopf_iv` depending on `data["multinetwork"]` and calls
`_PM.solve_model`, applying the same default reference-extensions as the
file-based wrapper.
"""
function solve_acdcopf_iv(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    if haskey(data, "multinetwork") && data["multinetwork"] == true
        return _PM.solve_model(data, model_type, optimizer, mp_build_acdcopf_iv; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!], kwargs...)
    else
        return _PM.solve_model(data, model_type, optimizer, build_acdcopf_iv; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!], kwargs...)
    end
end
"""
    build_acdcopf_iv(pm::_PM.AbstractIVRModel)

Build the JuMP model for a single-network IVR (current-voltage) AC/DC problem.

# Inputs
- `pm::_PM.AbstractIVRModel` : PowerModels internal model holder for IV formulations.

# Details
- Adds IV-specific variables (bus voltages, branch currents, generator currents,
  DC line currents, storage power).
- Adds DC-specific and special-component variables (DC branch flows/currents,
  converters, DC grid voltages, flexible loads, load currents, PST, SSSC).
- Adds IV formulation constraints:
  - current balance at AC buses (`constraint_current_balance_ac`),
  - branch current definitions and voltage drop (`_PM.constraint_current_from`,
    `_PM.constraint_current_to`, `_PM.constraint_voltage_drop`),
  - thermal and voltage-angle limits,
  - DC current/Ohm constraints and converter constraints.
- Adds objective using IVR objective primitive (`_PM.objective_min_fuel_and_flow_cost`).
- Emits warnings for components not yet implemented in IVR (e.g., PST/SSSC handling).
"""
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
end
"""
    mp_build_acdcopf_iv(pm::_PM.AbstractIVRModel)

Build the JuMP model for a multinetwork IVR (current-voltage) AC/DC problem.

# Inputs
- `pm::_PM.AbstractIVRModel` : PowerModels internal model holder containing multi-network data
  in `pm.ref[:it][:pm][:nw]`.

# Details
- Iterates over networks declared in `pm.ref[:it][:pm][:nw]` and creates
  network-scoped IV variables and constraints for each network:
  - bus voltages, branch currents, generator currents, DC-line currents, storage powers,
  - DC branch flows/currents, converters, DC grid voltages, flexible/fixed loads,
  - PST and SSSC variables (with warnings if IV handling is incomplete).
- Adds per-network IV constraints (current balances, current->voltage relations,
  voltage drops, thermal limits, DC Ohm laws, converter constraints).
- Applies cross-border constraints when `pm.setting["fix_cross_border_flows"]` is true.
- Assembles the global IVR objective via `_PM.objective_min_fuel_and_flow_cost(pm)`.
"""
function mp_build_acdcopf_iv(pm::_PM.AbstractIVRModel)
    # Create variables for each network
    for (n, _) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_branch_current(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)
        _PM.variable_gen_current(pm; nw = n)
        _PM.variable_dcline_current(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_flexible_demand(pm; nw = n)
        variable_load_current(pm; nw = n)
        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)
    end

    # Per-network constraints
    for (n, _) in pm.ref[:it][:pm][:nw]
        _PM.constraint_model_voltage(pm; nw = n)

        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :bus)
            constraint_current_balance_ac(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branch)
            _PM.constraint_current_from(pm, i; nw = n)
            _PM.constraint_current_to(pm, i; nw = n)

            _PM.constraint_voltage_drop(pm, i; nw = n)
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
            Memento.warn(_PM._LOGGER,"IVR formulation is not yet implemented for PSTs (nw = $n)")
        end

        for i in _PM.ids(pm, n, :sssc)
            Memento.warn(_PM._LOGGER,"IVR formulation is not yet implemented for SSSCs (nw = $n)")
        end

        for i in _PM.ids(pm, n, :busdc)
            constraint_current_balance_dc(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :branchdc)
            constraint_ohms_dc_branch(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :convdc)
            constraint_converter_limits(pm, i; nw = n)
            constraint_converter_losses(pm, i; nw = n)
            constraint_converter_current(pm, i; nw = n)
            constraint_conv_transformer(pm, i; nw = n)
            constraint_conv_reactor(pm, i; nw = n)
            constraint_conv_filter(pm, i; nw = n)
        end
    end

    # Cross-border fixed flows (global handling)
    if haskey(pm.setting, "fix_cross_border_flows") && pm.setting["fix_cross_border_flows"] == true
        borders = haskey(pm.setting, "borders") ? pm.setting["borders"] : _PM.ids(pm, :borders)
        if !haskey(pm.setting, "borders")
            borders = [i for i in _PM.ids(pm, n, :borders)]
        else
            borders = [i for i in pm.setting["borders"]]
        end
        for i in borders
            constraint_fixed_xb_flows(pm, i; nw = n)
        end
    end

    # Global objective assembly (IVR-specific)
    _PM.objective_min_fuel_and_flow_cost(pm)
end