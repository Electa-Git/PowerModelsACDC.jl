 
"""
    solve_spcuc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)

Entry point to solve a Security-Constrained Unit Commitment (SPCUC) problem.

# Inputs
- `data::Dict{String,Any}` : Parsed PowerModels data dictionary (multi-network expected).
- `model_type::Type` : PowerModels model type to use when building JuMP models.
- `optimizer` : JuMP optimizer/solver (e.g., Ipopt, Gurobi).
- `kwargs...` : Forwarded keyword arguments to `_PM.solve_model` (settings, `ref_extensions`, etc.).
  Default reference extensions applied: `add_ref_dcgrid!`, `ref_add_flex_load!`, `ref_add_pst!`, `ref_add_sssc!`, `ref_add_gendc!`.

# Returns
- A PowerModels-style solution dictionary produced by `_PM.solve_model`.

# Behavior
Delegates solve to `_PM.solve_model` with `build_spcuc` as the builder. The builder implements
a multi-network SPCUC formulation with per-hour UC submodels and contingency constraints.
"""

function solve_spcuc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_spcuc; ref_extensions = [add_ref_dcgrid!, ref_add_flex_load!, ref_add_pst!, ref_add_sssc!, ref_add_gendc!], kwargs...)
end


"""
    build_spcuc(pm::_PM.AbstractPowerModel)

Construct the multi-network SPCUC JuMP model.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder with multi-network and time-series references.

# Details
- Iterates networks declared in `pm.ref[:it][:pm][:hour_ids]` and adds network-scoped variables
  and constraints for AC voltages, DC grid variables, converters, generators, storage, and contingencies.
- Calls `base_uc_model!` for each scheduling hour to build the per-hour UC submodel.
- Calls `spcuc_contingency_model!` for each contingency stage (from `pm.ref[:it][:pm][:cont_ids]`).
- Assembles the global objective via `objective_min_cost_uc(pm)`.
"""
function build_spcuc(pm::_PM.AbstractPowerModel)

    for n in pm.ref[:it][:pm][:hour_ids]
        base_uc_model!(pm, n)
    end

    for n in pm.ref[:it][:pm][:cont_ids]
        spcuc_contingency_model!(pm, n)
    end

    objective_min_cost_uc(pm)   
end

"""
    base_uc_model!(pm, n)

Build the per-hour Unit Commitment (UC) submodel for network/time-index `n`.

# Inputs
- `pm` : PowerModels internal model holder.
- `n` : Network/time identifier corresponding to an entry in `pm.ref[:it][:pm][:hour_ids]`.

# Details
- Adds per-hour variables: bus voltages, branch power, generator power, storage power, inertia,
  DC branch flows, converter variables, generator states, flexible demand, PST/SSSC, storage on/off, contingencies.
- Adds per-hour constraints: voltage constraints, reference bus angles, AC power balances,
  branch Ohm/voltage/thermal constraints, DC power balances, converter constraints, flexible demand constraints.
- Adds unit-commitment specific constraints: generator on/off, unit commitment linking/ramping.
- Integrates storage constraints when storage is present.
- Applies fixed cross-border flow constraints if enabled in `pm.setting`.
"""
function base_uc_model!(pm, n)

        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)
        _PM.constraint_model_voltage(pm; nw = n)

        variable_inertia(pm; nw = n)
        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_dcgenerator_power(pm; nw = n)
        variable_generator_states(pm; nw = n, uc = true)
        variable_flexible_demand(pm; nw = n)
        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)
        variable_storage_on_off(pm; nw = n)
        constraint_voltage_dc(pm; nw = n)

        variable_contingencies(pm, nw = n)
        
        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i; nw = n)
        end
    
        for i in _PM.ids(pm, n, :bus)
            constraint_power_balance_ac(pm, i; nw = n)
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
    
        for i in _PM.ids(pm, n, :gen)
            constraint_generator_on_off(pm, i; nw = n, use_status = false)
            constraint_unit_commitment(pm, i; nw = n)
            if haskey(pm.setting, "uc_reserves") && pm.setting["uc_reserves"] == true
                constraint_unit_commitment_reserves(pm, i; nw = n)
            end
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

        if haskey(pm.setting, "fix_cross_border_flows") && pm.setting["fix_cross_border_flows"] == true
            if !haskey(pm.setting, "borders")
                borders = [i for i in _PM.ids(pm, n,:borders)]
            else
                borders = [i for i in pm.setting["borders"]]
            end
            for i in borders
                constraint_fixed_xb_flows(pm, i; nw = n)
            end
        end

        if haskey(_PM.ref(pm, n), :storage)
            storage_constraints(pm, n; uc = true)
        end

    end

