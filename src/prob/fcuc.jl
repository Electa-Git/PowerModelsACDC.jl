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
function solve_fcuc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_fcuc; ref_extensions = [add_ref_dcgrid!, ref_add_flex_load!, ref_add_pst!, ref_add_sssc!, ref_add_gendc!], kwargs...)
end

"""
    build_fcuc(pm::_PM.AbstractPowerModel)

Construct the multi-network FCUC JuMP model.

# Inputs
- `pm::_PM.AbstractPowerModel` : PowerModels internal model holder with multi-network and time-series references.

# Details
- Iterates networks declared in `pm.ref[:it][:pm][:nw]` and adds network-scoped variables
  for AC voltages, DC grid variables, converters and inertia/reserve contributions.
- Calls `uc_model!` for each scheduling hour (from `pm.ref[:it][:pm][:hour_ids]`) to build
  the per-hour UC submodel (branch power, storage, unit commitment variables, contingencies).
- Calls `contingency_contraints!` for contingency stages (from `pm.ref[:it][:pm][:cont_ids]`).
- Assembles the global objective via `objective_min_cost_fcuc(pm; droop = true)`.
"""
function build_fcuc(pm::_PM.AbstractPowerModel)

    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_dcgenerator_power(pm; nw = n)

        _PM.constraint_model_voltage(pm; nw = n)
        constraint_voltage_dc(pm; nw = n)

        variable_inertia(pm; nw = n)
        variable_hvdc_contribution(pm; nw = n)
        variable_generator_contribution(pm; nw = n)
        variable_storage_contribution(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
    end

    for n in pm.ref[:it][:pm][:hour_ids]
        uc_model!(pm, n)
    end

    for n in pm.ref[:it][:pm][:cont_ids]
        contingency_contraints!(pm, n)
    end

    objective_min_cost_fcuc(pm; droop = true)    
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
"""
function uc_model!(pm, n; cont = ["gen", "conv"])
    _PM.variable_branch_power(pm; nw = n)
    _PM.variable_storage_power(pm; nw = n)
    variable_generator_states(pm; nw = n, uc = true)
    variable_flexible_demand(pm; nw = n)
    variable_pst(pm; nw = n)
    variable_sssc(pm; nw = n)
    variable_storage_on_off(pm; nw = n)
    variable_contingencies(pm, nw = n)

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

    if any(cont .== "gen")
        constraint_generator_contingencies(pm; nw = n)
    end
    
    if any(cont .== "conv")
        constraint_converter_contingencies(pm; nw = n)
    end

    if haskey(_PM.ref(pm, n), :tie_lines)
        constraint_tieline_contingencies(pm; nw = n)
    end

    if haskey(_PM.ref(pm, n), :storage)
        constraint_storage_contingencies(pm; nw = n)
    end

    if haskey(_PM.ref(pm, n), :storage)
        storage_constraints(pm, n; uc = true)
    end
end
"""
    contingency_contraints!(pm, n)

Build constraints for a contingency scenario identified by `n`.

# Inputs
- `pm` : PowerModels internal model holder.
- `n` : Contingency model identifier (from `pm.ref[:it][:pm][:cont_ids]`).

# Details
- Re-establishes DC and converter balance constraints for the contingency stage.
- Adds converter reserve contributions and generator FCR (frequency containment reserve)
  contributions and associated absolute-value constraints.
- Adds storage reserve contribution constraints where storage exists.
- Determines contingency metadata (zone/area/type) via `determine_zone_area_type_of_contingency`
  and applies frequency-contingency constraints appropriate to the contingency type:
  generator, converter, storage or tie-line.
- Honors `pm.setting["hvdc_inertia_contribution"]` when present to include HVDC contributions
  in frequency constraints.
"""
function contingency_contraints!(pm, n)
    rn_idx = (n - get_reference_network_id(pm, n; uc = true))

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
        constraint_converter_power_balance(pm, i; nw = n)
    end
    
    gen_status = haskey(pm.setting, "use_gen_status") && pm.setting["use_gen_status"] == true
    for i in _PM.ids(pm, n, :gen)
        constraint_generator_on_off(pm, i; nw = n, use_status = gen_status, second_stage = true)
        constraint_generator_fcr_power_balance(pm, i; nw = n)
        constraint_generator_fcr_contribution(pm, i; nw = n)
        constraint_generator_fcr_contribution_abs(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :convdc)
        constraint_converter_reserve_contribution_absolute(pm, i; nw = n)
    end

    for i in _PM.ids(pm, n, :storage)
        constraint_storage_fcr_contribution(pm, i; nw = n)
        constraint_storage_fcr_contribution_abs(pm, i; nw = n)
    end

    zone, area, cont_type = determine_zone_area_type_of_contingency(pm, rn_idx, n)

    if cont_type == "gen"
        if haskey(pm.setting, "hvdc_inertia_contribution")
            constraint_frequency_generator_contingency(pm, zone; nw = n, hvdc_contribution = pm.setting["hvdc_inertia_contribution"])
        else
            constraint_frequency_generator_contingency(pm, zone; nw = n, hvdc_contribution = false)
        end
    end

    if cont_type == "conv"
        if haskey(pm.setting, "hvdc_inertia_contribution")
            constraint_frequency_converter_contingency(pm, zone; nw = n, hvdc_contribution = pm.setting["hvdc_inertia_contribution"])
        else
            constraint_frequency_converter_contingency(pm, zone; nw = n, hvdc_contribution = false)
        end
    end

    if haskey(_PM.ref(pm, n), :storage) && cont_type == "storage"
        if haskey(pm.setting, "hvdc_inertia_contribution")
            constraint_frequency_storage_contingency(pm, zone; nw = n, hvdc_contribution = pm.setting["hvdc_inertia_contribution"])
        else
            constraint_frequency_storage_contingency(pm, zone; nw = n, hvdc_contribution = false)
        end
    end

    if haskey(_PM.ref(pm, n), :tie_lines) && cont_type == "tie_line" && !isempty(_PM.ref(pm, n, :areas))
        if haskey(pm.setting, "hvdc_inertia_contribution") 
            constraint_frequency_tieline_contingency(pm, area; nw = n, hvdc_contribution = pm.setting["hvdc_inertia_contribution"])
        else
            constraint_frequency_tieline_contingency(pm, area; nw = n, hvdc_contribution = false)
        end
    end
end
"""
    determine_zone_area_type_of_contingency(pm, rn_idx, n) -> (zone_id::Int, area_id::Int, type::String)

Map a contingency reference index to (zone_id, area_id, contingency_type).

# Inputs
- `pm` : PowerModels internal model holder.
- `rn_idx` : Relative network index used to determine which contingency (derived in calling code).
- `n` : Network/contingency identifier.

# Returns
- `zone_id::Int` : Zone identifier (0 if not applicable).
- `area_id::Int` : Area identifier (0 if not applicable).
- `type::String` : Contingency type, one of "gen", "conv", "storage" or "tie_line".

# Logic
- The function assumes a mapping where each zone contributes up to three
  contingency types in sequence (gen, conv, storage). If `rn_idx` exceeds
  the zone-based range it is treated as a tie-line contingency and an area id is returned.
"""
function determine_zone_area_type_of_contingency(pm, rn_idx, n)
    zones = length(_PM.ref(pm, n, :zones))
    areas = length(_PM.ref(pm, n, :areas))

    zone_id = 0
    area_id = 0
    zone_ids = [z for z in _PM.ids(pm, n, :zones)]
    area_ids = [z for z in _PM.ids(pm, n, :areas)]
    if rn_idx <= zones * 3
        zone = Int(ceil(rn_idx / 3))
        if zone * 3 - rn_idx == 2
            type = "gen"
        elseif zone * 3 - rn_idx == 1
            type = "conv"
        elseif zone * 3 - rn_idx == 0
            type = "storage" 
        end
        zone_id = zone_ids[zone]
    else
        area = rn_idx - 3 * zones       
        type = "tie_line"
        area_id = 1
    end

    return zone_id, area_id, type
end
