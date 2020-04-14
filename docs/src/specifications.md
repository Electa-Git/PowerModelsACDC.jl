# Problem Specifications

## ACDCOPF


OPF with support for AC and DC grids at the same time, including AC/DC converters.




#### Variables
```julia
variable_voltage(pm)
variable_generation(pm)
variable_branch_flow(pm)
```

#### Objective
```julia
objective_min_fuel_cost(pm)
```

#### Constraints
```julia

variable_active_dcbranch_flow(pm)
variable_dcbranch_current(pm)
variable_dc_converter(pm)
variable_dcgrid_voltage_magnitude(pm)

constraint_voltage(pm)
constraint_voltage_dc(pm)

for i in _PM.ids(pm, :ref_buses)
    constraint_theta_ref(pm, i)
end

for i in _PM.ids(pm, :bus)
    constraint_kcl_shunt(pm, i)
end

for i in _PM.ids(pm, :branch)
    # dirty, should be improved in the future TODO
    if typeof(pm) <: _PM.SOCDFPowerModel
        constraint_flow_losses(pm, i)
        constraint_voltage_magnitude_difference(pm, i)
        constraint_branch_current(pm, i)
    else
        constraint_ohms_yt_from(pm, i)
        constraint_ohms_yt_to(pm, i)
    end

    constraint_voltage_angle_difference(pm, i)

    constraint_thermal_limit_from(pm, i)
    constraint_thermal_limit_to(pm, i)
end
for i in _PM.ids(pm, :busdc)
    constraint_kcl_shunt_dcgrid(pm, i)
end
for i in _PM.ids(pm, :branchdc)
    constraint_ohms_dc_branch(pm, i)
end
for i in _PM.ids(pm, :convdc)
    constraint_converter_losses(pm, i)
    constraint_converter_current(pm, i)
    constraint_conv_transformer(pm, i)
    constraint_conv_reactor(pm, i)
    constraint_conv_filter(pm, i)
    if pm.ref[:nw][pm.cnw][:convdc][i]["islcc"] == 1
        constraint_conv_firing_angle(pm, i)
    end
end
```
