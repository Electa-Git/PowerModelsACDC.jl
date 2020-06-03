
function variable_dcbranch_current(pm::_PM.AbstractPowerModel; kwargs...)
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vdcm = _PM.var(pm, nw)[:vdcm] = JuMP.JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :busdc)], base_name="$(nw)_vdcm",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", 1.0)
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(vdcm[i],  busdc["Vdcmin"])
            JuMP.set_upper_bound(vdcm[i],  busdc["Vdcmax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc, :vm, _PM.ids(pm, nw, :busdc), vdcm)
end

function variable_dcgrid_voltage_magnitude(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded = true, report::Bool=true)
    phivdcm = _PM.var(pm, nw)[:phi_vdcm] = JuMP.JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :busdc)], base_name="$(nw)_phi_vdcm",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc")
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(phivdcm[i],  busdc["Vdcmin"] - 1)
            JuMP.set_upper_bound(phivdcm[i],  busdc["Vdcmax"] - 1)
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc, :phivdcm, _PM.ids(pm, nw, :busdc), phivdcm)

end
"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude_sqr(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    wdc = _PM.var(pm, nw)[:wdc] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :busdc)], base_name="$(nw)_wdc",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", 1.0)^2
    )
    wdcr = _PM.var(pm, nw)[:wdcr] = JuMP.@variable(pm.model,
    [(i,j) in _PM.ids(pm, nw, :buspairsdc)], base_name="$(nw)_wdcr",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc, i), "Vdc", 1.0)^2
    )

    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc)
            JuMP.set_lower_bound(wdc[i],  busdc["Vdcmin"]^2)
            JuMP.set_upper_bound(wdc[i],  busdc["Vdcmax"]^2)
        end
        for (bp, buspairdc) in _PM.ref(pm, nw, :buspairsdc)
            JuMP.set_lower_bound(wdcr[bp],  0)
            JuMP.set_upper_bound(wdcr[bp],  buspairdc["vm_fr_max"] * buspairdc["vm_to_max"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc, :wdc, _PM.ids(pm, nw, :busdc), wdc)
end

"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_active_dcbranch_flow(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    p = _PM.var(pm, nw)[:p_dcgrid] = JuMP.@variable(pm.model,
    [(l,i,j) in _PM.ref(pm, nw, :arcs_dcgrid)], base_name="$(nw)_pdcgrid",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", 1.0)
    )

    if bounded
        for arc in _PM.ref(pm, nw, :arcs_dcgrid)
            l,i,j = arc
            JuMP.set_lower_bound(p[arc], -_PM.ref(pm, nw, :branchdc, l)["rateA"])
            JuMP.set_upper_bound(p[arc],  _PM.ref(pm, nw, :branchdc, l)["rateA"])
        end
    end

    report && _IM.sol_component_value_edge(pm, nw, :branchdc, :pf, :pt, _PM.ref(pm, nw, :arcs_dcgrid_from), _PM.ref(pm, nw, :arcs_dcgrid_to), p)
end


"variable: `ccm_dcgrid[l]` for `(l)` in `branchdc`"
function variable_dcbranch_current_sqr(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vpu = 0.8;
    cc = _PM.var(pm, nw)[:ccm_dcgrid] = JuMP.@variable(pm.model,
    [l in _PM.ids(pm, nw, :branchdc)], base_name="$(nw)_ccm_dcgrid",
    start = (_PM.comp_start_value(_PM.ref(pm, nw, :branchdc, l), "p_start", 0.0) / vpu)^2
    )
    if bounded
        for (l, branchdc) in _PM.ref(pm, nw, :branchdc)
            JuMP.set_lower_bound(cc[l], 0)
            JuMP.set_upper_bound(cc[l], (branchdc["rateA"] / vpu)^2)
        end
    end

    report && _IM.sol_component_value(pm, nw, :branchdc, :ccm, _PM.ids(pm, nw, :branchdc), cc)
end


####################### TNEP variables ################################

function variable_dcbranch_current_ne(pm::_PM.AbstractPowerModel; kwargs...)
end

"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vdcm_ne = _PM.var(pm, nw)[:vdcm_ne] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :busdc_ne)], base_name="$(nw)_vdcm_ne",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc_ne, i), "Vdc",  1.0)
    )
    if bounded
        for (i, busdc) in _PM.ref(pm, nw, :busdc_ne)
            JuMP.set_lower_bound(vdcm_ne[i],  busdc["Vdcmin"])
            JuMP.set_upper_bound(vdcm_ne[i],  busdc["Vdcmax"])
        end
    end

    report && _IM.sol_component_value(pm, nw, :busdc_ne, :vm, _PM.ids(pm, nw, :busdc_ne), vdcm_ne)
end

