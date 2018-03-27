"do nothing, this model does not have complex voltage constraints"
function constraint_voltage_dc(pm::GenericPowerModel, n::Int)
end

"""
```
sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == pd
```
"""
function constraint_kcl_shunt_dcgrid(pm::GenericPowerModel, n::Int, i::Int, bus_arcs_dcgrid, bus_convs_dc, pd)
    p_dcgrid = pm.var[:nw][n][:p_dcgrid]
    pconv_dc = pm.var[:nw][n][:pconv_dc]

    pm.con[:nw][n][:kcl_dcgrid][i] = @constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == (-pd))
end

"`pconv[i] == pconv`"
function constraint_active_conv_setpoint(pm::GenericPowerModel, n::Int, i, pconv)
    pconv_var = pm.var[:nw][n][:pconv_grid_ac][i]
    pm.con[:nw][n][:conv_pac][i] = @constraint(pm.model, pconv_var == -pconv)
end

"`qconv[i] == qconv`"
function constraint_reactive_conv_setpoint(pm::GenericPowerModel, n::Int, i, qconv)
    qconv_var = pm.var[:nw][n][:qconv_grid_ac][i]
    pm.con[:nw][n][:conv_qac][i] = @constraint(pm.model, qconv_var == -qconv)
end
