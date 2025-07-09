"Collect all vaiables for flexible demand"
function variable_flexible_demand(pm::_PM.AbstractPowerModel; kwargs...)
    variable_total_flex_demand(pm; kwargs...)
    variable_demand_reduction(pm; kwargs...)
    variable_demand_curtailment(pm; kwargs...)
end

function variable_total_flex_demand(pm::_PM.AbstractPowerModel; kwargs...)
    variable_total_flex_demand_active(pm; kwargs...)
    variable_total_flex_demand_reactive(pm; kwargs...)
end

"Variable for the actual (flexible) real load demand at each load point and each time step"
function variable_total_flex_demand_active(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    pflex = _PM.var(pm, nw)[:pflex] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_pflex",
        lower_bound = min(0, _PM.ref(pm, nw, :load, i, "pd")),
        upper_bound = max(0, _PM.ref(pm, nw, :load, i, "pd")),
        start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "pd")
    )
    report && _PM.sol_component_value(pm, nw, :load, :pflex, _PM.ids(pm, nw, :load), pflex)
end

function variable_total_flex_demand_reactive(pm::_PM.AbstractActivePowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
end

"Variable for the actual (flexible) reactive load demand at each load point and each time step"
function variable_total_flex_demand_reactive(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    qflex = _PM.var(pm, nw)[:qflex] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_qflex",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "qd"),
        lower_bound = -abs(_PM.ref(pm, nw, :load, i, "qd")),
        upper_bound =  abs(_PM.ref(pm, nw, :load, i, "qd")),
    )
    report && _PM.sol_component_value(pm, nw, :load, :qflex, _PM.ids(pm, nw, :load), qflex)
end


"Variable for the power not consumed (voluntary load reduction) at each flex load point and each time step"
function variable_demand_reduction(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    pred = _PM.var(pm, nw)[:pred] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :flex_load)], base_name="$(nw)_pred",
        lower_bound = 0,
        upper_bound = max(0, _PM.ref(pm, nw, :load, i, "pd")) * _PM.ref(pm, nw, :flex_load, i, "pred_rel_max"),
        start = 0
    )
    if report
        _PM.sol_component_value(pm, nw, :load, :pred, _PM.ids(pm, nw, :flex_load), pred)
    end
end

"Variable for load curtailment (i.e. involuntary demand reduction) at each load point and each time step"
function variable_demand_curtailment(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    pcurt = _PM.var(pm, nw)[:pcurt] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_pcurt",
        lower_bound = 0,
        upper_bound = max(0, _PM.ref(pm, nw, :load, i, "pd")),
        start = 0
    )
    report && _PM.sol_component_value(pm, nw, :load, :pcurt, _PM.ids(pm, nw, :load), pcurt)
end

"Calculate the operational cost of flexible demand"
function calc_load_operational_cost_uc(pm::_PM.AbstractPowerModel)
    load_cost_red = Dict()
    load_cost_curt = Dict()
    for n in pm.ref[:it][:pm][:hour_ids]
        for (l, load) in _PM.nws(pm)[n][:load]
            p_red = _PM.var(pm, n, :pred, l)
            p_curt = _PM.var(pm, n, :pcurt, l)
            load_cost_red[n, l] = load["cost_red"]  * p_red
            load_cost_curt[n, l] = load["cost_curt"] * p_curt
        end
    end

    return load_cost_red, load_cost_curt
end

"Constraint template for flexible demand"
function constraint_total_flexible_demand(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    load     = _PM.ref(pm, nw, :load, i)
    pd       = load["pd"]
    pf_angle = atan(load["qd"] / load["pd"]) # Power factor angle, in radians

    constraint_total_flexible_demand(pm, nw, i, pd, pf_angle)
end

function constraint_total_fixed_demand(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    load     = _PM.ref(pm, nw, :load, i)
    pd       = load["pd"]
    qd       = load["qd"]
    pf_angle = atan(load["qd"] / load["pd"])  # Power factor angle, in radians
    constraint_total_fixed_demand(pm, nw, i, pd, qd, pf_angle)
end

"All demand related constraints for supported formulations"
# ACP
function constraint_total_flexible_demand(pm::_PM.AbstractACPModel, n::Int, i, pd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)
    pred        = _PM.var(pm, n, :pred, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd - pcurt - pred)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end

function constraint_total_fixed_demand(pm::_PM.AbstractACPModel, n::Int, i, pd, qd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd)
    JuMP.@constraint(pm.model, pcurt == 0.0)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == qd)
    # JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end
# ACR
function constraint_total_flexible_demand(pm::_PM.AbstractACRModel, n::Int, i, pd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)
    pred        = _PM.var(pm, n, :pred, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd - pcurt - pred)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end

function constraint_total_fixed_demand(pm::_PM.AbstractACRModel, n::Int, i, pd, qd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd)
    JuMP.@constraint(pm.model, pcurt == 0.0)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end
# IVR
function constraint_total_flexible_demand(pm::_PM.AbstractIVRModel, n::Int, i, pd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)
    pred        = _PM.var(pm, n, :pred, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd - pcurt - pred)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end

function constraint_total_fixed_demand(pm::_PM.AbstractIVRModel, n::Int, i, pd, qd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd)
    JuMP.@constraint(pm.model, pcurt == 0.0)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end
# DCP
function constraint_total_flexible_demand(pm::_PM.AbstractDCPModel, n::Int, i, pd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)
    pred        = _PM.var(pm, n, :pred, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd - pcurt - pred)
end

function constraint_total_fixed_demand(pm::_PM.AbstractDCPModel, n::Int, i, pd, qd, pf_angle)
    pflex  = _PM.var(pm, n, :pflex, i)
    pcurt  = _PM.var(pm, n, :pcurt, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd)
    JuMP.@constraint(pm.model, pcurt == 0.0)
end
# LPAC
function constraint_total_flexible_demand(pm::_PM.AbstractLPACModel, n::Int, i, pd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)
    pred        = _PM.var(pm, n, :pred, i)
    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd - pcurt - pred)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end