function variable_dcgrid_voltage_magnitude_ne(pm::_PM.AbstractLPACModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
        phivdcm_ne = _PM.var(pm, nw)[:phi_vdcm_ne] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :busdc_ne)], base_name="$(nw)_phi_vdcm_ne",
        lower_bound = _PM.ref(pm, nw, :busdc_ne, i, "Vdcmin") - 1,
        upper_bound = _PM.ref(pm, nw, :busdc_ne, i, "Vdcmax") - 1,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc_ne, i), "Vdc")
        )
        if bounded
            for (i, busdc) in _PM.ref(pm, nw, :busdc_ne)
                JuMP.set_lower_bound(phivdcm_ne[i],  busdc["Vdcmin"] - 1)
                JuMP.set_upper_bound(phivdcm_ne[i],  busdc["Vdcmax"] -1 )
            end
        end
        report && _IM.sol_component_value(pm, nw, :busdc_ne, :phivdcm_ne, _PM.ids(pm, nw, :busdc_ne), phivdcm_ne)

#TODO
# think about creating an arc/dict with branchdc_ne pointing to both existing and new buses. Then update limits with corresponding buses.
        phivdcm_fr_ne = _PM.var(pm, nw)[:phi_vdcm_fr] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_phi_vdcm_fr",
        start = 0
        )
        if bounded
            for (i, branchdc) in _PM.ref(pm, nw, :branchdc_ne)
                JuMP.set_lower_bound(phivdcm_fr_ne[i],  -0.2)
                JuMP.set_upper_bound(phivdcm_fr_ne[i],  0.2 )
            end
        end
        report && _IM.sol_component_value(pm, nw, :branchdc_ne, :phivdcm_fr, _PM.ids(pm, nw, :branchdc_ne), phivdcm_fr_ne)


        phivdcm_to_ne = _PM.var(pm, nw)[:phi_vdcm_to] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_phi_vdcm_to",
        start = 0
        )

        if bounded
            for (i, branchdc) in _PM.ref(pm, nw, :branchdc_ne)
                JuMP.set_lower_bound(phivdcm_to_ne[i],  -0.2)
                JuMP.set_upper_bound(phivdcm_to_ne[i],  0.2 )
            end
        end
        report && _IM.sol_component_value(pm, nw, :branchdc_ne, :phivdcm_to, _PM.ids(pm, nw, :branchdc_ne), phivdcm_to_ne)
end

