# ...existing code...

export solve_acdcopf_bf

"""
    solve_acdcopf_bf(file::String, model_type::Type, solver; kwargs...)

Solve an AC/DC Optimal Power Flow (OPF) problem using the Branch-Flow (BF)
formulation (BF = branch flow) for the AC portion, combined with DC components.

# Arguments
- `file::String` : Path to the input data file (e.g., MATPOWER `.m` file`).
- `model_type::Type` : PowerModels model type to use for solving (e.g., ACPPowerModel, ACRPowerModel, SOCBFPowerModel).
- `solver` : JuMP solver object or solver factory (e.g., Ipopt).
- `kwargs...` : Optional keyword arguments forwarded to the PowerModels solve entrypoint
  (settings, `ref_extensions`, etc.).

# Returns
- A solution dictionary as returned by PowerModels containing variable values,
  objective (when applicable), and solver termination status.

# Details
- Parses the input file into a PowerModels data dictionary and performs any
  package-specific preprocessing via `process_additional_data!`.
- Delegates to `solve_acdcopf_bf(data::Dict, ...)` with the default set of
  reference extensions for DC grids, PSTs, SSSC, flexible loads, and DC
  generators (these can be overridden via `kwargs`).
- The Branch-Flow formulation models branch flows and currents explicitly and
  is often preferred for radial or distribution-like topologies or when
  branch current/flow variables and their convex relaxations are required.
"""
function solve_acdcopf_bf(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    process_additional_data!(data)
    return solve_acdcopf_bf(data, model_type, solver; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
end

"""
    solve_acdcopf_bf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)

Solve an AC/DC OPF (Branch-Flow formulation) using an already-parsed data dictionary.

# Arguments
- `data::Dict{String,Any}` : Parsed PowerModels data dictionary.
- `model_type::Type` : PowerModels model type to build the JuMP model.
- `solver` : JuMP solver object or factory.
- `kwargs...` : Forwarded keyword arguments (settings, `ref_extensions` override, etc.).

# Returns
- A solution dictionary produced by the PowerModels solve pipeline.

# Details
- Chooses the appropriate build function depending on whether the data
  represents a single network or a multinetwork setup.
- By default calls the BF-specific builder `build_acdcopf_bf` (or the multi
  network variant) and applies the default reference extensions for DC and
  other special components. Override `ref_extensions` to change behavior.
"""
function solve_acdcopf_bf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    if haskey(data, "multinetwork") && data["multinetwork"] == true
        return _PM.solve_model(data, model_type, solver, mp_build_acdcopf_bf; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
    else
        return _PM.solve_model(data, model_type, solver, build_acdcopf_bf; ref_extensions = [add_ref_dcgrid!, ref_add_pst!, ref_add_sssc!, ref_add_flex_load!, ref_add_gendc!], kwargs...)
    end
end

"""
    build_acdcopf_bf(pm::_PM.AbstractPowerModel)

Construct the JuMP model for a single-network AC/DC OPF using the Branch-Flow (BF)
formulation for the AC network.

# Arguments
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder containing
  parsed data, the JuMP model, settings and references.

# Details
- Adds variables typical for BF formulations:
  - explicit branch flow / branch current variables,
  - squared voltage magnitude or voltage magnitude variables as required by the BF formulation,
  - generator active/reactive powers, storage power variables.
- Adds DC-specific variables for DC branches, converters, DC grid voltages and DC generators.
- Adds variables and constraints for flexible and fixed loads, PSTs and SSSCs when present.
- Adds constraints including (but not limited to):
  - branch-flow equations (power flow on each branch expressed via sending/receiving end flows and currents),
  - branch current limits and thermal limits,
  - voltage drop constraints along branches as per BF formulation,
  - AC power balance at buses,
  - DC branch Ohm's law and DC power balance,
  - converter transformer/reactor/filter constraints, losses, and current/angle limits.
- Sets the objective to minimize operational cost when the chosen model type represents an optimization problem.
- Honors `pm.setting` flags (for example `fix_cross_border_flows`) and applies corresponding constraints if enabled.

# Notes
- This builder is intended to be BF-specific: where the standard AC formulation
  uses admittance-based Ohm constraints, the BF builder enforces branch-wise
  flow/current relations. For formulations that already include SOC/branch-current
  variables (e.g., `SOCBFPowerModel`) the builder will reuse or align with those
  variables where appropriate.
"""

function build_acdcopf_bf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_storage_power(pm)
    _PM.variable_branch_current(pm)

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dc_converter(pm)
    variable_dcgrid_voltage_magnitude(pm)
    variable_dcgenerator_power(pm)
    variable_flexible_demand(pm)
    variable_pst(pm)
    variable_sssc(pm)

    _PM.objective_min_fuel_cost(pm)

    _PM.constraint_model_current(pm)
    constraint_voltage_dc(pm)

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    for i in _PM.ids(pm, :bus)
        constraint_power_balance_ac(pm, i)
    end

    for i in _PM.ids(pm, :branch)
        _PM.constraint_power_losses(pm, i)
        _PM.constraint_voltage_magnitude_difference(pm, i)
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

    for i in _PM.ids(pm, :busdc)
        constraint_power_balance_dc(pm, i)
    end
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
        constraint_dc_branch_current(pm, i)
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
    mp_build_acdcopf_bf(pm::_PM.AbstractPowerModel)

Construct the JuMP model for a multinetwork AC/DC OPF using the Branch-Flow (BF)
formulation for each AC subnetwork.

# Arguments
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder containing
  parsed data, JuMP model, settings and references for multiple networks.

# Details
- Iterates networks in `pm.ref[:it][:pm][:nw]` and for each network:
  - Adds BF variables and DC variables scoped to the network.
  - Adds the BF-specific set of constraints (per-branch flows, voltage drops,
    current limits, etc.) and DC constraints for the network.
- Adds inter-network / cross-border constraints where applicable (fixed or free flows).
- Aggregates objective contributions and applies the global objective.
"""

# ...existing code...

function mp_build_acdcopf_bf(pm::_PM.AbstractPowerModel)
    # Create variables for each network
    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)

        # DC & special-component variables (scoped per network)
        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_dcgenerator_power(pm; nw = n)
        variable_flexible_demand(pm; nw = n)
        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)
    end

    # Add constraints for each network
    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.constraint_model_voltage(pm; nw = n)
        constraint_voltage_dc(pm; nw = n)

        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :bus)
            constraint_power_balance_ac(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branch)
            # Branch-flow specific constraints: keep thermal/angle/Ohm relations
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
            # If LCC converter, add firing-angle constraint
            if haskey(pm.ref[:it][:pm][:nw][n], :convdc) && pm.ref[:it][:pm][:nw][n][:convdc][i]["islcc"] == 1
                constraint_conv_firing_angle(pm, i; nw = n)
            end
        end

        if haskey(_PM.ref(pm, n), :storage)
            storage_constraints(pm, n)
        end
        # Cross-border fixed flows (global handling)
        if haskey(pm.setting, "fix_cross_border_flows") && pm.setting["fix_cross_border_flows"] == true
            if !haskey(pm.setting, "borders")
                borders = [i for i in _PM.ids(pm, n, :borders)]
            else
                borders = [i for i in pm.setting["borders"]]
            end
            for i in borders
                constraint_fixed_xb_flows(pm, i, nw = n)
            end
        end
    end
    # Global objective assembly
    objective_min_operational_cost(pm)
end
