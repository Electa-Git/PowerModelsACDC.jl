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
    variable_acside_active_power(pm, n; kwargs...)
    variable_acside_reactive_power(pm, n; kwargs...)
    variable_dcside_power(pm, n; kwargs...)
    variable_acside_current(pm, n; kwargs...)
end

"variable: `p_conv[l,i,j]` for `(l,i,j)` in `conv_arcs_acdc`"
function variable_active_converter_flow(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:p_conv] = @variable(pm.model,
        [(l,i,j) in pm.ref[:nw][n][:arcs_conv_acdc]], basename="$(n)_pconv",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Pacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Pacmax"]
        )
    else
        pm.var[:nw][n][:p_conv] = @variable(pm.model,
        [(l,i,j) in pm.ref[:nw][n][:arcs_conv_acdc]], basename="$(n)_pconv",
        start = PowerModels.getstart(pm.ref[:nw][n][:convdc], i, "P_g")
        )
    end
    display(pm.var[:nw][n][:p_conv])
end

function variable_reactive_converter_flow(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:q_conv] = @variable(pm.model,
        [(l,i,j) in pm.ref[:nw][n][:arcs_conv_acdc]], basename="$(n)_qconv",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Qacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Qacmax"]
        )
    else
        pm.var[:nw][n][:q_conv] = @variable(pm.model,
        [(l,i,j) in pm.ref[:nw][n][:arcs_conv_acdc]], basename="$(n)_qconv",
        start = PowerModels.getstart(pm.ref[:nw][n][:convdc], i, "Q_g")
        )
    end
    display(pm.var[:nw][n][:q_conv])
end


"variable: `pconv_ac[j]` for `j` in `convdc`"
function variable_acside_active_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
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
function variable_acside_reactive_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
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

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    if bounded
        pm.var[:nw][n][:pconv_dc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_dc",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Pacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Pacmax"]
        )
    else
        pm.var[:nw][n][:pconv_dc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_dc",
        start = PowerModels.getstart(pm.ref[:nw][n][:convdc], i, "Pdcset")
        )
    end
end

"variable: `iconv_dc[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:iconv_ac] = @variable(pm.model,
    [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_iconv_dc",
    lowerbound = 0,
    upperbound = sqrt(pm.ref[:nw][n][:convdc][i]["Pacrated"]^2 + pm.ref[:nw][n][:convdc][i]["Qacrated"]^2) / sqrt(3) # assuming rated voltage = 1pu
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
function variable_acside_current{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true)
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
function variable_dcgrid_voltage_magnitude{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true)
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
function variable_acside_current{T <: PowerModels.AbstractWRMForm}(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true)
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
function variable_dcgrid_voltage_magnitude{T <: PowerModels.AbstractWRMForm}(pm::GenericPowerModel{T}, n::Int=pm.cnw; bounded = true)
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
