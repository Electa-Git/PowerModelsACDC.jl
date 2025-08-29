"Variable storage on/off state"
function variable_storage_on_off(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    alpha_s = _PM.var(pm, nw)[:alpha_s] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :storage)], base_name="$(nw)_alpha_s",
    binary = true
    )

    report && _PM.sol_component_value(pm, nw, :storage, :alpha_s, _PM.ids(pm, nw, :storage), alpha_s)
end


# storage constaints for multi - period problems
function storage_constraints(pm, n; uc = false)
    for i in _PM.ids(pm, n, :storage)
        _PM.constraint_storage_thermal_limit(pm, i, nw = n)
        _PM.constraint_storage_losses(pm, i, nw = n)
        if uc == true
            constraint_storage_on_off(pm, i, nw = n)
        end
    end

    ref_nw_id = get_reference_network_id(pm, n; uc = uc)
    final_network_id = sort(collect(_PM.nw_ids(pm)))[end]
    if ref_nw_id == 1
        for i in _PM.ids(pm, n, :storage)
            println(_PM.ref(pm, n, :storage, i)["energy"])
            _PM.constraint_storage_state(pm, i, nw = n)
        end
    elseif ref_nw_id < final_network_id
        prev_nw_id = get_previous_hour_network_id(pm, n; uc = uc)
        for i in _PM.ids(pm, n, :storage)
            storage = _PM.ref(pm, n, :storage, i)
            if haskey(storage, "fixed_energy") && any(storage["fixed_energy"][:,1] .== n)
                constraint_fixed_storage_state(pm, i; nw = n)
                _PM.constraint_storage_state(pm, i, prev_nw_id, ref_nw_id)
            else
                _PM.constraint_storage_state(pm, i, prev_nw_id, ref_nw_id)
            end
        end
    else
        prev_nw_id = get_previous_hour_network_id(pm, n; uc = uc)
        for i in _PM.ids(pm, n, :storage)
            constraint_storage_state_final(pm, i; nw = n)
            _PM.constraint_storage_state(pm, i, prev_nw_id, ref_nw_id)
        end
    end
end

# Constraint template for storage on/off constraints
"On / off constraints for storage units"
function constraint_storage_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    storage     = _PM.ref(pm, nw, :storage, i)
    charge_rating = storage["charge_rating"]
    discharge_rating = storage["discharge_rating"]

    nw_ref = get_reference_network_id(pm, nw)
    constraint_storage_on_off(pm, nw_ref, i, charge_rating, discharge_rating)
end

#### DCP constraints
"On / off constraints for storage units"
function constraint_storage_on_off(pm::_PM.AbstractDCPModel, n::Int, i, charge_rating, discharge_rating)
    pc = _PM.var(pm, n, :sc, i)
    pd = _PM.var(pm, n, :sd, i)
    ps = _PM.var(pm, n, :ps, i)
    alpha_s = _PM.var(pm, n, :alpha_s, i)

    JuMP.@constraint(pm.model,  pc <= charge_rating * alpha_s)
    JuMP.@constraint(pm.model,  pc >= 0)
    JuMP.@constraint(pm.model,  pd <= discharge_rating * alpha_s)
    JuMP.@constraint(pm.model,  pd >= 0)
    JuMP.@constraint(pm.model,  ps <= discharge_rating * alpha_s)
    JuMP.@constraint(pm.model,  ps >= -discharge_rating * alpha_s)
end

## Reserve raletd constraints
function constraint_storage_fcr_contribution(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    storage = _PM.ref(pm, nw, :storage, i)
    ramp_rate = storage["ramp_rate_per_s"]

    ΔTin = _PM.ref(pm, nw, :frequency_parameters)["t_fcr"]
    ΔTdroop = _PM.ref(pm, nw, :frequency_parameters)["t_fcrd"]

    return constraint_storage_fcr_contribution(pm, i, nw, ramp_rate, ΔTin, ΔTdroop)
end

function constraint_storage_fcr_contribution_abs(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    constraint_storage_fcr_contribution_abs(pm, i, nw)
end

function constraint_storage_fcr_contribution(pm::_PM.AbstractPowerModel, i::Int, n::Int, ramp_rate, ΔTin, ΔTdroop)
    ps_droop = _PM.var(pm, n, :ps_droop, i)

    JuMP.@constraint(pm.model, ps_droop >= - ramp_rate * (ΔTdroop - ΔTin))
    JuMP.@constraint(pm.model, ps_droop <=   ramp_rate * (ΔTdroop - ΔTin))
end


function  constraint_storage_fcr_contribution_abs(pm::_PM.AbstractPowerModel, i::Int, n::Int)
    ps_droop = _PM.var(pm, n, :ps_droop, i)
    ps_droop_abs = _PM.var(pm, n, :ps_droop_abs, i)

    JuMP.@constraint(pm.model, ps_droop_abs >=  ps_droop)
    JuMP.@constraint(pm.model, ps_droop_abs >= -ps_droop)
end



function constraint_storage_state_final(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    initial_energy = _PM.ref(pm, nw, :storage, i)["energy"]

    constraint_storage_state_final(pm, nw, initial_energy, i)
end


function constraint_storage_state_final(pm::_PM.AbstractPowerModel, n, initial_energy, i)
    se_final = _PM.var(pm, n, :se, i)

    JuMP.@constraint(pm.model, se_final >= initial_energy)
end


function constraint_fixed_storage_state(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    fixed_energy_vector = _PM.ref(pm, nw, :storage, i)["fixed_energy"]
    nw_id = findall(fixed_energy_vector[:,1] .== nw)
    fixed_energy = fixed_energy_vector[nw_id, 2][1]
    constraint_fixed_storage_state(pm, nw, i, fixed_energy)
end

function constraint_fixed_storage_state(pm::_PM.AbstractPowerModel, n::Int, i::Int, fixed_energy)
    se = _PM.var(pm, n, :se, i)

    JuMP.@constraint(pm.model, se == fixed_energy)
end