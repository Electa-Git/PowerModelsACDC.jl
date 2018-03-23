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

function variable_dc_converter(pm::GenericPowerModel, n::Int=pm.cnw; kwargs...)
    variable_converter_active_power(pm, n; kwargs...)
    variable_converter_reactive_power(pm, n; kwargs...)
    variable_dcside_power(pm, n; kwargs...)
    variable_acside_current(pm, n; kwargs...)
    variable_converter_filter_voltage(pm, n; kwargs...)
    variable_converter_internal_voltage(pm, n; kwargs...)
    variable_converter_to_grid_active_power(pm, n; kwargs...)
    variable_converter_to_grid_reactive_power(pm, n; kwargs...)
end

"variable: `pconv_ac[j]` for `j` in `convdc`"
function variable_converter_active_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:pconv_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_ac",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Pacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Pacmax"]
        )
    else
        pm.var[:nw][n][:pconv_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_ac",
        start = PowerModels.getstart(pm.ref[:nw][n][:convdc], i, "P_g")
        )
    end
end

"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_converter_reactive_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:qconv_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_qconv_ac",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Qacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Qacmax"]
        )
    else
        pm.var[:nw][n][:qconv_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_qconv_ac",
        start = PowerModels.getstart(pm.ref[:nw][n][:convdc], i, "Q_g")
        )
    end
end



"variable: `pconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_active_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:pconv_grid_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_ac",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Pacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Pacmax"]
        )
    else
        pm.var[:nw][n][:pconv_grid_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_ac",
        start = PowerModels.getstart(pm.ref[:nw][n][:convdc], i, "P_g")
        )
    end
end

"variable: `qconv_grid_ac[j]` for `j` in `convdc`"
function variable_converter_to_grid_reactive_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:qconv_grid_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_qconv_ac",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Qacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Qacmax"]
        )
    else
        pm.var[:nw][n][:qconv_grid_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_qconv_ac",
        start = PowerModels.getstart(pm.ref[:nw][n][:convdc], i, "Q_g")
        )
    end
end


"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    bigM = 1.2; # to account for losses, maximum losses to be derived
    if bounded
        pm.var[:nw][n][:pconv_dc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_dc",
        lowerbound = -pm.ref[:nw][n][:convdc][i]["Pacrated"] * bigM,
        upperbound =  pm.ref[:nw][n][:convdc][i]["Pacrated"] * bigM #TODO derive maximum losses
        )
    else
        pm.var[:nw][n][:pconv_dc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_dc",
        start = PowerModels.getstart(pm.ref[:nw][n][:convdc], i, "Pdcset")
        )
    end
end

"variable: `iconv_ac[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:iconv_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_iconv_ac",
    lowerbound = 0,
    upperbound = sqrt(pm.ref[:nw][n][:convdc][i]["Pacrated"]^2 + pm.ref[:nw][n][:convdc][i]["Qacmax"]^2) / sqrt(3) # assuming rated voltage = 1pu
    )
end

function variable_converter_filter_voltage(pm::GenericPowerModel, n::Int=pm.cnw; kwargs...)
    variable_converter_filter_voltage_magnitude(pm, n; kwargs...)
    variable_converter_filter_voltage_angle(pm, n; kwargs...)
end


"variable: `vmf_ac[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_magnitude(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    pm.var[:nw][n][:vmf_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_vmf_ac",
    lowerbound = pm.ref[:nw][n][:convdc][i]["Vmmin"]/bigM,
    upperbound = pm.ref[:nw][n][:convdc][i]["Vmmax"]*bigM
    )
end


"variable: `vaf_ac[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_angle(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    bigM = 2*pi; #
    pm.var[:nw][n][:vaf_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_vaf_ac",
    lowerbound = -bigM,
    upperbound = bigM
    )
end


function variable_converter_internal_voltage(pm::GenericPowerModel, n::Int=pm.cnw; kwargs...)
    variable_converter_internal_voltage_magnitude(pm, n; kwargs...)
    variable_converter_internal_voltage_angle(pm, n; kwargs...)
end


"variable: `vmc_ac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_magnitude(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:vmc_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_vmc_ac",
    lowerbound = pm.ref[:nw][n][:convdc][i]["Vmmin"],
    upperbound = pm.ref[:nw][n][:convdc][i]["Vmmax"]
    )
end

"variable: `vac_ac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_angle(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    bigM = 2*pi; #
    pm.var[:nw][n][:vac_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_vac_ac",
    lowerbound = -bigM,
    upperbound = bigM
    )
