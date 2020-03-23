
function variable_dcbranch_current(pm::AbstractPowerModel; kwargs...)
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vdcm = PowerModels.var(pm, nw)[:vdcm] = JuMP.JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :busdc)], base_name="$(nw)_vdcm",
    start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", 1.0)
    )

    if bounded
        for (i, busdc) in ref(pm, nw, :busdc)
            JuMP.set_lower_bound(vdcm[i],  busdc["Vdcmin"])
            JuMP.set_upper_bound(vdcm[i],  busdc["Vdcmax"])
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :busdc, :vm, ids(pm, nw, :busdc), vdcm)
end

function variable_dcgrid_voltage_magnitude(pm::AbstractLPACModel; nw::Int=pm.cnw, bounded = true, report::Bool=true)
    phivdcm = PowerModels.var(pm, nw)[:phi_vdcm] = JuMP.JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :busdc)], base_name="$(nw)_phi_vdcm",
    start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc")
    )

    if bounded
        for (i, busdc) in ref(pm, nw, :busdc)
            JuMP.set_lower_bound(phivdcm[i],  busdc["Vdcmin"] - 1)
            JuMP.set_upper_bound(phivdcm[i],  busdc["Vdcmax"] - 1)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :busdc, :phivdcm, ids(pm, nw, :busdc), phivdcm)

end
"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude_sqr(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    wdc = PowerModels.var(pm, nw)[:wdc] = JuMP.@variable(pm.model,
    [i in PowerModels.ids(pm, nw, :busdc)], base_name="$(nw)_wdc",
    start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", 1.0)^2
    )
    wdcr = PowerModels.var(pm, nw)[:wdcr] = JuMP.@variable(pm.model,
    [(i,j) in PowerModels.ids(pm, nw, :buspairsdc)], base_name="$(nw)_wdcr",
    start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", 1.0)^2
    )

    if bounded
        for (i, busdc) in ref(pm, nw, :busdc)
            JuMP.set_lower_bound(wdc[i],  busdc["Vdcmin"]^2)
            JuMP.set_upper_bound(wdc[i],  busdc["Vdcmax"]^2)
        end
        for (bp, buspairdc) in ref(pm, nw, :buspairsdc)
            JuMP.set_lower_bound(wdcr[bp],  0)
            JuMP.set_upper_bound(wdcr[bp],  buspairdc["vm_fr_max"] * buspairdc["vm_to_max"])
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :busdc, :wdc, ids(pm, nw, :busdc), wdc)
end

"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_active_dcbranch_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    p = PowerModels.var(pm, nw)[:p_dcgrid] = JuMP.@variable(pm.model,
    [(l,i,j) in PowerModels.ref(pm, nw, :arcs_dcgrid)], base_name="$(nw)_pdcgrid",
    start = PowerModels.comp_start_value(ref(pm, nw, :branchdc, l), "p_start", 1.0)
    )

    if bounded
        for arc in ref(pm, nw, :arcs_dcgrid)
            l,i,j = arc
            JuMP.set_lower_bound(p[arc], -ref(pm, nw, :branchdc, l)["rateA"])
            JuMP.set_upper_bound(p[arc],  ref(pm, nw, :branchdc, l)["rateA"])
        end
    end

    report && PowerModels.sol_component_value_edge(pm, nw, :branchdc, :pf, :pt, ref(pm, nw, :arcs_dcgrid_from), ref(pm, nw, :arcs_dcgrid_to), p)
end


"variable: `ccm_dcgrid[l]` for `(l)` in `branchdc`"
function variable_dcbranch_current_sqr(pm::AbstractPowerModel; nw::Int=pm.cnw, bounded::Bool = true, report::Bool=true)
    vpu = 0.8;
    cc = PowerModels.var(pm, nw)[:ccm_dcgrid] = JuMP.@variable(pm.model,
    [l in PowerModels.ids(pm, nw, :branchdc)], base_name="$(nw)_ccm_dcgrid",
    start = (PowerModels.comp_start_value(ref(pm, nw, :branchdc, l), "p_start", 0.0) / vpu)^2
    )
    if bounded
        for (l, branchdc) in ref(pm, nw, :branchdc)
            JuMP.set_lower_bound(cc[l], 0)
            JuMP.set_upper_bound(cc[l], (branchdc["rateA"] / vpu)^2)
        end
    end

    report && PowerModels.sol_component_value(pm, nw, :branchdc, :ccm, ids(pm, nw, :branchdc), cc)
end
