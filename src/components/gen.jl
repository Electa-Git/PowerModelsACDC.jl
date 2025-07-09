function variable_generator_states(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, uc = false, res_on = false, all_on = false)
    variable_generator_state(pm, nw = nw; res_on = res_on, all_on = all_on)
    if uc == true
        if haskey(pm.setting, "relax_uc_binaries") && pm.setting["relax_uc_binaries"] == true
            variable_generator_state_mut_relax(pm, nw = nw)
            variable_generator_state_mdt_relax(pm, nw = nw)
        else
            variable_generator_state_mut(pm, nw = nw)
            variable_generator_state_mdt(pm, nw = nw)
        end
    end
end

"Variable for generator state"
function variable_generator_state(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true, res_on = false, all_on = false)
    alpha_g = _PM.var(pm, nw)[:alpha_g] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_alpha_g",
        binary = true,
        start = 0,
        upper_bound = 1,
        lower_bound = 0,
    )
    
    for (g, gen) in _PM.ref(pm, nw, :gen)
        if res_on == true && (gen["type"] == "Wind" || gen["type"] == "Solar")
            JuMP.set_lower_bound(alpha_g[g], 1)
            JuMP.set_upper_bound(alpha_g[g], 1)
        elseif gen["pmax"] == 0
            JuMP.set_lower_bound(alpha_g[g], 0)
            JuMP.set_upper_bound(alpha_g[g], 0)
        end
        if all_on == true
            JuMP.set_lower_bound(alpha_g[g], 1)
            JuMP.set_upper_bound(alpha_g[g], 1)
        end
    end
    report && _PM.sol_component_value(pm, nw, :gen, :alpha_g, _PM.ids(pm, nw, :gen), alpha_g)
end

"Variable for minimum up-time"
function variable_generator_state_mut(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    beta_g = _PM.var(pm, nw)[:beta_g] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_beta_g",
        binary = true,
        start = 0,
        lower_bound = 0,
        upper_bound = 1
    )
    report && _PM.sol_component_value(pm, nw, :gen, :beta_g, _PM.ids(pm, nw, :gen), beta_g)
end

"Variable for minimum down-time"
function variable_generator_state_mdt(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    gamma_g = _PM.var(pm, nw)[:gamma_g] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_gamma_g",
        binary = true,
        start = 0,
        lower_bound = 0,
        upper_bound = 1
    )
    report && _PM.sol_component_value(pm, nw, :gen, :gamma_g, _PM.ids(pm, nw, :gen), gamma_g)
end

"Variable for minimum up-time relaxed"
function variable_generator_state_mut_relax(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    beta_g = _PM.var(pm, nw)[:beta_g] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_beta_g",
        binary = false,
        lower_bound = 0,
        upper_bound = 1,
        start = 0
    )
    report && _PM.sol_component_value(pm, nw, :gen, :beta_g, _PM.ids(pm, nw, :gen), beta_g)
end

"Variable for minimum down-time relaxed"
function variable_generator_state_mdt_relax(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    gamma_g = _PM.var(pm, nw)[:gamma_g] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_gamma_g",
        binary = false,
        lower_bound = 0,
        upper_bound = 1,
        start = 0
    )
    report && _PM.sol_component_value(pm, nw, :gen, :gamma_g, _PM.ids(pm, nw, :gen), gamma_g)
end

"Collect generator redispatch variables"
function variable_generator_redispatch(pm; kwargs...)
    variable_generator_redispatch_up(pm; kwargs...)
    variable_generator_redispatch_down(pm; kwargs...)
end


"Variable for upwards generator redispatch each time step"
function variable_generator_redispatch_up(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    dpg_up = _PM.var(pm, nw)[:dpg_up] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_dpg_up",
        lower_bound = 0,
        upper_bound = 2 * max(0, _PM.ref(pm, nw, :gen, i, "pmax")),
        start = 0
    )
    report && _PM.sol_component_value(pm, nw, :gen, :dpg_up, _PM.ids(pm, nw, :gen), dpg_up)
end

"Variable for upwards generator redispatch each time step"
function variable_generator_redispatch_down(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    dpg_down = _PM.var(pm, nw)[:dpg_down] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gen)], base_name="$(nw)_dpg_down",
        lower_bound = 0,
        upper_bound = 2 * max(0, _PM.ref(pm, nw, :gen, i, "pmax")),
        start = 0
    )
    report && _PM.sol_component_value(pm, nw, :gen, :dpg_down, _PM.ids(pm, nw, :gen), dpg_down)
end

