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