# A simple preventive SCOPF model considering AC and DC network contingencies
"""
    solve_scopf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)

File-based or data-based entrypoint to solve a preventive Security-Constrained OPF (SCOPF).

# Inputs
- `data::Dict{String,Any}` : Parsed PowerModels data dictionary (may contain multi-network/time staging).
- `model_type::Type` : PowerModels model type used to build the JuMP model.
- `solver` : JuMP solver/optimizer (e.g., Ipopt, Gurobi).
- `kwargs...` : Forwarded keyword arguments to `_PM.solve_model` (settings, `ref_extensions`, etc.).
  Default reference extensions applied: `add_ref_dcgrid!`, `ref_add_pst!`, `ref_add_sssc!`, `ref_add_flex_load!`, `ref_add_gendc!`.

# Returns
- PowerModels-style solution dictionary containing variable values, objective (when applicable) and solver termination information.

# Behavior
- Delegates to `_PM.solve_model` with `build_scopf` as the builder.
- `build_scopf` constructs a first-stage (pre-contingency) model for each hour/network
  and second-stage (post-contingency) models for each contingency scenario, then
  assembles a preventive SCOPF objective.
"""
function solve_scopf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.solve_model(data, model_type, solver, build_scopf; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
end
"""
    build_scopf(pm::_PM.AbstractPowerModel)

Construct the preventive SCOPF JuMP model.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder (parsed data, settings and references).

# Details
- For each network/time index declared in `pm.ref[:it][:pm][:nw]`:
  - creates per-network variables (bus voltages, generator/branch/storage power, DC variables, PST, SSSC, flexible demand, generator action variables).
- Calls `first_stage_model!` for each specified first-stage network/hour (`pm.ref[:it][:pm][:hour_ids]`) to add pre-contingency constraints.
- Calls `second_stage_model!` for each contingency network (`pm.ref[:it][:pm][:cont_ids]`) to add post-contingency constraints and component outage handling.
- Assembles the preventive SCOPF objective through `objective_min_scopf_cost(pm; network_ids = ...)`.

# Notes
- Converter droop optimization and DC converter passivity checks are supported via `pm.setting` flags.
"""
function build_scopf(pm::_PM.AbstractPowerModel)
    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcgenerator_power(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_flexible_demand(pm; nw = n)
        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)
        variable_generator_actions(pm; nw = n)
    end
    for n in pm.ref[:it][:pm][:hour_ids]
        first_stage_model!(pm, n)
    end
    for n in pm.ref[:it][:pm][:cont_ids]
        second_stage_model!(pm, n)
    end
    objective_min_scopf_cost(pm; network_ids = pm.ref[:it][:pm][:hour_ids])
end
"""
    first_stage_model!(pm::_PM.AbstractPowerModel, n)

Add first-stage (pre-contingency) variables and constraints for network/time index `n`.

# Inputs
- `pm` : PowerModels internal model holder.
- `n` : Network/time identifier (from `pm.ref[:it][:pm][:hour_ids]`).

# Details
- Optionally creates converter droop coefficient variables when `pm.setting["optimize_converter_droop"]` is true.
- Adds DC voltage model, reference angle constraints, AC power balance, DC balance, flexible demand aggregation.
- Adds branch Ohm/thermal/angle constraints and converter constraints (losses, current, transformer/reactor/filter).
- When converter droop optimization is enabled, also adds droop coefficient constraints and optional DC converter passivity constraints.
"""
function first_stage_model!(pm, n)
    if haskey(pm.setting, "optimize_converter_droop") && pm.setting["optimize_converter_droop"] == true
        variable_converter_droop_coefficient(pm; nw = n)
    end

    constraint_voltage_dc(pm; nw = n)

    for i in _PM.ids(pm, n, :ref_buses)
        _PM.constraint_theta_ref(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :bus)
        constraint_power_balance_ac(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :busdc)
        constraint_power_balance_dc(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :flex_load)
        constraint_total_flexible_demand(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :branch)
        _PM.constraint_ohms_yt_from(pm, i; nw = n)
        _PM.constraint_ohms_yt_to(pm, i; nw = n)
        _PM.constraint_voltage_angle_difference(pm, i; nw = n) #angle difference across transformer and reactor - useful for LPAC if available?
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
        if pm.ref[:it][:pm][:nw][n][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i; nw = n)
        end
        if haskey(pm.setting, "optimize_converter_droop") && pm.setting["optimize_converter_droop"] == true
            if n > 1
                for i in _PM.ids(pm, n, :convdc)
                    constraint_droop_coefficient(pm, i; nw = n)
                end
            end
            if haskey(pm.setting, "dc_converter_passivity") && pm.setting["dc_converter_passivity"] == true
                constraint_dc_converter_passivity(pm, i; nw = n)
            end
        end
    end
end
"""
    second_stage_model!(pm::_PM.AbstractPowerModel, n)

Add second-stage (post-contingency) variables and constraints for contingency network `n`.

# Inputs
- `pm` : PowerModels internal model holder.
- `n` : Contingency network identifier (from `pm.ref[:it][:pm][:cont_ids]`).

# Details
- Sets up DC voltage constraints and auxiliary DC-voltage variables used in contingency models.
- Reapplies reference angle, AC/DC power balance and generator action constraints appropriate for the contingency scenario.
- For each DC branch, applies contingency-specific branch outage constraints when the contingency targets that DC branch.
- For converters targeted by the contingency, applies converter contingency constraints; otherwise applies normal converter constraints and DC droop control (SCOPF-specific).
- Applies branch Ohm/thermal constraints and generator action constraints for post-contingency operation.
"""
function second_stage_model!(pm, n)
    constraint_voltage_dc(pm; nw = n)
    variable_dcgrid_auxiliary_voltage_magnitude(pm; nw = n)

    for i in _PM.ids(pm, n, :ref_buses)
        _PM.constraint_theta_ref(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :bus)
        constraint_power_balance_ac(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :busdc)
        constraint_power_balance_dc(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :gen)
        constraint_gen_actions(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :flex_load)
        constraint_total_flexible_demand(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :branch)
        _PM.constraint_ohms_yt_from(pm, i; nw = n)
        _PM.constraint_ohms_yt_to(pm, i; nw = n)
        _PM.constraint_voltage_angle_difference(pm, i; nw = n) #angle difference across transformer and reactor - useful for LPAC if available?
        _PM.constraint_thermal_limit_from(pm, i; nw = n)
        _PM.constraint_thermal_limit_to(pm, i; nw = n)
    end

    contingencies = _PM.ref(pm, n, :contingencies)
    cont_id = mod(n, pm.ref[:it][:pm][:number_of_contingencies])
    if cont_id == 0
        cont_id = pm.ref[:it][:pm][:number_of_contingencies]
    end

    for i in _PM.ids(pm, n, :branchdc)
        if contingencies[cont_id]["dcbranch_id1"] == i || contingencies[cont_id]["dcbranch_id2"] == i || contingencies[cont_id]["dcbranch_id3"] == i
            constraint_dc_branch_contingencies(pm, i; nw = n)
            constraint_ohms_dc_branch_contingency(pm, i; nw = n, online = 0)
        else
            constraint_ohms_dc_branch(pm, i; nw = n)
        end
    end
    
    
    for i in _PM.ids(pm, n, :convdc)
        if contingencies[cont_id]["dcconv_id1"] == i || contingencies[cont_id]["dcconv_id2"] == i || contingencies[cont_id]["dcconv_id3"] == i
            constraint_converter_contingencies(pm, i; nw = n)
        else
            constraint_converter_losses(pm, i; nw = n)
            constraint_converter_current(pm, i; nw = n)
            constraint_conv_transformer(pm, i; nw = n)
            constraint_conv_reactor(pm, i; nw = n)
            constraint_conv_filter(pm, i; nw = n)
            if pm.ref[:it][:pm][:nw][n][:convdc][i]["islcc"] == 1
                constraint_conv_firing_angle(pm, i; nw = n)
            end
            constraint_dc_droop_control(pm, i, nw = n; scopf = true)
        end 
    end
end