function variable_sssc(pm::_PM.AbstractPowerModel; kwargs...)
    variable_sssc_quadrature_voltage(pm; kwargs...)
    variable_sssc_equivalent_angle(pm; kwargs...)
    variable_active_sssc_flow(pm; kwargs...)
    variable_reactive_sssc_flow(pm; kwargs...)
end

"variable: `vq[i]` for `i` in `sssc`"
function variable_sssc_quadrature_voltage(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    vq = _PM.var(pm, nw)[:vqsssc] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :sssc)], base_name="$(nw)_vqsssc",
        start = 0
    )

    if bounded
        for (s, sssc) in _PM.ref(pm, nw, :sssc)
            JuMP.set_lower_bound(vq[s], sssc["vqmin"])
            JuMP.set_upper_bound(vq[s], sssc["vqmax"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :sssc, :vq, _PM.ids(pm, nw, :sssc), vq)
end

function variable_sssc_equivalent_angle(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    αq = _PM.var(pm, nw)[:alphaqsssc] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :sssc)], base_name="$(nw)_alphaqsssc",
        start = 0
    )

    if bounded
        for (s, sssc) in _PM.ref(pm, nw, :sssc)
            JuMP.set_lower_bound(αq[s], -atan(abs(sssc["vqmin"])))
            JuMP.set_upper_bound(αq[s],  atan(abs(sssc["vqmax"])))
        end
    end

    report && _PM.sol_component_value(pm, nw, :sssc, :alpha, _PM.ids(pm, nw, :sssc), αq)
end

"variable: `p[l,i,j]` for `(l,i,j)` in `sssc_arcs`"
function variable_active_sssc_flow(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    p = _PM.var(pm, nw)[:psssc] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs_sssc)], base_name="$(nw)_psssc",
        start = 0
    )

    if bounded
        for arc in _PM.ref(pm, nw, :arcs_sssc)
            l,i,j = arc
                JuMP.set_lower_bound(p[arc], -_PM.ref(pm, nw, :sssc, l)["rate_a"])
                JuMP.set_upper_bound(p[arc],  _PM.ref(pm, nw, :sssc, l)["rate_a"])
        end
    end

    report && _PM.sol_component_value_edge(pm, nw, :sssc, :pf, :pt, _PM.ref(pm, nw, :arcs_from_sssc), _PM.ref(pm, nw, :arcs_to_sssc), p)
end

"variable: `p[l,i,j]` for `(l,i,j)` in `sssc_arcs`"
function variable_reactive_sssc_flow(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    q = _PM.var(pm, nw)[:qsssc] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs_sssc)], base_name="$(nw)_psssc",
        start = 0
    )

    if bounded
        for arc in _PM.ref(pm, nw, :arcs_sssc)
            l,i,j = arc
                JuMP.set_lower_bound(q[arc], -_PM.ref(pm, nw, :sssc, l)["rate_a"])
                JuMP.set_upper_bound(q[arc],  _PM.ref(pm, nw, :sssc, l)["rate_a"])
        end
    end

    report && _PM.sol_component_value_edge(pm, nw, :sssc, :qf, :qt, _PM.ref(pm, nw, :arcs_from_sssc), _PM.ref(pm, nw, :arcs_to_sssc), q)
end

