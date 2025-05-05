function variable_pst(pm::_PM.AbstractPowerModel; kwargs...)
    variable_active_pst_flow(pm; kwargs...)
    variable_reactive_pst_flow(pm; kwargs...)
    variable_pst_angle(pm; kwargs...)
    variable_pst_cosine(pm; kwargs...)
end

"variable: `p[l,i,j]` for `(l,i,j)` in `pst_arcs`"
function variable_active_pst_flow(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    p = _PM.var(pm, nw)[:ppst] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs_pst)], base_name="$(nw)_ppst",
        start = 0
    )

    if bounded
        for arc in _PM.ref(pm, nw, :arcs_pst)
            l,i,j = arc
                JuMP.set_lower_bound(p[arc], -_PM.ref(pm, nw, :pst, l)["rate_a"])
                JuMP.set_upper_bound(p[arc], _PM.ref(pm, nw, :pst, l)["rate_a"])
        end
    end

    report && _PM.sol_component_value_edge(pm, nw, :pst, :pf, :pt, _PM.ref(pm, nw, :arcs_from_pst), _PM.ref(pm, nw, :arcs_to_pst), p)
end

"variable: `q[l,i,j]` for `(l,i,j)` in `pst_arcs`"
function variable_reactive_pst_flow(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    q = _PM.var(pm, nw)[:qpst] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs_pst)], base_name="$(nw)_qpst",
        start = 0
    )

    if bounded
        for arc in _PM.ref(pm, nw, :arcs_pst)
            l,i,j = arc
                JuMP.set_lower_bound(q[arc], -_PM.ref(pm, nw, :pst, l)["rate_a"])
                JuMP.set_upper_bound(q[arc], _PM.ref(pm, nw, :pst, l)["rate_a"])
        end
    end

    report && _PM.sol_component_value_edge(pm, nw, :pst, :qf, :qt, _PM.ref(pm, nw, :arcs_from_pst), _PM.ref(pm, nw, :arcs_to_pst), q)
end

"variable: psta[i] for PSTs"
function variable_pst_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    alpha = _PM.var(pm, nw)[:psta] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :pst)], base_name="$(nw)_psta",
        start = 0
    )
    if bounded
        for (i, pst) in _PM.ref(pm, nw, :pst)
            JuMP.set_lower_bound(alpha[i], pst["angmin"])
            JuMP.set_upper_bound(alpha[i], pst["angmax"])
        end
    end
    report && _PM.sol_component_value(pm, nw, :pst, :alpha, _PM.ids(pm, nw, :pst), alpha)
end

function variable_pst_cosine(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
end

function variable_pst_cosine(pm::_PM.LPACCPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    cs_pst = _PM.var(pm, nw)[:cs_pst] = JuMP.@variable(pm.model,
        [bp in _PM.ids(pm, nw, :buspairs_pst)], base_name="$(nw)_cs",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :buspairs_pst, bp), "cs_start", 1.0)
    )

    if bounded
        for (bp, buspair) in _PM.ref(pm, nw, :buspairs_pst)
            angmin = buspair["angmin"]
            angmax = buspair["angmax"]
            if angmin >= 0
                cos_max = cos(angmin)
                cos_min = cos(angmax)
            end
            if angmax <= 0
                cos_max = cos(angmax)
                cos_min = cos(angmin)
            end
            if angmin < 0 && angmax > 0
                cos_max = 1.0
                cos_min = min(cos(angmin), cos(angmax))
            end

            JuMP.set_lower_bound(cs_pst[bp], cos_min)
            JuMP.set_upper_bound(cs_pst[bp], cos_max)
        end
    end

    report && _PM.sol_component_value_buspair(pm, nw, :buspairs_pst, :cs_pst, _PM.ids(pm, nw, :buspairs_pst), cs_pst)
end

