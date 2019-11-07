
function variable_dcbranch_current(pm::AbstractPowerModel; kwargs...)
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:vdcm] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], base_name="$(nw)_$(cnd)_vdcm",
        lower_bound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmin", cnd),
        upper_bound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmax", cnd),
        start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:vdcm] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], base_name="$(nw)_$(cnd)_vdcm",
        start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)
        )
    end
end

function variable_dcgrid_voltage_magnitude(pm::AbstractLPACModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded = true)
        PowerModels.var(pm, nw, cnd)[:phi_vdcm] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], base_name="$(nw)_$(cnd)_phi_vdcm",
        lower_bound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmin", cnd) - 1, #+/- 10% tolerance to voltages
        upper_bound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmax", cnd) - 1,
        start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", cnd)
        )
end

"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude_sqr(pm::AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:wdc] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], base_name="$(nw)_$(cnd)_wdc",
        lower_bound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmin", cnd)^2,
        upper_bound = PowerModels.ref(pm, nw, :busdc, i, "Vdcmax", cnd)^2,
        start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)^2
        )
        PowerModels.var(pm, nw, cnd)[:wdcr] = @variable(pm.model,
        [(i,j) in PowerModels.ids(pm, nw, :buspairsdc)], base_name="$(nw)_$(cnd)_wdcr",
        lower_bound = 0,
        upper_bound = PowerModels.ref(pm, nw, :buspairsdc, (i,j), "vm_fr_max", cnd) * PowerModels.ref(pm, nw, :buspairsdc, (i,j), "vm_to_max", cnd),
        start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)^2
        )
    else
        PowerModels.var(pm, nw, cnd)[:wdc] = @variable(pm.model,
        [i in PowerModels.ids(pm, nw, :busdc)], base_name="$(nw)_$(cnd)_wdc",
        start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)^2,
        lower_bound = 0
        )
        PowerModels.var(pm, nw, cnd)[:wdcr] = @variable(pm.model,
        [(i,j) in PowerModels.ids(pm, nw, :buspairsdc)], base_name="$(nw)_$(cnd)_wdcr",
        start = PowerModels.comp_start_value(ref(pm, nw, :busdc, i), "Vdc", cnd, 1.0)^2,
        lower_bound = 0
        )
    end
end

"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_active_dcbranch_flow(pm::AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    if bounded
        PowerModels.var(pm, nw, cnd)[:p_dcgrid] = @variable(pm.model,
        [(l,i,j) in PowerModels.ref(pm, nw, :arcs_dcgrid)], base_name="$(nw)_$(cnd)_pdcgrid",
        lower_bound = -PowerModels.ref(pm, nw, :branchdc, l, "rateA", cnd),
        upper_bound =  PowerModels.ref(pm, nw, :branchdc, l, "rateA", cnd),
        start = PowerModels.comp_start_value(ref(pm, nw, :branchdc, l), "p_start", cnd, 1.0)
        )
    else
        PowerModels.var(pm, nw, cnd)[:p_dcgrid] = @variable(pm.model,
        [(l,i,j) in PowerModels.ref(pm, nw, :arcs_dcgrid)], base_name="$(nw)_$(cnd)_pdcgrid",
        start = PowerModels.comp_start_value(ref(pm, nw, :branchdc, l), "p_start", cnd, 1.0)
        )
    end
end

"variable: `ccm_dcgrid[l]` for `(l)` in `branchdc`"
function variable_dcbranch_current_sqr(pm::AbstractPowerModel; nw::Int=pm.cnw, cnd::Int=pm.ccnd, bounded::Bool = true)
    vpu = 0.8;
    if bounded
        PowerModels.var(pm, nw, cnd)[:ccm_dcgrid] = @variable(pm.model,
        [l in PowerModels.ids(pm, nw, :branchdc)], base_name="$(nw)_$(cnd)_ccm_dcgrid",
        lower_bound = 0,
        upper_bound = (PowerModels.ref(pm, nw, :branchdc, l, "rateA", cnd) / vpu)^2,
        start = (PowerModels.comp_start_value(ref(pm, nw, :branchdc, l), "p_start", cnd, 0.0) / vpu)^2
        )
    else
        PowerModels.var(pm, nw, cnd)[:ccm_dcgrid] = @variable(pm.model,
        [l in PowerModels.ids(pm, nw, :branchdc)], base_name="$(nw)_$(cnd)_ccm_dcgrid",
        start = (PowerModels.comp_start_value(ref(pm, nw, :branchdc, l), "p_start", cnd, 0.0) / vpu)^2,
        lower_bound = 0
        )
    end
end