"Constraint template for SSSC"
function constraint_ohms_y_from_sssc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    sssc = _PM.ref(pm, nw, :sssc, i)
    f_bus = sssc["f_bus"]
    t_bus = sssc["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_admittance(sssc, "sssc")
    g_fr = sssc["g_fr"]
    b_fr = sssc["b_fr"]

    constraint_ohms_y_from_sssc(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
end

function constraint_ohms_y_to_sssc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    sssc = _PM.ref(pm, nw, :sssc, i)
    f_bus = sssc["f_bus"]
    t_bus = sssc["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = calc_branch_admittance(sssc, "sssc")
    g_to = sssc["g_fr"]
    b_to = sssc["b_fr"]

    constraint_ohms_y_to_sssc(pm, nw, i, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
end

"All SSSCs related constraints for supported formulations"
# common
function constraint_limits_sssc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    sssc = _PM.ref(pm, nw, :sssc, i)
    srated = sssc["rate_a"]
    f_bus = sssc["f_bus"]
    t_bus = sssc["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    p_fr  = _PM.var(pm, nw,  :psssc, f_idx)
    q_fr  = _PM.var(pm, nw,  :qsssc, f_idx)
    p_to  = _PM.var(pm, nw,  :psssc, t_idx)
    q_to  = _PM.var(pm, nw,  :qsssc, t_idx)

    JuMP.@constraint(pm.model, p_fr^2 + q_fr^2 <= srated^2)
    JuMP.@constraint(pm.model, p_to^2 + q_to^2 <= srated^2)
end
# ACP
function constraint_ohms_y_from_sssc(pm::_PM.AbstractACPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    vq = _PM.var(pm, n,  :vqsssc, i)
    p_fr  = _PM.var(pm, n,  :psssc, f_idx)
    q_fr  = _PM.var(pm, n,  :qsssc, f_idx)
    vm_fr = _PM.var(pm, n, :vm, f_bus)
    vm_to = _PM.var(pm, n, :vm, t_bus)
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)


    vm_fr_star =  JuMP.@expression(pm.model, sqrt(vm_fr^2 + 2 * vm_fr * sin(va_fr) * vq + vq^2))
    va_fr_star =  JuMP.@expression(pm.model, atan((vm_fr * sin(va_fr) + vq) / (vm_fr * cos(va_fr))))

    JuMP.@constraint(pm.model, p_fr ==  (g+g_fr)*(vm_fr_star)^2 - g*vm_fr_star*vm_to*cos(va_fr_star-va_to) + -b*vm_fr_star*vm_to*sin(va_fr_star-va_to) )
    JuMP.@constraint(pm.model, q_fr == -(b+b_fr)*(vm_fr_star)^2 + b*vm_fr_star*vm_to*cos(va_fr_star-va_to) + -g*vm_fr_star*vm_to*sin(va_fr_star-va_to) )
end

function constraint_ohms_y_to_sssc(pm::_PM.AbstractACPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
    vq = _PM.var(pm, n,  :vqsssc, i)
    p_to  = _PM.var(pm, n,  :psssc, t_idx)
    q_to  = _PM.var(pm, n,  :qsssc, t_idx)
    vm_fr = _PM.var(pm, n, :vm, f_bus)
    vm_to = _PM.var(pm, n, :vm, t_bus)
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)

    vm_fr_star =  JuMP.@expression(pm.model, sqrt(vm_fr^2 + 2 * vm_fr * sin(va_fr) * vq + vq^2))
    va_fr_star =  JuMP.@expression(pm.model, atan((vm_fr * sin(va_fr) + vq) / (vm_fr * cos(va_fr))))


    JuMP.@constraint(pm.model, p_to ==  (g+g_to)*vm_to^2 - g*vm_to*vm_fr_star*cos(va_to-va_fr_star) + -b*vm_to*vm_fr_star*sin(va_to-va_fr_star) )
    JuMP.@constraint(pm.model, q_to == -(b+b_to)*vm_to^2 + b*vm_to*vm_fr_star*cos(va_to-va_fr_star) + -g*vm_to*vm_fr_star*sin(va_to-va_fr_star) )
end

# ACR
function constraint_ohms_y_from_sssc(pm::_PM.AbstractACRModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    vq = _PM.var(pm, n,  :vqsssc, i)
    p_fr = _PM.var(pm, n, :psssc, f_idx)
    q_fr = _PM.var(pm, n, :qsssc, f_idx)
    vr_fr = _PM.var(pm, n, :vr, f_bus)
    vr_to = _PM.var(pm, n, :vr, t_bus)
    vi_fr = _PM.var(pm, n, :vi, f_bus)
    vi_to = _PM.var(pm, n, :vi, t_bus)

    vi_fr_star =  JuMP.@expression(pm.model, vi_fr + vq)
    JuMP.@constraint(pm.model, p_fr ==  (g+g_fr)*(vr_fr^2 + vi_fr_star^2) + (-g)*(vr_fr*vr_to + vi_fr_star*vi_to) + (-b)*(vi_fr_star*vr_to - vr_fr*vi_to) )
    JuMP.@constraint(pm.model, q_fr == -(b+b_fr)*(vr_fr^2 + vi_fr_star^2) - (-b)*(vr_fr*vr_to + vi_fr_star*vi_to) + (-g)*(vi_fr_star*vr_to - vr_fr*vi_to) )
end


function constraint_ohms_y_to_sssc(pm::_PM.AbstractACRModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
    vq = _PM.var(pm, n,  :vqsssc, i)
    p_to = _PM.var(pm, n, :psssc, t_idx)
    q_to = _PM.var(pm, n, :qsssc, t_idx)
    vr_fr = _PM.var(pm, n, :vr, f_bus)
    vr_to = _PM.var(pm, n, :vr, t_bus)
    vi_fr = _PM.var(pm, n, :vi, f_bus)
    vi_to = _PM.var(pm, n, :vi, t_bus)

    vi_fr_star =  JuMP.@expression(pm.model, vi_fr + vq)
    JuMP.@constraint(pm.model, p_to ==  (g+g_to)*(vr_to^2 + vi_to^2) + (-g)*(vr_fr*vr_to + vi_fr_star*vi_to) + (-b)*(-(vi_fr_star*vr_to - vr_fr*vi_to)) )
    JuMP.@constraint(pm.model, q_to == -(b+b_to)*(vr_to^2 + vi_to^2) - (-b)*(vr_fr*vr_to + vi_fr_star*vi_to) + (-g)*(-(vi_fr_star*vr_to - vr_fr*vi_to)) )
end


function constraint_limits_sssc(pm::_PM.DCPPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    sssc = _PM.ref(pm, nw, :sssc, i)
    srated = sssc["rate_a"]

    f_bus = sssc["f_bus"]
    t_bus = sssc["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    p_fr  = _PM.var(pm, nw,  :psssc, f_idx)
    p_to  = _PM.var(pm, nw,  :psssc, t_idx)

    JuMP.@constraint(pm.model, -srated <= p_fr <= srated)
    JuMP.@constraint(pm.model, -srated <= p_to <= srated)
end

function constraint_ohms_y_from_sssc(pm::_PM.AbstractDCPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr)
    alpha = _PM.var(pm, n,  :alphaqsssc, i)
    p_fr  = _PM.var(pm, n,  :psssc, f_idx)
    vm = 1
    va_fr = _PM.var(pm, n, :va, f_bus)
    va_to = _PM.var(pm, n, :va, t_bus)

    JuMP.@constraint(pm.model, p_fr ==   -b * vm * (va_fr - va_to - alpha))
end


function constraint_ohms_y_to_sssc(pm::_PM.AbstractDCPModel, n::Int, i::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to)
    p_fr  = _PM.var(pm, n,  :psssc, f_idx)
    p_to  = _PM.var(pm, n,  :psssc, t_idx)

    JuMP.@constraint(pm.model, p_to == - p_fr)
end