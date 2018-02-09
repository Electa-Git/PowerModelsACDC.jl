"variable: `p_dcgrid[l,i,j]` for `(l,i,j)` in `arcs_dcgrid`"
function variable_active_dcbranch_flow(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:p_dcgrid] = @variable(pm.model,
        [(l,i,j) in pm.ref[:nw][n][:arcs_dcgrid]], basename="$(n)_pdcgrid",
        lowerbound = -pm.ref[:nw][n][:branchdc][l]["rateA"],
        upperbound =  pm.ref[:nw][n][:branchdc][l]["rateA"]
    )
end

function variable_dc_converter(pm::GenericPowerModel, n::Int=pm.cnw; kwargs...)
    variable_acside_active_power(pm, n; kwargs...)
    variable_acside_reactive_power(pm, n; kwargs...)
    variable_dcside_power(pm, n; kwargs...)
    variable_acside_current(pm, n; kwargs...)
end

"variable: `pconv_ac[j]` for `j` in `convdc`"
function variable_acside_active_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:pconv_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_ac",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Pacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Pacmax"]
    )
end

"variable: `qconv_ac[j]` for `j` in `convdc`"
function variable_acside_reactive_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:qconv_ac] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_qconv_ac",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Qacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Qacmax"]
    )
end

"variable: `pconv_dc[j]` for `j` in `convdc`"
function variable_dcside_power(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:pconv_dc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_pconv_dc",
        lowerbound = pm.ref[:nw][n][:convdc][i]["Pacmin"],
        upperbound = pm.ref[:nw][n][:convdc][i]["Pacmax"]
    )
end

"variable: `iconv_dc[j]` for `j` in `convdc`"
function variable_acside_current(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:iconv_dc] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:convdc])], basename="$(n)_iconv_dc",
        lowerbound = 0,
        upperbound = sqrt(pm.ref[:nw][n][:convdc][i]["Pacrated"]^2 + pm.ref[:nw][n][:convdc][i]["Qacrated"]^2) / sqrt(3) # assuming rated voltage = 1pu
    )
end

"variable: `v[i]` for `i` in `bus`es"
function variable_dcgrid_voltage_magnitude(pm::GenericPowerModel, n::Int=pm.cnw; bounded = true)
    pm.var[:nw][n][:vdcm] = @variable(pm.model,
        [i in keys(pm.ref[:nw][n][:busdc])], basename="$(n)_vdcm",
        lowerbound = pm.ref[:nw][n][:busdc][i]["Vdcmin"],
        upperbound = pm.ref[:nw][n][:busdc][i]["Vdcmax"],
        start = PowerModels.getstart(pm.ref[:nw][n][:busdc], i, "Vdc", 1.0)
    )

end
