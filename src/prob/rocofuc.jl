"""
    solve_fcuc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)

Entry point to solve a Frequency-Constrained Unit Commitment (FCUC) problem.

# Inputs
- `data::Dict{String,Any}` : Parsed PowerModels data dictionary (multi-network expected).
- `model_type::Type` : PowerModels model type to use when building JuMP models.
- `optimizer` : JuMP optimizer/solver (e.g., Ipopt, Gurobi).
- `kwargs...` : Forwarded keyword arguments to `_PM.solve_model` (settings, `ref_extensions`, etc.).
  Default reference extensions applied: `add_ref_dcgrid!`, `ref_add_flex_load!`, `ref_add_pst!`, `ref_add_sssc!`, `ref_add_gendc!`.

# Returns
- A PowerModels-style solution dictionary produced by `_PM.solve_model`.

# Behavior
Delegates solve to `_PM.solve_model` with `build_fcuc` as the builder. The builder implements
a multi-network FCUC formulation with per-hour UC submodels, contingency constraints and a
global objective that includes frequency-related cost terms.
"""
function solve_rocofuc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_rocofuc; ref_extensions = [add_ref_dcgrid!, ref_add_flex_load!, ref_add_pst!, ref_add_sssc!, ref_add_gendc!], kwargs...)
end

"""
    build_rocofuc(pm::_PM.AbstractPowerModel)

Construct the multi-network FCUC JuMP model.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder with multi-network and time-series references.

# Details
- Adds network-scoped variables for AC voltages, DC grid variables, converters and
  inertia/reserve contributions.
- Calls `uc_model!` for each scheduling hour (from `pm.ref[:it][:pm][:hour_ids]`) to build
  the per-hour UC submodel (branch power, storage, unit commitment variables, contingencies).
- Calls `contingency_constraints!` for contingency stages (from `pm.ref[:it][:pm][:cont_ids]`).
- Assembles the global objective via `objective_min_cost_fcuc(pm; droop = true)`.
"""
function build_rocofuc(pm::_PM.AbstractPowerModel)

    for n in _PM.nw_ids(pm)
        _PM.variable_bus_voltage(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_dcgenerator_power(pm; nw = n)

        _PM.constraint_model_voltage(pm; nw = n)
        constraint_voltage_dc(pm; nw = n)

        variable_inertia(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
    end

    for n in pm.ref[:it][:pm][:hour_ids]
        rocofuc_model!(pm, n)
    end

        objective_min_cost_uc(pm)
end

"""
    uc_model!(pm, n)

Build the per-hour Unit Commitment (UC) submodel for network/time-index `n`.

# Inputs
- `pm` : PowerModels internal model holder.
- `n` : Network/time identifier corresponding to an entry in `pm.ref[:it][:pm][:hour_ids]`.

# Details
- Adds per-hour variables: branch power, storage power, UC on/off states, flexible loads,
  PST/SSSC, storage on/off and contingency variables.
- Adds per-hour constraints: reference bus angles, AC power balances, branch Ohm/voltage
  constraints, DC power balances, converter constraints, flexible demand constraints.
- Adds unit-commitment specific constraints: generator on/off, unit commitment linking/ramping,
  generator contingency and converter contingency constraints.
- Integrates storage constraints and storage contingency handling when storage is present.
- Applies fixed cross-border flow constraints if enabled in `pm.setting`.
- Adds RoCoF contingency constraints for defined system splits. (ToDo: later add different contingency types)
"""
function rocofuc_model!(pm, n) 
    _PM.variable_branch_power(pm; nw = n)
    _PM.variable_storage_power(pm; nw = n)
    variable_generator_states(pm; nw = n, uc = true)
    variable_flexible_demand(pm; nw = n)
    variable_pst(pm; nw = n)
    variable_sssc(pm; nw = n)
    variable_storage_on_off(pm; nw = n)
    variable_split_contingency(pm; nw = n)

    for i in _PM.ids(pm, n, :ref_buses)
        _PM.constraint_theta_ref(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :bus)
        constraint_power_balance_ac(pm, i; nw = n) # add storage
    end

    for i in _PM.ids(pm, n, :branch)
        _PM.constraint_ohms_yt_from(pm, i; nw = n)
        _PM.constraint_ohms_yt_to(pm, i; nw = n)
        _PM.constraint_voltage_angle_difference(pm, i; nw = n)
        _PM.constraint_thermal_limit_from(pm, i; nw = n)
        _PM.constraint_thermal_limit_to(pm, i; nw = n)
    end
    for i in _PM.ids(pm, n, :busdc)
        constraint_power_balance_dc(pm, i; nw = n)
    end
    for i in _PM.ids(pm, n, :branchdc)
        constraint_ohms_dc_branch(pm, i; nw = n)
    end
    for i in _PM.ids(pm, n, :convdc)
        constraint_converter_losses(pm, i; nw = n)
        constraint_converter_current(pm, i; nw = n)
        constraint_conv_transformer(pm, i; nw = n)
        constraint_conv_reactor(pm, i; nw = n)
        constraint_conv_filter(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :flex_load)
        constraint_total_flexible_demand(pm, i; nw = n)
    end

    if haskey(pm.setting, "fix_cross_border_flows") && pm.setting["fix_cross_border_flows"] == true
        if !haskey(pm.setting, "borders")
            borders = [i for i in _PM.ids(pm, n, :borders)]
        else
            borders = [i for i in pm.setting["borders"]]
        end
        for i in borders
            constraint_fixed_xb_flows(pm, i; nw = n)
        end
    end

    gen_status = haskey(pm.setting, "use_gen_status") && pm.setting["use_gen_status"] == true
    for i in _PM.ids(pm, n, :gen)
        constraint_generator_on_off(pm, i; nw = n, use_status = gen_status)
        constraint_unit_commitment(pm, i; nw = n)
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

    for i in _PM.ids(pm, n, :zones)
        constraint_rocof_split(pm, i; nw = n)
    end
end