"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude_sqr_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    bi_bp = Dict([(i, (b["fbusdc"], b["tbusdc"])) for (i,b) in _PM.ref(pm, nw, :branchdc_ne)])
    bus_vdcmax = merge(Dict([(b,bus["Vdcmax"]) for (b,bus) in _PM.ref(pm, nw, :busdc)]),
    Dict([(b,bus["Vdcmax"]) for (b,bus) in _PM.ref(pm, nw, :busdc_ne)]))
    bus_vdcmin = merge(Dict([(b,bus["Vdcmin"]) for (b,bus) in _PM.ref(pm, nw, :busdc)]),
    Dict([(b,bus["Vdcmin"]) for (b,bus) in _PM.ref(pm, nw, :busdc_ne)]))
         # display(_PM.ids(pm, nw, :buspairsdc_ne))
        wdc_ne = _PM.var(pm, nw)[:wdc_ne] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :busdc_ne)], base_name="$(nw)_wdc_ne",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc_ne, i), "Vdc",  1.0)^2,
        )
        wdcr_ne = _PM.var(pm, nw)[:wdcr_ne] = JuMP.@variable(pm.model,
        [l in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_wdcr_ne",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc_ne, bi_bp[l][1]), "Vdc",  1.0)^2,
        )
        if bounded
            for (i, busdc) in _PM.ref(pm, nw, :busdc_ne)
                JuMP.set_lower_bound(wdc_ne[i],  busdc["Vdcmin"]^2)
                JuMP.set_upper_bound(wdc_ne[i],  busdc["Vdcmax"]^2)
            end
            for (br, branchdc) in _PM.ref(pm, nw, :branchdc_ne)
                JuMP.set_lower_bound(wdcr_ne[br],  0)
                JuMP.set_upper_bound(wdcr_ne[br],  bus_vdcmax[bi_bp[br][1]] * bus_vdcmax[bi_bp[br][2]])
            end
        end
        report && _IM.sol_component_value(pm, nw, :busdc_ne, :wdc_ne, _PM.ids(pm, nw, :busdc_ne), wdc_ne)
        report && _IM.sol_component_value(pm, nw, :busdc_ne, :wdcr_ne, _PM.ids(pm, nw, :busdc_ne), wdcr_ne)
end

function variable_dcgrid_voltage_magnitude_sqr_du(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true) # this has to to every branch, different than its counterpart(Wdc_fr) since two candidate branches can be connected to same node and two duplicate variables will be needed
    bi_bp = Dict([(i, (b["fbusdc"], b["tbusdc"])) for (i,b) in _PM.ref(pm, nw, :branchdc_ne)])
    wdc_fr_ne = _PM.var(pm, nw)[:wdc_du_fr] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_wdc_du_fr",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc_ne, bi_bp[i][1]), "Vdc",  1.0)^2,
    )
    wdc_to_ne = _PM.var(pm, nw)[:wdc_du_to] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_wdc_du_to",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc_ne, bi_bp[i][1]), "Vdc",  1.0)^2,
    )
    #TODO replace wdc_du_fr and wdc_du_to with wdc_fr and wdc_to make make it consistent with PM, there multiplication is defined by wr - real and wi- imag
    wdcr_frto_ne = _PM.var(pm, nw)[:wdcr_du] = JuMP.@variable(pm.model,
    [i in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_wdcr_du",
    start = _PM.comp_start_value(_PM.ref(pm, nw, :busdc_ne, bi_bp[i][1]), "Vdc",  1.0)^2,
    )

    if bounded
        for (i, branchdc) in _PM.ref(pm, nw, :branchdc_ne)
            JuMP.set_lower_bound(wdc_fr_ne[i],  0)
            JuMP.set_upper_bound(wdc_fr_ne[i],  1.21)
            JuMP.set_lower_bound(wdc_to_ne[i],  0)
            JuMP.set_upper_bound(wdc_to_ne[i],  1.21)
            JuMP.set_lower_bound(wdcr_frto_ne[i],  0)
            JuMP.set_upper_bound(wdcr_frto_ne[i],  1.21)
        end
    end
    report && _IM.sol_component_value(pm, nw, :busdc_ne, :wdc_du_fr, _PM.ids(pm, nw, :busdc_ne), wdc_fr_ne)
    report && _IM.sol_component_value(pm, nw, :busdc_ne, :wdc_du_to, _PM.ids(pm, nw, :busdc_ne), wdc_to_ne)
    report && _IM.sol_component_value(pm, nw, :busdc_ne, :wdcr_du, _PM.ids(pm, nw, :busdc_ne), wdcr_frto_ne)
end

"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_active_dcbranch_flow_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
        p = _PM.var(pm, nw)[:p_dcgrid_ne]= JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs_dcgrid_ne)], base_name="$(nw)_pdcgrid_ne",
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc_ne, l), "p_start",  1.0)
        )

    if bounded
        for arc in _PM.ref(pm, nw, :arcs_dcgrid_ne)
            l,i,j = arc
            JuMP.set_lower_bound(p[arc], -_PM.ref(pm, nw, :branchdc_ne, l)["rateA"])
            JuMP.set_upper_bound(p[arc],  _PM.ref(pm, nw, :branchdc_ne, l)["rateA"])
        end
    end

    report && _IM.sol_component_value_edge(pm, nw, :branchdc_ne, :pf, :pt, _PM.ref(pm, nw, :arcs_dcgrid_from_ne), _PM.ref(pm, nw, :arcs_dcgrid_to_ne), p)
end

"variable: `ccm_dcgrid[l]` for `(l)` in `branchdc`"
function variable_dcbranch_current_sqr_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vpu = 0.8
    cc= _PM.var(pm, nw)[:ccm_dcgrid_ne] = JuMP.@variable(pm.model,
    [l in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_ccm_dcgrid_ne",
    start = (_PM.comp_start_value(_PM.ref(pm, nw, :branchdc_ne, l), "p_start",  0.0) / vpu)^2
    )

    if bounded
        for (l, branchdc) in _PM.ref(pm, nw, :branchdc_ne)
            JuMP.set_lower_bound(cc[l], 0)
            JuMP.set_upper_bound(cc[l], (branchdc["rateA"] / vpu)^2)
        end
    end

    report && _IM.sol_component_value(pm, nw, :branchdc_ne, :ccm, _PM.ids(pm, nw, :branchdc), cc)
end

"variable: `0 <= convdc_ne[c] <= 1` for `c` in `candidate converters"
function variable_branch_ne(pm::_PM.AbstractPowerModel; nw::Int=pm.cnw, relax::Bool=false, report::Bool=true)
    if !relax
        Z_dc_branch_ne = _PM.var(pm, nw)[:branch_ne] = JuMP.@variable(pm.model, #branch_ne is also name in PowerModels, branchdc_ne is candidate branches
        [l in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_branch_ne",
        binary = true,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc_ne, l), "convdc_tnep_start",  0.0)
        )
    else
        Z_dc_branch_ne = _PM.var(pm, nw)[:branch_ne] = JuMP.@variable(pm.model, #branch_ne is also name in PowerModels, branchdc_ne is candidate branches
        [l in _PM.ids(pm, nw, :branchdc_ne)], base_name="$(nw)_branch_ne",
        lower_bound = 0,
        upper_bound = 1,
        start = _PM.comp_start_value(_PM.ref(pm, nw, :branchdc_ne, l), "convdc_tnep_start",  0.0)
        )
    end
    report && _IM.sol_component_value(pm, nw, :branchdc_ne, :isbuilt, _PM.ids(pm, nw, :branchdc_ne), Z_dc_branch_ne)
end