"""
    spcuc_contingency_model!(pm, n)

Build constraints for a contingency scenario identified by `n` in the SPCUC formulation.

# Inputs
- `pm` : PowerModels internal model holder.
- `n` : Contingency model identifier (from `pm.ref[:it][:pm][:cont_ids]`).

# Details
- Adds contingency-specific variables: bus voltages, branch power, generator power, storage power,
  inertia, DC variables, flexible demand, PST/SSSC, storage on/off, generator inertia response.
- Adds constraints: DC power balances, reference bus angles, AC power balances, DC branch constraints,
  flexible demand response, branch constraints, converter constraints with fixed response.
- Applies generator inertial response constraints to the contingency.
"""
function spcuc_contingency_model!(pm, n)

    gen_id = (n - get_reference_network_id(pm, n; uc = true))

    _PM.variable_bus_voltage_magnitude(pm; nw = n, bounded = false)
    _PM.variable_bus_voltage_angle(pm; nw = n, bounded = false)
    _PM.variable_branch_power(pm; nw = n, bounded = false)
    _PM.variable_gen_power(pm; nw = n, bounded = false)
    _PM.variable_storage_power(pm; nw = n, bounded = false)
    _PM.constraint_model_voltage(pm; nw = n)

    variable_inertia(pm; nw = n)
    variable_active_dcbranch_flow(pm; nw = n, bounded = false)
    variable_dcbranch_current(pm; nw = n, bounded = false)
    variable_dc_converter(pm; nw = n, bounded = true)
    variable_dcgrid_voltage_magnitude(pm; nw = n, bounded = false)
    variable_dcgenerator_power(pm; nw = n, bounded = false)
    variable_flexible_demand(pm; nw = n, bounded = true)
    variable_pst(pm; nw = n, bounded = false)
    variable_sssc(pm; nw = n, bounded = false)
    variable_storage_on_off(pm; nw = n)
    constraint_voltage_dc(pm; nw = n)


    variable_generator_inertia_response(pm; nw = n)
    for i in _PM.ids(pm, n, :gen)
        constraint_generator_inertial_response_to_contingency(pm, i, gen_id; nw = n)
    end

    for i in _PM.ids(pm, n, :busdc)
        constraint_power_balance_dc(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :ref_buses)
        _PM.constraint_theta_ref(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :bus)
        constraint_power_balance_ac(pm, i; nw = n)
    end


    for i in _PM.ids(pm, n, :branchdc)
        constraint_ohms_dc_branch(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :flex_load)
        constraint_fixed_demand_response(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :branch)
        _PM.constraint_ohms_yt_from(pm, i; nw = n)
        _PM.constraint_ohms_yt_to(pm, i; nw = n)
        if haskey(pm.setting, "add_split_constraints") && pm.setting["add_split_constraints"] == true &&  any(i .== pm.ref[:it][:pm][:nw][n][:tie_lines]) 
            _PM.constraint_voltage_angle_difference(pm, i; nw = n)
        end
    end

    for i in _PM.ids(pm, n, :convdc)
        constraint_converter_losses(pm, i; nw = n)
        constraint_converter_current(pm, i; nw = n)
        constraint_conv_transformer(pm, i; nw = n)
        constraint_conv_reactor(pm, i; nw = n)
        constraint_conv_filter(pm, i; nw = n)
        constraint_fixed_converter_response(pm, i; nw = n)
    end
end