"""
    solve_rdopf(file::String, model_type::Type, optimizer; kwargs...)

File-based entrypoint to solve a redispatch (RD) Optimal Power Flow problem.

# Inputs
- `file::String` : Path to the input data file (PowerModels / MATPOWER style).
- `model_type::Type` : PowerModels model type used to build the JuMP model.
- `optimizer` : JuMP optimizer/solver (e.g., Ipopt, Gurobi).
- `kwargs...` : Forwarded keyword arguments to the PowerModels solve entrypoint
  (`_PM.solve_model`). Common keys include `setting` and `ref_extensions`. By
  default reference extensions for DC grids, PST, SSSC, flexible loads and DC
  generators are applied.

# Returns
- A PowerModels-style solution dictionary containing variable values, objective
  (when applicable) and solver termination information.

# Behavior
- Parses the input file into a PowerModels data dictionary, applies package-
  specific preprocessing via `process_additional_data!` and delegates to the
  data-based entrypoint that builds and solves the redispatch model.
"""
function solve_rdopf(file::String, model_type::Type, optimizer; kwargs...)
    data = PowerModels.parse_file(file)
    process_additional_data!(data)
    return _PM.solve_model(data, model_type, optimizer, build_rdopf; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
end
"""
    solve_rdopf(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)

Data-based entrypoint to solve a redispatch OPF given an already-parsed data dictionary.

# Inputs
- `data::Dict{String,Any}` : Parsed PowerModels data dictionary.
- `model_type::Type` : PowerModels model type used to build the JuMP model.
- `optimizer` : JuMP optimizer/solver.
- `kwargs...` : Forwarded keyword arguments to `_PM.solve_model`.

# Returns
- A PowerModels-style solution dictionary.

# Behavior
- Calls `_PM.solve_model` with `build_rdopf` as the builder and the default set
  of reference extensions (override via `kwargs[:ref_extensions]`).
"""
function solve_rdopf(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_rdopf; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
end
"""
    build_rdopf(pm::_PM.AbstractPowerModel)

Build the JuMP model for a Redispatch Optimal Power Flow (RD-OPF) problem.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder containing parsed
  data, settings, and the JuMP model to be populated.

# Details
This builder constructs a redispatch model (single-period) by:
- creating AC variables: bus voltages, generator active power, branch power,
  storage power;
- adding DC variables and components: active DC branch flows, DC branch currents,
  DC converters, DC grid voltage magnitudes and DC generator power variables;
- adding flexible demand, PST, SSSC, and redispatch-specific variables;
- optionally adding generator state variables and inertia-related modeling when
  `pm.setting["inertia_limit"] == true`;
- assembling an objective appropriate for redispatch:
  - if `inertia_limit` setting is enabled, uses inertia-aware redispatch objective,
  - otherwise uses standard redispatch objective;
- adding constraints:
  - reference bus angle constraints,
  - AC power-balance at buses,
  - branch Ohm and thermal/angle constraints,
  - DC power-balance and DC branch Ohm constraints,
  - converter losses, current limits and device-specific constraints,
  - PST/SSSC device equations and limits,
  - flexible demand aggregation and generator redispatch constraints,
  - generator on/off or redispatch constraints depending on settings;
- applying fixed cross-border flow constraints when requested (`pm.setting["fix_cross_border_flows"]`);
- applying inertia limits per configured zones if `pm.setting["inertia_limit"] == true`.

# Notes
- The builder prefers existing PowerModels primitives for constraints and
  variables; it also calls ACDC-specific primitives (e.g., converter firing-angle
  constraint) when required by device configuration (e.g., LCC converters).
- `pm.setting` keys used by this builder include:
  - `"fix_cross_border_flows"` : Boolean, apply fixed cross-border flow constraints.
  - `"borders"` : Optional list of border ids for fixed flows.
  - `"inertia_limit"` : Boolean, enable inertia-limit modeling and inertia-aware objective.
  - `"use_gen_status"` : (indirectly used) influence generator on/off modeling.
"""
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
