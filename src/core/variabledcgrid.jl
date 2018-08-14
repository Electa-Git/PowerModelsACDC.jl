
function variable_dcbranch_current(pm::GenericPowerModel; kwargs...)
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:vdcm] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], basename="$(nw)_$(cnd)_vdcm",
        lowerbound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmin", cnd),
        upperbound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmax", cnd)
        )
    else
        PowerModels.var(pm, nw, cnd)[:vdcm] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], basename="$(nw)_$(cnd)_vdcm",
        start = PowerModels.getval(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)
        )
    end
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude_sqr(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:wdc] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], basename="$(nw)_$(cnd)_wdc",
        lowerbound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmin", cnd)^2,
        upperbound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmax", cnd)^2,
        start = PowerModels.getval(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)^2
        )
        PowerModels.var(pm, nw, cnd)[:wdcr] = @variable(pm.model,
        [(i,j) in PowerModels.ids(pm, nw, :buspairsdc)], basename="$(nw)_$(cnd)_wdcr",
        lowerbound = 0,
        upperbound = PowerModels.ref(pm, nw, :buspairsdc, (i,j), "vm_fr_max", cnd) * PowerModels.ref(pm, nw, :buspairsdc, (i,j), "vm_to_max", cnd),
        start = PowerModels.getval(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)^2
        )
    else
        PowerModels.var(pm, nw, cnd)[:wdc] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], basename="$(nw)_$(cnd)_wdc",
        start = PowerModels.getval(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)^2,
        lowerbound = 0
        )
        PowerModels.var(pm, nw, cnd)[:wdcr] = @variable(pm.model,
        [(i,j) in PowerModels.ids(pm, nw, :buspairsdc)], basename="$(nw)_$(cnd)_wdcr",
        start = PowerModels.getval(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)^2,
        lowerbound = 0
        )
    end
end

"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_active_dcbranch_flow(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:p_dcgrid] = @variable(pm.model,
        [(l,i,j) in PowerModels.ref(pm, nw, :arcs_dcgrid)], basename="$(nw)_$(cnd)_pdcgrid",
        lowerbound = -PowerModels.ref(pm, nw, :branchdc, l, "rateA", cnd),
        upperbound =  PowerModels.ref(pm, nw, :branchdc, l, "rateA", cnd)
        )
    else
        PowerModels.var(pm, nw, cnd)[:p_dcgrid] = @variable(pm.model,
        [(l,i,j) in PowerModels.ref(pm, nw, :arcs_dcgrid)], basename="$(nw)_$(cnd)_pdcgrid",
        start = PowerModels.getval(ref(pm, nw, :branchdc, l), "p_start", cnd, 1.0)
        )
    end
end

"variable: `ccm_dcgrid[l]` for `(l)` in `branchdc`"
function variable_dcbranch_current_sqr(pm::GenericPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    vpu = 0.8;
    if bounded
        PowerModels.var(pm, nw, cnd)[:ccm_dcgrid] = @variable(pm.model,
        [l in PowerModels.ids(pm, nw, :branchdc)], basename="$(nw)_$(cnd)_ccm_dcgrid",
        lowerbound = 0,
        upperbound = (PowerModels.ref(pm, nw, :branchdc, l, "rateA", cnd) / vpu)^2
        )
    else
        PowerModels.var(pm, nw, cnd)[:ccm_dcgrid] = @variable(pm.model,
        [l in PowerModels.ids(pm, nw, :branchdc)], basename="$(nw)_$(cnd)_ccm_dcgrid",
        start = (PowerModels.getval(ref(pm, nw, :branchdc, l), "p_start", cnd, 0.0) / vpu)^2,
        lowerbound = 0
        )
    end
end
