function constraint_thermal_limit_from(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    if haskey(branch, "rate_a")
        if haskey(branch, "short_term_rating_factor")
            rate_a = branch["rate_a"] * branch["short_term_rating_factor"]
        else
            rate_a = branch["rate_a"]
        end
        constraint_thermal_limit_from(pm, nw, f_idx, rate_a)
    end
end


function constraint_thermal_limit_to(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    t_idx = (i, t_bus, f_bus)

    if haskey(branch, "rate_a")
        if haskey(branch, "short_term_rating_factor")
            rate_a = branch["rate_a"] * branch["short_term_rating_factor"]
        else
            rate_a = branch["rate_a"]
        end
        constraint_thermal_limit_to(pm, nw, t_idx, rate_a)
    end
end


# DCP constraints TODO all ither formulations
"nothing to do, this model is symetric"
function constraint_thermal_limit_to(pm::_PM.AbstractPowerModel, n::Int, t_idx, rate_a)
    # NOTE correct?
    l,i,j = t_idx
    p_fr = _PM.var(pm, n, :p, (l,j,i))
    if isa(p_fr, JuMP.VariableRef) && JuMP.has_upper_bound(p_fr)
        cstr = JuMP.UpperBoundRef(p_fr)
    else
        p_to = _PM.var(pm, n, :p, t_idx)
        cstr = JuMP.@constraint(pm.model, p_to <= rate_a)
    end

    if _IM.report_duals(pm)
        _PM.sol(pm, n, :branch, t_idx[1])[:mu_sm_to] = cstr
    end
end