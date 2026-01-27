# Explicit DC branch current variable
"""
Creates DC branch current variables for IVR models.
"""
function variable_dcbranch_current(pm::_PM.AbstractIVRModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    vpu = 1;
    igrid_dc = _PM.var(pm, nw)[:igrid_dc] = JuMP.@variable(pm.model,
    [(l,i,j) in _PM.ref(pm, nw, :arcs_dcgrid)], base_name="$(nw)_igrid_dc",
    start = (_PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", 0.0) / vpu)
    )
    if bounded
        for arc in _PM.ref(pm, nw, :arcs_dcgrid)
            l,i,j = arc
            JuMP.set_lower_bound(igrid_dc[arc], -_PM.ref(pm, nw, :branchdc, l)["rateA"] / vpu)
            JuMP.set_upper_bound(igrid_dc[arc],  _PM.ref(pm, nw, :branchdc, l)["rateA"] / vpu)
        end
    end
    report && _IM.sol_component_value_edge(pm, _PM.pm_it_sym, nw, :branchdc, :if, :it, _PM.ref(pm, nw, :arcs_dcgrid_from), _PM.ref(pm, nw, :arcs_dcgrid_to), igrid_dc)
end

# Kirchhoff's current law for DC nodes
"""
Kirchhoff's current law constraint for DC buses in IVR models.
"""
function constraint_current_balance_dc(pm::_PM.AbstractIVRModel, n::Int, bus_arcs_dcgrid, bus_convs_dc, pd)
    igrid_dc = _PM.var(pm, n, :igrid_dc)
    iconv_dc = _PM.var(pm, n, :iconv_dc)

    JuMP.@constraint(pm.model, sum(igrid_dc[a] for a in bus_arcs_dcgrid) + sum(iconv_dc[c] for c in bus_convs_dc) == 0) # deal with pd
end

# Ohm's law for DC branches
"""
Ohm's law constraints for DC branches in IVR models, relating voltages, currents, and powers.
"""
function constraint_ohms_dc_branch(pm::_PM.AbstractIVRModel, n::Int,  f_bus, t_bus, f_idx, t_idx, r, p)
    i_dc_fr = _PM.var(pm, n,  :igrid_dc, f_idx)
    i_dc_to = _PM.var(pm, n,  :igrid_dc, t_idx)
    vmdc_fr = _PM.var(pm, n,  :vdcm, f_bus)
    vmdc_to = _PM.var(pm, n,  :vdcm, t_bus)
    p_fr  = _PM.var(pm, n,  :p_dcgrid, f_idx)
    p_to  = _PM.var(pm, n,  :p_dcgrid, t_idx)

    if r == 0
        JuMP.@constraint(pm.model, i_dc_fr + i_dc_to == 0)
    else
        JuMP.@constraint(pm.model, vmdc_to ==  vmdc_fr - 1/p * r * i_dc_fr)
        JuMP.@constraint(pm.model, vmdc_fr ==  vmdc_to - 1/p * r * i_dc_to)
    end

    JuMP.@constraint(pm.model, p_fr ==  vmdc_fr * i_dc_fr)
    JuMP.@constraint(pm.model, p_to ==  vmdc_to * i_dc_to)
end