function constraint_total_fixed_demand(pm::_PM.AbstractLPACModel, n::Int, i, pd, qd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)
    qflex       = _PM.var(pm, n, :qflex, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd)
    JuMP.@constraint(pm.model, pcurt == 0.0)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end
# NF
function constraint_total_flexible_demand(pm::_PM.AbstractAPLossLessModels, n::Int, i, pd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)
    pred        = _PM.var(pm, n, :pred, i)
    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd - pcurt - pred)
end

function constraint_total_fixed_demand(pm::_PM.AbstractAPLossLessModels, n::Int, i, pd, qd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd)
    JuMP.@constraint(pm.model, pcurt == 0.0)
end
# SOCWR
function constraint_total_flexible_demand(pm::_PM.AbstractWModels, n::Int, i, pd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)
    pred        = _PM.var(pm, n, :pred, i)
    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd - pcurt - pred)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end

function constraint_total_fixed_demand(pm::_PM.AbstractWModels, n::Int, i, pd, qd, pf_angle)
    pflex       = _PM.var(pm, n, :pflex, i)
    qflex       = _PM.var(pm, n, :qflex, i)
    pcurt       = _PM.var(pm, n, :pcurt, i)

    # Active power demand is the reference demand `pd` plus the contributions from all the demand flexibility decision variables
    JuMP.@constraint(pm.model, pflex == pd)
    JuMP.@constraint(pm.model, pcurt == 0.0)

    # Reactive power demand is given by the active power demand and the power factor angle of the load
    JuMP.@constraint(pm.model, qflex == tan(pf_angle) * pflex)
end
# IVRPowerModel
function variable_load_current(pm::_PM.AbstractIVRModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true, kwargs...)
    variable_load_current_real(pm, nw=nw, bounded=bounded, report=report; kwargs...)
    variable_load_current_imaginary(pm, nw=nw, bounded=bounded, report=report; kwargs...)

    # store active and reactive power expressions for use in flexible demand constraints, objective + post processing
    for (i,load) in _PM.ref(pm, nw, :load)
        busid = load["load_bus"]
        vr = _PM.var(pm, nw, :vr, busid)
        vi = _PM.var(pm, nw, :vi, busid)
        crl = _PM.var(pm, nw, :crl, i)
        cil = _PM.var(pm, nw, :cil, i)
        pflex = _PM.var(pm, nw, :pflex, i)
        qflex = _PM.var(pm, nw, :qflex, i)
        JuMP.@constraint(pm.model, pflex == vr*crl  + vi*cil)
        JuMP.@constraint(pm.model, qflex == vi*crl  - vr*cil)
    end
    # _PM.var(pm, nw)[:pflex] = pflex
    # _PM.var(pm, nw)[:qflex] = qflex
    # report && _PM.sol_component_value(pm, nw, :load, :pflex, _PM.ids(pm, nw, :load), pflex)
    # report && _PM.sol_component_value(pm, nw, :load, :qflex, _PM.ids(pm, nw, :load), qflex)
end
function variable_load_current_real(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    crl = _PM.var(pm, nw)[:crl] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_crl",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "crl_start")
    )

    if bounded
        bus = _PM.ref(pm, nw, :bus)
        for (i, l) in _PM.ref(pm, nw, :load)
            vmin = bus[l["load_bus"]]["vmin"]
            @assert vmin > 0
            s = sqrt(l["pd"]^2 +l["qd"]^2)
            ub = s/vmin

            JuMP.set_lower_bound(crl[i], -ub)
            JuMP.set_upper_bound(crl[i],  ub)
        end
    end

    report && _PM.sol_component_value(pm, nw, :load, :crl, _PM.ids(pm, nw, :load), crl)
end
function variable_load_current_imaginary(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    cil = _PM.var(pm, nw)[:cil] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :load)], base_name="$(nw)_cil",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :load, i), "cil_start")
    )

    if bounded
        bus = _PM.ref(pm, nw, :bus)
        for (i, l) in _PM.ref(pm, nw, :load)
            vmin = bus[l["load_bus"]]["vmin"]
            @assert vmin > 0
            s = sqrt(l["pd"]^2 +l["qd"]^2)
            ub = s/vmin

            JuMP.set_lower_bound(cil[i], -ub)
            JuMP.set_upper_bound(cil[i],  ub)
        end
    end

    report && _PM.sol_component_value(pm, nw, :load, :cil, _PM.ids(pm, nw, :load), cil)
end