# Constraint templates:
"Defines system-wide generator inertia limits in given market zone"
function constraint_generator_inertia_limit(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    inertia_limit = _PM.ref(pm, nw, :inertia_limit, i)["limit"]

    generator_properties = Dict()
    for (g, gen) in _PM.ref(pm, nw, :gen)
        if haskey(gen, "zone") && gen["zone"] == i && haskey(gen, "inertia_constants")
            push!(generator_properties, g => Dict("inertia" => gen["inertia_constants"], "rating" => gen["pmax"]))
        end
    end

    constraint_generator_inertia_limit(pm, nw, generator_properties, inertia_limit)
end

"On/off status csontraint for unit commitment model"
function constraint_generator_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default, use_status = true, second_stage = false)
    gen     = _PM.ref(pm, nw, :gen, i)
    pmax = gen["pmax"]
    pmin = gen["pmin"]
    if use_status == true
        status = gen["dispatch_status"]
    else
        status = 0
    end

    if second_stage == false
        constraint_generator_on_off(pm, nw, i, pmax, pmin, status)
    else
        nw_ref = get_reference_network_id(pm, nw; uc = true)
        constraint_generator_on_off(pm, nw, nw_ref, i, pmax, pmin, status)
    end
end

"Generator status indicator constraint for optimal power flow model model"
function constraint_generator_status(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    constraint_generator_status(pm, nw, i)
end
"Generator status indicator constraint for unit commitment model"
function constraint_generator_status_uc(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    previous_hour_network = get_previous_hour_network_id(pm, nw; uc = true)

    constraint_generator_status_uc(pm, nw, i, previous_hour_network)
end
"Generator status indicator constraint for unit commitment model dunring generator contingency"
function constraint_generator_status_cont(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw; uc = true)
    constraint_generator_status_cont(pm, nw, i, reference_network_idx)
end

"Collect generator unit commitment constraints"
function contstraint_unit_commitment(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    constraint_generator_decisions(pm, i, nw)
    constraint_minimum_generator_up_time(pm, i, nw)
    constraint_minimum_generator_down_time(pm, i, nw)
end
"Link generator decisions in security constrained unit commitment model"
function constraint_generator_decisions(pm::_PM.AbstractPowerModel, i::Int, nw::Int = _PM.nw_id_default)
    if nw == 1
        constraint_initial_generator_decisions(pm, i, nw)
    else
        previous_hour_network = get_previous_hour_network_id(pm, nw; uc = true)
        constraint_generator_decisions(pm, i, nw, previous_hour_network)
        constraint_generator_ramping(pm, i, nw, previous_hour_network)
    end
end
"Genetor minimum up-time constraint"
function constraint_minimum_generator_up_time(pm::_PM.AbstractPowerModel, i::Int, nw::Int = _PM.nw_id_default)
    gen =_PM.ref(pm, nw, :gen, i)
    mut = gen["mut"]
    if pm.ref[:it][:pm][:number_of_contingencies] !== 0
        interval = pm.ref[:it][:pm][:number_of_contingencies]
    else
        interval = 1
    end
    h_start = max(1, (nw + interval - (mut * interval))) 
    τ = h_start : interval : nw

    return constraint_minimum_generator_up_time(pm, i, nw, τ)
end
"Genetor minimum down-time constraint"
function constraint_minimum_generator_down_time(pm::_PM.AbstractPowerModel, i::Int, nw::Int = _PM.nw_id_default)
    gen =_PM.ref(pm, nw, :gen, i)
    mdt = gen["mdt"]
    if pm.ref[:it][:pm][:number_of_contingencies] !== 0
        interval = pm.ref[:it][:pm][:number_of_contingencies]
    else
        interval = 1
    end
    h_start = max(1, (nw + interval - (mdt * interval))) 
    τ = h_start : interval : nw

    return constraint_minimum_generator_down_time(pm, i, nw, τ)
end

"Generator ramping constraint for unit commitment model"
function constraint_generator_ramping(pm::_PM.AbstractPowerModel, i::Int, nw::Int, previous_hour_network)
    gen = _PM.ref(pm, nw, :gen, i)
    Δt = _PM.ref(pm, nw, :uc_parameters)["time_interval"]
    pmax = gen["pmax"]
    pmin = gen["pmin"]
    ΔPg_up = gen["ramp_rate"] * Δt * pmax
    ΔPg_down = gen["ramp_rate"] * Δt * pmax

    return constraint_generator_ramping(pm, i, nw, previous_hour_network, ΔPg_up, ΔPg_down, pmin)
end

function constraint_unit_commitment_reserves(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    return constraint_unit_commitment_reserves(pm, i, nw)
end

function constraint_generator_redispatch(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    gen     = _PM.ref(pm, nw, :gen, i)

    if haskey(gen, "pg")
        pg_ref  = gen["pg"]
        constraint_generator_redispatch(pm, nw, i, pg_ref)
    end
end

"Modelling generator power balance when providing FCR"
function constraint_generator_fcr_power_balance(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    reference_network_idx = get_reference_network_id(pm, nw)

    constraint_generator_fcr_power_balance(pm, i, nw, reference_network_idx)
end

"Modelling generator FCR contribution"
function constraint_generator_fcr_contribution(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    gen = _PM.ref(pm, nw, :gen, i)
    ramp_rate = gen["ramp_rate_per_s"]

    ΔTin = _PM.ref(pm, nw, :frequency_parameters)["t_fcr"]
    ΔTdroop = _PM.ref(pm, nw, :frequency_parameters)["t_fcrd"]

    return constraint_generator_fcr_contribution(pm, i, nw, ramp_rate, ΔTin, ΔTdroop)
end

"Absolute value of generator FCR contribution for post processing"
function constraint_generator_fcr_contribution_abs(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    constraint_generator_fcr_contribution_abs(pm, i, nw)
end
#################################################
# Generator realetd constraints form independent:
#################################################
"Link generator status of different hours together, to keep them on / off"
function constraint_generator_status(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    alpha_n = _PM.var(pm, n, :alpha_g, i)
    alpha_n_1 = _PM.var(pm, n-1, :alpha_g, i)

    JuMP.@constraint(pm.model, alpha_n == alpha_n_1)
end
"Link generator status of different hours together, to keep them on / off"
function constraint_generator_status_cont(pm::_PM.AbstractPowerModel, n::Int, i::Int, ref_id)
    alpha_n = _PM.var(pm, n, :alpha_g, i)
    alpha_n_1 = _PM.var(pm, ref_id, :alpha_g, i)

    JuMP.@constraint(pm.model, alpha_n == alpha_n_1)
end
"Link generator status of different hours together, to keep them on / off"
function constraint_generator_status_uc(pm::_PM.AbstractPowerModel, n::Int, i::Int, prev_hour)
    alpha_n = _PM.var(pm, n, :alpha_g, i)
    alpha_n_1 = _PM.var(pm, prev_hour, :alpha_g, i)

    JuMP.@constraint(pm.model, alpha_n == alpha_n_1)
end
"Linking constraints for generator decision variables for t = T_0"
function constraint_initial_generator_decisions(pm::_PM.AbstractPowerModel, i::Int, n::Int)
    alpha_n = _PM.var(pm, n, :alpha_g, i)
    beta_n = _PM.var(pm, n, :beta_g, i)
    gamma_n = _PM.var(pm, n, :gamma_g, i)

    JuMP.@constraint(pm.model, - alpha_n + beta_n - gamma_n == 0)
end

"Linking constraints for generator decision variables for t ≥ T_0"
function constraint_generator_decisions(pm::_PM.AbstractPowerModel, i::Int, n::Int, prev_hour)
    alpha_n = _PM.var(pm, n, :alpha_g, i)
    alpha_n_1 = _PM.var(pm, prev_hour, :alpha_g, i)
    beta_n = _PM.var(pm, n, :beta_g, i)
    gamma_n = _PM.var(pm, n, :gamma_g, i)

    JuMP.@constraint(pm.model, alpha_n_1 - alpha_n + beta_n - gamma_n == 0)
end

"Raamping limits for genertors"
function constraint_generator_ramping(pm::_PM.AbstractPowerModel, i::Int, n::Int, prev_hour, ΔPg_up, ΔPg_down, pmin)
    pg_n = _PM.var(pm, n, :pg, i)
    pg_n_1 = _PM.var(pm, prev_hour, :pg, i)
    alpha_n = _PM.var(pm, n, :alpha_g, i)
    beta_n = _PM.var(pm, n, :beta_g, i)
    gamma_n = _PM.var(pm, n, :gamma_g, i)

    JuMP.@constraint(pm.model, pg_n - pg_n_1 <= ΔPg_up * alpha_n + (pmin - ΔPg_up) * beta_n)
    JuMP.@constraint(pm.model, pg_n_1 - pg_n <= ΔPg_down * alpha_n + pmin * gamma_n)
end

"Generator minimum up-time constraint"
function constraint_minimum_generator_up_time(pm::_PM.AbstractPowerModel, i::Int, n::Int, τ)
    alpha_n = _PM.var(pm, n, :alpha_g, i)

    JuMP.@constraint(pm.model, alpha_n >= sum([_PM.var(pm, t, :beta_g, i) for t in τ]))
end

"Generator minimum down-time constraint"
function constraint_minimum_generator_down_time(pm::_PM.AbstractPowerModel, i::Int, n::Int, τ)
    alpha_n = _PM.var(pm, n, :alpha_g, i)

    JuMP.@constraint(pm.model, (1 - alpha_n) >= sum([_PM.var(pm, t, :gamma_g, i) for t in τ]))
end

"Modelling generator power balance when providing FCR"
function constraint_generator_fcr_power_balance(pm::_PM.AbstractPowerModel, i::Int, n::Int, reference_network_idx)
    pg = _PM.var(pm, n, :pg, i)
    pg_ref = _PM.var(pm, reference_network_idx, :pg, i)
    pg_droop = _PM.var(pm, n, :pg_droop, i)

    JuMP.@constraint(pm.model, pg == pg_ref + pg_droop)
end

"Modelling generator FCR contribution"
function constraint_generator_fcr_contribution(pm::_PM.AbstractPowerModel, i::Int, n::Int, ramp_rate, ΔTin, ΔTdroop)
    pg_droop = _PM.var(pm, n, :pg_droop, i)

    JuMP.@constraint(pm.model, pg_droop >= - ramp_rate * (ΔTdroop - ΔTin))
    JuMP.@constraint(pm.model, pg_droop <=   ramp_rate * (ΔTdroop - ΔTin))
end

"Absolute value of generatoe FCR contribution for post processing"
function  constraint_generator_fcr_contribution_abs(pm::_PM.AbstractPowerModel, i::Int, n::Int)
    pg_droop = _PM.var(pm, n, :pg_droop, i)
    pg_droop_abs = _PM.var(pm, n, :pg_droop_abs, i)

    JuMP.@constraint(pm.model, pg_droop_abs >=  pg_droop)
    JuMP.@constraint(pm.model, pg_droop_abs >= -pg_droop)
end


######################################
# Generator realetd constraints DCP:
######################################
function constraint_generator_inertia_limit(pm::_PM.AbstractDCPModel, n::Int, generator_properties, inertia_limit)
    alpha_g = _PM.var(pm, n, :alpha_g)

    JuMP.@constraint(pm.model, sum([properties["inertia"] * properties["rating"] * alpha_g[g] / 0.9 for (g, properties) in generator_properties])  >= inertia_limit)
end


function constraint_generator_redispatch(pm::_PM.AbstractDCPModel, n::Int, i, pg_ref)
    pg       = _PM.var(pm, n, :pg, i)
    dpg_up   = _PM.var(pm, n, :dpg_up, i)
    dpg_down = _PM.var(pm, n, :dpg_down, i)

    # Starting from the reference dispatch pg_ref, the new dispatch point is pg == pg_ref + dpg_up - dpg_down
    JuMP.@constraint(pm.model, pg == pg_ref + dpg_up - dpg_down)
end


function constraint_generator_on_off(pm::_PM.AbstractDCPModel, n::Int, i, pmax, pmin, status)
    pg = _PM.var(pm, n, :pg, i)
    alpha_g = _PM.var(pm, n, :alpha_g, i)

    JuMP.@constraint(pm.model,  pg <= pmax * alpha_g)
    JuMP.@constraint(pm.model,  pg >= pmin * alpha_g)
    JuMP.@constraint(pm.model,  alpha_g >= status)
end

function constraint_generator_on_off(pm::_PM.AbstractDCPModel, n::Int, nw_ref, i, pmax, pmin, status)
    pg = _PM.var(pm, n, :pg, i)
    alpha_g = _PM.var(pm, nw_ref, :alpha_g, i)

    JuMP.@constraint(pm.model,  pg <= pmax * alpha_g)
    JuMP.@constraint(pm.model,  pg >= pmin * alpha_g)
    JuMP.@constraint(pm.model,  alpha_g >= status)
end

# Generator related constraints NF:

function constraint_generator_inertia_limit(pm::_PM.AbstractNFAModel, n::Int, generator_properties, inertia_limit)
    pg = _PM.var(pm, n, :pg)
    if !isempty(generator_properties)
        JuMP.@constraint(pm.model, sum([properties["inertia"] * pg[g] / 0.9 for (g, properties) in generator_properties])  >= inertia_limit)
    end
end