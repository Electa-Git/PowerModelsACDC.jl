"""
    constraint_power_balance(pm::AbstractACNFAIVRModel, i::Int; nw::Int=_PM.nw_id_default)

Adds the active-power balance for AC bus `i` in the hybrid AC-NFA/DC-IVR formulation.
"""
function constraint_power_balance(pm::AbstractACNFAIVRModel, i::Int; nw::Int=_PM.nw_id_default)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_convs_ac = _PM.ref(pm, nw, :bus_convs_ac, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    pd = Dict(d => _PM.ref(pm, nw, :load, d, "pd") for d in bus_loads)
    gs = Dict(s => _PM.ref(pm, nw, :shunt, s, "gs") for s in bus_shunts)

    return constraint_power_balance(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, gs)
end

"""
    constraint_power_balance(pm::AbstractACNFAIVRModel, nw::Int, i::Int, ...)

Active-power balance for the NFA AC network, including AC/DC converter power.
"""
function constraint_power_balance(pm::AbstractACNFAIVRModel, nw::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, gs)
    p = get(_PM.var(pm, nw), :p, Dict{Any,Any}())
    p_dc = get(_PM.var(pm, nw), :p_dc, Dict{Any,Any}())
    pg = get(_PM.var(pm, nw), :pg, Dict{Any,Any}())
    pconv_grid_ac = get(_PM.var(pm, nw), :pconv_tf_fr, Dict{Any,Any}())

    _PM._check_var_keys(p, bus_arcs, "active power", "AC branch")
    _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    _PM._check_var_keys(pconv_grid_ac, bus_convs_ac, "active power", "AC/DC converter")

    cstr_p = JuMP.@constraint(pm.model,
        sum(p[a] for a in bus_arcs; init=0.0) +
        sum(p_dc[a] for a in bus_arcs_dc; init=0.0) +
        sum(pconv_grid_ac[c] for c in bus_convs_ac; init=0.0) ==
        sum(pg[g] for g in bus_gens; init=0.0) -
        sum(pd[d] for d in bus_loads; init=0.0) -
        sum(gs[s] for s in bus_shunts; init=0.0)
    )

    _PM.sol(pm, nw, :bus, i)[:lam_kcl_r] = cstr_p
    return cstr_p
end

"""
    constraint_converter(pm::AbstractACNFAIVRModel, i::Int; nw::Int=_PM.nw_id_default)

Adds the converter constraints for the hybrid AC-NFA/DC-IVR formulation.
"""
function constraint_converter(pm::AbstractACNFAIVRModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    busdc = conv["busdc_i"]
    loss_a = get(conv, "LossA", 0.0)
    loss_b = get(conv, "LossB", 0.0)
    loss_c = get(conv, "LossCrec", get(conv, "LossCinv", 0.0))

    return constraint_converter(pm, nw, i, busdc, loss_a, loss_b, loss_c)
end

"""
    constraint_converter(pm::AbstractACNFAIVRModel, nw::Int, i::Int, busdc::Int, loss_a, loss_b, loss_c)

Couples the NFA AC-side converter power to the IVR DC-side voltage and current.
"""
function constraint_converter(pm::AbstractACNFAIVRModel, nw::Int, i::Int, busdc::Int, loss_a, loss_b, loss_c)
    pconv_grid_ac = _PM.var(pm, nw, :pconv_tf_fr, i)
    pconv_ac = _PM.var(pm, nw, :pconv_ac, i)
    pconv_dc = _PM.var(pm, nw, :pconv_dc, i)
    iconv_dc = _PM.var(pm, nw, :iconv_dc, i)
    vdc = _PM.var(pm, nw, :vdcm, busdc)

    JuMP.@constraint(pm.model, pconv_grid_ac == pconv_ac)
    JuMP.@constraint(pm.model, pconv_dc == vdc*iconv_dc)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc == loss_a)

    return nothing
end

