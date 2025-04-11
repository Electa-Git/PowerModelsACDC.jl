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
    if ref_nw_id == 1
        for i in _PM.ids(pm, n, :storage)
            _PM.constraint_storage_state(pm, i, nw = n)
        end
    else
        prev_nw_id = get_previous_hour_network_id(pm, n; uc = uc)
        for i in _PM.ids(pm, n, :storage)
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