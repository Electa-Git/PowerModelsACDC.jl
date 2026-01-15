"""
    solve_uc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)

Entrypoint to solve a Unit Commitment (UC) problem (multi-period, multi-network).

# Inputs
- `data::Dict{String,Any}` : Parsed PowerModels data dictionary. Expects multi-network / time staging in `pm.ref[:it]`.
- `model_type::Type` : PowerModels model type used to build the JuMP model.
- `optimizer` : JuMP optimizer/solver (e.g., Ipopt, Gurobi).
- `kwargs...` : Forwarded keyword arguments to `_PM.solve_model` (settings, `ref_extensions`, etc.).
  Default `ref_extensions` applied: `add_ref_dcgrid!`, `ref_add_flex_load!`, `ref_add_pst!`, `ref_add_sssc!`, `ref_add_gendc!`.

# Returns
- PowerModels-style solution dictionary produced by `_PM.solve_model` (variable values, objective, solver status).

# Behavior
Delegates to `_PM.solve_model` with `build_uc` as the builder. The builder creates
network- and time-scoped UC variables (generator on/off, branch and bus variables,
storage, flexible demand, PST/SSSC, DC components) and enforces per-period operational
and unit-commitment constraints. Use `pm.setting` to control optional features such as
reserve handling (`"uc_reserves"`) and cross-border flow fixing (`"fix_cross_border_flows"`).
"""
function solve_uc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_uc; ref_extensions = [add_ref_dcgrid!, ref_add_flex_load!, ref_add_pst!, ref_add_sssc!, ref_add_gendc!], kwargs...)
end

"""
    build_uc(pm::_PM.AbstractPowerModel)

Construct the multi-network / multi-period Unit Commitment (UC) JuMP model.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder with multi-network/time references.

# Details
- For each network/time index in `pm.ref[:it][:pm][:nw]` the builder:
  - creates operational variables: bus voltages, branch/gen/storage powers, branch currents (if BF/SOCBF), DC variables, flexible demand, PST/SSSC variables.
  - creates UC-specific variables: generator start/on/off/state indicators, storage on/off, contingency/state variables if present.
  - enforces per-network constraints: reference bus angle, AC power balance, branch Ohm/voltage-angle/thermal limits, DC power balance and DC Ohm laws, converter losses/current limits, flexible demand aggregation.
  - enforces generator UC constraints (on/off linking, unit commitment constraints) and (optionally) UC reserves via `pm.setting["uc_reserves"]`.
  - enforces storage coupling and storage on/off constraints when storage is present.
- Applies optional global constraints:
  - fixed cross-border flows when `pm.setting["fix_cross_border_flows"] == true`.
- Assembles the objective via `objective_min_cost_uc(pm)`.

# Notes
- The builder relies on ACDC-specific primitives; extend `pm.setting` to enable/disable features.
"""
function build_uc(pm::_PM.AbstractPowerModel)
    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)
        _PM.constraint_model_voltage(pm; nw = n)

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
    end

    for (n, networks) in pm.ref[:it][:pm][:nw]
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

    objective_min_cost_uc(pm)
end
"""
    objective_min_cost_uc(pm::_PM.AbstractPowerModel; report::Bool=true, droop = false)

Formulate the UC objective: sum of generator operational and start-up costs plus
demand reduction and shedding costs over the scheduling horizon.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder.
- `report::Bool` : When true, objective may prepare internal reporting structures (default true).
- `droop::Bool` : Reserved flag for droop-related cost terms (default false).

# Returns
- A JuMP objective expression added to `pm.model` minimizing total UC cost.

# Details
- For each scheduling hour in `pm.ref[:it][:pm][:hour_ids]`, the generator cost includes:
  - start-up cost component (via binary indicator `beta_g` and generator pmax),
  - variable fuel cost (linear term on `pg`) and start-up fixed cost (via `alpha_g`).
- Adds load reduction and load curtailment costs obtained from `calc_load_operational_cost_uc(pm)`.
"""
function objective_min_cost_uc(pm::_PM.AbstractPowerModel; report::Bool=true, droop = false)
    gen_cost = Dict()

    for n in pm.ref[:it][:pm][:hour_ids]
        for (i,gen) in _PM.nws(pm)[n][:gen]
            beta_g =  _PM.var(pm, n, :beta_g, i)
            alpha_g =  _PM.var(pm, n, :alpha_g, i)
            pg =  _PM.var(pm, n, :pg, i)
            gen_cost[(n,i)] = (beta_g * gen["start_up_cost"] * gen["pmax"]) + (gen["cost"][1]*pg + (gen["cost"][2] * alpha_g))
        end
    end

    load_cost_red, load_cost_curt = calc_load_operational_cost_uc(pm)

    return JuMP.@objective(pm.model, Min,
        sum( sum( gen_cost[(n,i)] for (i,gen) in _PM.nws(pm)[n][:gen]) for n in pm.ref[:it][:pm][:hour_ids]) 
        + sum( sum( load_cost_curt[(n,i)] for (i,load) in _PM.nws(pm)[n][:load]) for n in pm.ref[:it][:pm][:hour_ids])
        + sum( sum( load_cost_red[(n,i)] for (i,load) in _PM.nws(pm)[n][:load]) for n in pm.ref[:it][:pm][:hour_ids])
    )
end