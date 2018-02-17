# Problem Specifications

## ACDCOPF


OPF with support for AC and DC grids at the same time




#### Variables
```julia
variable_unb_voltage(pm)
variable_unb_current(pm)
variable_unb_line_flow(pm)
variable_unb_generation(pm)
```

#### Objective
```julia
objective_min_fuel_cost_ub(pm)
```

#### Constraints
```julia
for i in ids(pm, :ref_buses)
    constraint_voltage_reference_ub(pm, i)
end

for i in ids(pm, :branch)
     constraint_ohms_ub(pm, i)
     constraint_branch_limit_ub(pm, i)
     constraint_voltage_magnitudes(pm, i)
     constraint_psd(pm, i)
end

for i in ids(pm, :bus)
    constraint_kcl_shunt_ub(pm, i)
end
```