end



"variable: `wf_ac[j]` for `j` in `convdc`"
function variable_converter_filter_voltage_wr_wrm(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    pm.var[:nw][n][:wf_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_wf_ac",
    lowerbound = (pm.ref[:nw][n][:convdc][i]["Vmmin"]/bigM)^2,
    upperbound = (pm.ref[:nw][n][:convdc][i]["Vmmax"]*bigM)^2
    )
    pm.var[:nw][n][:wrf_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_wrf_ac",
    lowerbound = 0,
    upperbound = (pm.ref[:nw][n][:convdc][i]["Vmmax"]*bigM)^2
    )
    pm.var[:nw][n][:wif_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_wif_ac",
    lowerbound = -(pm.ref[:nw][n][:convdc][i]["Vmmax"]*bigM)^2,
    upperbound = (pm.ref[:nw][n][:convdc][i]["Vmmax"]*bigM)^2
    )
end

"variable: `wf_ac[j]` for `j` in `convdc`"
function variable_converter_internal_voltage_wr_wrm(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    bigM = 1.2; # only internal converter voltage is strictly regulated
    pm.var[:nw][n][:wc_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_wc_ac",
    lowerbound = (pm.ref[:nw][n][:convdc][i]["Vmmin"])^2,
    upperbound = (pm.ref[:nw][n][:convdc][i]["Vmmax"])^2
    )
    pm.var[:nw][n][:wrc_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_wrc_ac",
    lowerbound = 0,
    upperbound = (pm.ref[:nw][n][:convdc][i]["Vmmax"]*bigM)^2
    )
    pm.var[:nw][n][:wic_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_wic_ac",
    lowerbound = -(pm.ref[:nw][n][:convdc][i]["Vmmax"]*bigM)^2,
    upperbound = (pm.ref[:nw][n][:convdc][i]["Vmmax"]*bigM)^2
    )
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


"variable: `iconv_dc[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true) where {T <: PowerModels.AbstractWRForm}
    pm.var[:nw][n][:iconv_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_iconv_dc",
    lowerbound = 0,
    upperbound = sqrt(pm.ref[:nw][n][:convdc][i]["Pacrated"]^2 + pm.ref[:nw][n][:convdc][i]["Qacrated"]^2) / sqrt(3) # assuming rated voltage = 1pu
    )
    pm.var[:nw][n][:iconv_ac_sq] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_iconv_dc_sq",
    lowerbound = 0,
    upperbound = (pm.ref[:nw][n][:convdc][i]["Pacrated"]^2 + pm.ref[:nw][n][:convdc][i]["Qacrated"]^2) / (3) # assuming rated voltage = 1pu
    )
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true) where {T <: PowerModels.AbstractWRForm}
    if bounded
        pm.var[:nw][n][:wdc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:busdc])], basename="$(n)_wdc",
        lowerbound = pm.ref[:nw][n][:busdc][i]["Vdcmin"]^2,
        upperbound = pm.ref[:nw][n][:busdc][i]["Vdcmax"]^2,
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)^2
        )
        print()
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


"variable: `iconv_dc[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true) where {T <: PowerModels.AbstractWRMForm}
    pm.var[:nw][n][:iconv_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_iconv_dc",
    lowerbound = 0,
    upperbound = sqrt(pm.ref[:nw][n][:convdc][i]["Pacrated"]^2 + pm.ref[:nw][n][:convdc][i]["Qacrated"]^2) / sqrt(3) # assuming rated voltage = 1pu
    )
    pm.var[:nw][n][:iconv_ac_sq] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_iconv_dc_sq",
    lowerbound = 0,
    upperbound = (pm.ref[:nw][n][:convdc][i]["Pacrated"]^2 + pm.ref[:nw][n][:convdc][i]["Qacrated"]^2) / (3) # assuming rated voltage = 1pu
    )
end


"variable: `vdcm[i]` for `i` in `dcbus`es"
function variable_dcgrid_voltage_magnitude(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true) where {T <: PowerModels.AbstractWRMForm}
    if bounded
        pm.var[:nw][n][:wdc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:busdc])], basename="$(n)_wdc",
        lowerbound = pm.ref[:nw][n][:busdc][i]["Vdcmin"]^2,
        upperbound = pm.ref[:nw][n][:busdc][i]["Vdcmax"]^2,
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)^2
        )
        print()
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
