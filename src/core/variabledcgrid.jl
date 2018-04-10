
function variable_dcbranch_current(pm::GenericPowerModel, n::Int=pm.cnw; kwargs...)
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:vdcm] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:busdc])], basename="$(n)_vdcm",
        lowerbound = pm.ref[:nw][n][:busdc][i]["Vdcmin"],
        upperbound = pm.ref[:nw][n][:busdc][i]["Vdcmax"],
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)
        )
    else
        pm.var[:nw][n][:vdcm] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:busdc])], basename="$(n)_vdcm",
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)
        )
    end
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude_sqr(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:wdc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:busdc])], basename="$(n)_wdc",
        lowerbound = pm.ref[:nw][n][:busdc][i]["Vdcmin"]^2,
        upperbound = pm.ref[:nw][n][:busdc][i]["Vdcmax"]^2,
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)^2
        )
        pm.var[:nw][n][:wdcr] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:buspairsdc])], basename="$(n)_wdcr",
        lowerbound = 0,
        upperbound = pm.ref[:nw][n][:buspairsdc][i]["vm_fr_max"]*pm.ref[:nw][n][:buspairsdc][i]["vm_to_max"],
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)^2
        )
    else
        pm.var[:nw][n][:wdc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:busdc])], basename="$(n)_wdc",
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)^2
        )
        pm.var[:nw][n][:wdcr] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:buspairsdc])], basename="$(n)_wdcr",
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)^2
        )

    end
end

"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_active_dcbranch_flow(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:p_dcgrid] = @variable(pm.model,
        [(l,i,j) in pm.ref[:nw][n][:arcs_dcgrid]], basename="$(n)_pdcgrid",
        lowerbound = -pm.ref[:nw][n][:branchdc][l]["rateA"],
        upperbound =  pm.ref[:nw][n][:branchdc][l]["rateA"]
        )
    else
        pm.var[:nw][n][:p_dcgrid] = @variable(pm.model,
        [(l,i,j) in pm.ref[:nw][n][:arcs_dcgrid]], basename="$(n)_pdcgrid",
        start = PowerModels.getstart(pm.ref[:nw][n][:branchdc], l, "p_start", 0.0)
        )
    end
end

"variable: `ccm_dcgrid[l]` for `(l)` in `branchdc`"
function variable_dcbranch_current_sqr(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    vpu = 0.8
    if bounded
        pm.var[:nw][n][:ccm_dcgrid] = @variable(pm.model,
        [l in keys(pm.ref[:nw][n][:branchdc])], basename="$(n)_ccm_dcgrid",
        lowerbound = 0,
        upperbound = (pm.ref[:nw][n][:branchdc][l]["rateA"]/vpu)^2
        )
    else
        pm.var[:nw][n][:ccm_dcgrid] = @variable(pm.model,
        [l in pm.ref[:nw][n][:branchdc]], basename="$(n)_ccm_dcgrid",
        start = PowerModels.getstart(pm.ref[:nw][n][:branchdc], l, "p_start", 0.0)/vpu
        )
    end
end
