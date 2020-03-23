"do nothing, this model does not have complex voltage constraints"
function constraint_voltage_dc(pm::AbstractPowerModel,  n::Int)
end

"""
```
sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == pd
```
"""
function constraint_kcl_shunt_dcgrid(pm::AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid, bus_convs_dc, pd)
    p_dcgrid = PowerModels.var(pm, n, :p_dcgrid)
    pconv_dc = PowerModels.var(pm, n, :pconv_dc)

    PowerModels.con(pm, n, :kcl_dcgrid)[i] = @constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == (-pd))
end

"`pconv[i] == pconv`"
function constraint_active_conv_setpoint(pm::AbstractPowerModel, n::Int, i, pconv)
    pconv_var = PowerModels.var(pm, n, :pconv_tf_fr, i)
    PowerModels.con(pm, n, :conv_pac)[i] = @constraint(pm.model, pconv_var == -pconv)
end

"`qconv[i] == qconv`"
function constraint_reactive_conv_setpoint(pm::AbstractPowerModel, n::Int, i, qconv)
    qconv_var = PowerModels.var(pm, n, :qconv_tf_fr, i)
    PowerModels.con(pm, n, :conv_qac)[i] = @constraint(pm.model, qconv_var == -qconv)
end