"Constraint template for PSTs"
function constraint_ohms_y_from_pst(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    pst = _PM.ref(pm, nw, :pst, i)
    f_bus = pst["f_bus"]
    t_bus = pst["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_admittance(pst, "pst")
    g_fr = pst["g_fr"]
    b_fr = pst["b_fr"]

    constraint_ohms_y_from_pst(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
end

function constraint_ohms_y_to_pst(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    pst = _PM.ref(pm, nw, :pst, i)
    f_bus = pst["f_bus"]
    t_bus = pst["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_admittance(pst, "pst")
    g_to = pst["g_to"]
    b_to = pst["b_to"]

    constraint_ohms_y_to_pst(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
end

"All PST related constraints for supported formulations"
# ACP
function constraint_ohms_y_from_pst(pm::_PM.AbstractACPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    alpha = _PM.var(pm, n,  :psta, i)
    p_fr  = _PM.var(pm, n,  :ppst, f_idx)
    q_fr  = _PM.var(pm, n,  :qpst, f_idx)
    vm_fr = _PM.var(pm, n, :vm, f_bus)
    vm_to = _PM.var(pm, n, :vm, t_bus)
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)

    JuMP.@constraint(pm.model, p_fr ==  (g+g_fr)*(vm_fr)^2 - g*vm_fr*vm_to*cos(va_fr-va_to-alpha) + -b*vm_fr*vm_to*sin(va_fr-va_to-alpha) )
    JuMP.@constraint(pm.model, q_fr == -(b+b_fr)*(vm_fr)^2 + b*vm_fr*vm_to*cos(va_fr-va_to-alpha) + -g*vm_fr*vm_to*sin(va_fr-va_to-alpha) )
end

function constraint_ohms_y_to_pst(pm::_PM.AbstractACPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
    alpha = _PM.var(pm, n,  :psta, i)
    p_to  = _PM.var(pm, n,  :ppst, t_idx)
    q_to  = _PM.var(pm, n,  :qpst, t_idx)
    vm_fr = _PM.var(pm, n, :vm, f_bus)
    vm_to = _PM.var(pm, n, :vm, t_bus)
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)

    JuMP.@constraint(pm.model, p_to ==  (g+g_to)*vm_to^2 - g*vm_to*vm_fr*cos(va_to-va_fr+alpha) + -b*vm_to*vm_fr*sin(va_to-va_fr+alpha) )
    JuMP.@constraint(pm.model, q_to == -(b+b_to)*vm_to^2 + b*vm_to*vm_fr*cos(va_to-va_fr+alpha) + -g*vm_to*vm_fr*sin(va_to-va_fr+alpha) )
end

function constraint_limits_pst(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    pst = _PM.ref(pm, nw, :pst, i)
    srated = pst["rate_a"]
    angmin = pst["angmin"]
    angmax = pst["angmax"]

    f_bus = pst["f_bus"]
    t_bus = pst["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    alpha = _PM.var(pm, nw,  :psta, i)
    p_fr  = _PM.var(pm, nw,  :ppst, f_idx)
    q_fr  = _PM.var(pm, nw,  :qpst, f_idx)
    p_to  = _PM.var(pm, nw,  :ppst, t_idx)
    q_to  = _PM.var(pm, nw,  :qpst, t_idx)

    JuMP.@constraint(pm.model, p_fr^2 + q_fr^2 <= srated^2)
    JuMP.@constraint(pm.model, p_to^2 + q_to^2 <= srated^2)
    JuMP.@constraint(pm.model, alpha <= angmax)
    JuMP.@constraint(pm.model, alpha >= angmin)
end

# DCP
function constraint_ohms_y_from_pst(pm::_PM.AbstractDCPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    alpha = _PM.var(pm, n,  :psta, i)
    p_fr  = _PM.var(pm, n,  :ppst, f_idx)
    vm = 1
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)

    JuMP.@constraint(pm.model, p_fr ==   -b * vm * (va_fr - va_to - alpha))
end

function constraint_ohms_y_to_pst(pm::_PM.AbstractDCPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
    alpha = _PM.var(pm, n,  :psta, i)
    p_to  = _PM.var(pm, n,  :ppst, t_idx)
    p_f = _PM.var(pm, n,  :ppst, f_idx)
    vm = 1
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)

    JuMP.@constraint(pm.model, p_to == - p_f)
end

function constraint_limits_pst(pm::_PM.AbstractDCPModel, i::Int; nw::Int=_PM.nw_id_default)
    pst = _PM.ref(pm, nw, :pst, i)
    srated = pst["rate_a"]
    angmin = pst["angmin"]
    angmax = pst["angmax"]

    f_bus = pst["f_bus"]
    t_bus = pst["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    alpha = _PM.var(pm, nw,  :psta, i)
    p_fr  = _PM.var(pm, nw,  :ppst, f_idx)
    p_to  = _PM.var(pm, nw,  :ppst, t_idx)

    JuMP.@constraint(pm.model, -srated <= p_fr <= srated)
    JuMP.@constraint(pm.model, -srated <= p_to <= srated)
    JuMP.@constraint(pm.model, alpha <= angmax)
    JuMP.@constraint(pm.model, alpha >= angmin)
end

# LPAC
function constraint_ohms_y_from_pst(pm::_PM.AbstractLPACModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    alpha = _PM.var(pm, n,  :psta, i)
    p_fr  = _PM.var(pm, n,  :ppst, f_idx)
    q_fr  = _PM.var(pm, n,  :qpst, f_idx)

    phi_fr = _PM.var(pm, n, :phi, f_bus)
    phi_to = _PM.var(pm, n, :phi, t_bus)
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)
    cs = _PM.var(pm, n, :cs_pst, (f_bus, t_bus))

    JuMP.@constraint(pm.model, p_fr ==  g * (1.0 + 2*phi_fr) - g * (cs + phi_fr + phi_to) - b * (va_fr - va_to - alpha))
    JuMP.@constraint(pm.model, q_fr == -b * (1.0 + 2*phi_fr) + b * (cs + phi_fr + phi_to) - g * (va_fr - va_to - alpha))
end
function constraint_ohms_y_to_pst(pm::_PM.AbstractLPACModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    alpha = _PM.var(pm, n,  :psta, i)
    p_to  = _PM.var(pm, n,  :ppst, t_idx)
    q_to  = _PM.var(pm, n,  :qpst, t_idx)

    phi_fr = _PM.var(pm, n, :phi, f_bus)
    phi_to = _PM.var(pm, n, :phi, t_bus)
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)
    cs = _PM.var(pm, n, :cs_pst, (f_bus, t_bus))

    JuMP.@constraint(pm.model, p_to ==  g * (1.0 + 2 * phi_to) - g * (cs + phi_fr + phi_to) -b * (va_to - va_fr + alpha))
    JuMP.@constraint(pm.model, q_to == -b * (1.0 + 2 * phi_to) + b * (cs + phi_fr + phi_to) -g * (va_to - va_fr + alpha))
end
function constraint_limits_pst(pm::_PM.AbstractLPACModel, i::Int; nw::Int=_PM.nw_id_default)
    pst = _PM.ref(pm, nw, :pst, i)
    srated = pst["rate_a"]
    angmin = pst["angmin"]
    angmax = pst["angmax"]

    f_bus = pst["f_bus"]
    t_bus = pst["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    alpha = _PM.var(pm, nw,  :psta, i)
    p_fr  = _PM.var(pm, nw,  :ppst, f_idx)
    q_fr  = _PM.var(pm, nw,  :qpst, f_idx)
    p_to  = _PM.var(pm, nw,  :ppst, t_idx)
    q_to  = _PM.var(pm, nw,  :qpst, t_idx)

    JuMP.@constraint(pm.model, p_fr^2 + q_fr^2 <= srated^2)
    JuMP.@constraint(pm.model, p_to^2 + q_to^2 <= srated^2)
    JuMP.@constraint(pm.model, alpha <= angmax)
    JuMP.@constraint(pm.model, alpha >= angmin)
end
# SOCWR
function constraint_ohms_y_from_pst(pm::_PM.AbstractWModels, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    print("PSTs not yet defined for SOC formulations", "\n")
end
function constraint_ohms_y_to_pst(pm::_PM.AbstractWModels, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    print("PSTs not yet defined for SOC formulations", "\n")
end
function constraint_limits_pst(pm::_PM.AbstractWModels, i::Int; nw::Int=_PM.nw_id_default)
    print("PSTs not yet defined for SOC formulations", "\n")
end