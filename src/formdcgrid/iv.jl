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
            if !haskey(_PM.ref(pm, nw, :branchdc, l), "dcr") || _PM.ref(pm, nw, :branchdc, l)["dcr"] == 0
                JuMP.set_lower_bound(igrid_dc[arc], -_PM.ref(pm, nw, :branchdc, l)["rateA"] / vpu)
                JuMP.set_upper_bound(igrid_dc[arc],  _PM.ref(pm, nw, :branchdc, l)["rateA"] / vpu)
            else
                JuMP.set_lower_bound(igrid_dc[arc], -_PM.ref(pm, nw, :branchdc, l)["rateA"] / vpu * 10)
                JuMP.set_upper_bound(igrid_dc[arc],  _PM.ref(pm, nw, :branchdc, l)["rateA"] / vpu * 10)
            end
        end
    end
    report && _PM.sol_component_value_edge(pm, nw, :branchdc, :if, :it, _PM.ref(pm, nw, :arcs_dcgrid_from), _PM.ref(pm, nw, :arcs_dcgrid_to), igrid_dc)
end

"""
Creates DC branch temperature variables for IVR models.
"""
# function variable_dcbranch_temperature(pm::_PM.AbstractIVRModel; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
#     cond_temp_dc = _PM.var(pm, nw)[:cond_temp_dc] = JuMP.@variable(pm.model,
#     [l in _PM.ids(pm, nw, :branchdc)], base_name="$(nw)_cond_temp_dc",
#     start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "cond_temp_start", 0.0)
#     )
#     if bounded
#         for l in _PM.ids(pm, nw, :branchdc)
#             JuMP.set_lower_bound(cond_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["cond_temp_min"])
#             JuMP.set_upper_bound(cond_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["cond_temp_max"])
#         end
#     end

#     Δ_cond_temp_dc = _PM.var(pm, nw)[:delta_cond_temp_dc] = JuMP.@variable(pm.model,
#     [l in _PM.ids(pm, nw, :branchdc)], base_name="$(nw)_delta_cond_temp_dc",
#     start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "cond_temp_start", 0.0)
#     )
#     if bounded
#         for l in _PM.ids(pm, nw, :branchdc)
#             JuMP.set_lower_bound(Δ_cond_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["delta_cond_temp_min"])
#             JuMP.set_upper_bound(Δ_cond_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["delta_cond_temp_max"])
#         end
#     end

#     cable_surface_temp_dc = _PM.var(pm, nw)[:cable_surface_temp_dc] = JuMP.@variable(pm.model,
#     [l in _PM.ids(pm, nw, :branchdc)], base_name="$(nw)_cable_surface_temp_dc",
#     start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "cable_surface_temp_start", 0.0)
#     )
#     if bounded
#         for l in _PM.ids(pm, nw, :branchdc)
#             JuMP.set_lower_bound( cable_surface_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["surf_temp_min"])
#             JuMP.set_upper_bound( cable_surface_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["surf_temp_max"])
#         end
#     end


#     Δ_cable_surface_temp_dc = _PM.var(pm, nw)[:delta_cable_surface_temp_dc] = JuMP.@variable(pm.model,
#     [l in _PM.ids(pm, nw, :branchdc)], base_name="$(nw)_delta_cable_surface_temp_dc",
#     start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "cable_surface_temp_start", 0.0)
#     )
#     if bounded
#         for l in _PM.ids(pm, nw, :branchdc)
#             JuMP.set_lower_bound(Δ_cable_surface_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["delta_surf_temp_min"])
#             JuMP.set_upper_bound(Δ_cable_surface_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["delta_surf_temp_max"])
#         end
#     end

#     report && _PM.sol_component_value(pm, nw, :branchdc, :cable_cond_temp, _PM.ids(pm, nw, :branchdc), cond_temp_dc)
#     report && _PM.sol_component_value(pm, nw, :branchdc, :cable_surface_temp, _PM.ids(pm, nw, :branchdc), cable_surface_temp_dc)
# end


function variable_dcbranch_temperature(pm::_PM.AbstractIVRModel, ids; nw::Int=_PM.nw_id_default, bounded::Bool = true, report::Bool=true)
    cond_temp_dc = _PM.var(pm, nw)[:cond_temp_dc] = JuMP.@variable(pm.model,
    [l in ids], base_name="$(nw)_cond_temp_dc",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "cond_temp_start", 0.0)
    )
    if bounded
        for l in ids
            JuMP.set_lower_bound(cond_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["cond_temp_min"])
            JuMP.set_upper_bound(cond_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["cond_temp_max"])
        end
    end

    Δ_cond_temp_dc = _PM.var(pm, nw)[:delta_cond_temp_dc] = JuMP.@variable(pm.model,
    [l in ids], base_name="$(nw)_delta_cond_temp_dc",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "cond_temp_start", 0.0)
    )
    if bounded
        for l in ids
            JuMP.set_lower_bound(Δ_cond_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["delta_cond_temp_min"])
            JuMP.set_upper_bound(Δ_cond_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["delta_cond_temp_max"])
        end
    end

    cable_surface_temp_dc = _PM.var(pm, nw)[:cable_surface_temp_dc] = JuMP.@variable(pm.model,
    [l in ids], base_name="$(nw)_cable_surface_temp_dc",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "cable_surface_temp_start", 0.0)
    )
    if bounded
        for l in ids
            JuMP.set_lower_bound( cable_surface_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["surf_temp_min"])
            JuMP.set_upper_bound( cable_surface_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["surf_temp_max"])
        end
    end


    Δ_cable_surface_temp_dc = _PM.var(pm, nw)[:delta_cable_surface_temp_dc] = JuMP.@variable(pm.model,
    [l in ids], base_name="$(nw)_delta_cable_surface_temp_dc",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "cable_surface_temp_start", 0.0)
    )
    if bounded
        for l in ids
            JuMP.set_lower_bound(Δ_cable_surface_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["delta_surf_temp_min"])
            JuMP.set_upper_bound(Δ_cable_surface_temp_dc[l], _PM.ref(pm, nw, :branchdc, l)["delta_surf_temp_max"])
        end
    end

    report && _PM.sol_component_value(pm, nw, :branchdc, :cable_cond_temp, ids, cond_temp_dc)
    report && _PM.sol_component_value(pm, nw, :branchdc, :cable_surface_temp, ids, cable_surface_temp_dc)
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
