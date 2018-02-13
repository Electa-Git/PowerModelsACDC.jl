# Problem Specifications

## Security-Constrained Optimal Power Flow (SCOPF)
Two-stage (preventive-corrective) 2-period security-constrained optimal power flow problem type.
This includes:
- Shiftable PSTs and tappable OLTCs
- Generator dispatch
- Load shedding
- Minimum risk: preventive and/or corrective

This does not yet include
- Contingency discarding with indicator variables
- Failure of corrective actions with indicator variables
- Blackout risk:
    - Risk of failure of corrective actions
    - Risk of not securing contingencies

### Overarching model
#### variables
```julia
variable_risk(pm)
variable_dispatch_cost(pm)
variable_redispatch_cost(pm)
variable_loadshedding_cost(pm)
```

#### Objective
```julia
objective_total_risk(pm, first_stage_network_id, second_stage_network_ids)
```

#### Constraints
```julia
first_stage_model(pm, first_stage_network_id)
second_stage_model(pm, first_stage_network_id, second_stage_network_ids)
```

### Preventive stage (stage 1)
#### Variables
```julia
PowerModels.variable_voltage(pm, n)
PowerModels.variable_generation(pm, n)
PowerModels.variable_line_flow(pm, n)
PowerModels.variable_dcline_flow(pm, n)
variable_transformation(pm, n)
variable_node_aggregation(pm, n)
variable_load(pm, n)
variable_action_indicator(pm, n)
variable_auxiliary_power(pm, n)
```

#### Constraints
```julia
PowerModels.constraint_voltage(pm, n)
for i in PowerModels.ids(pm, n, :ref_buses)
    PowerModels.constraint_theta_ref(pm, n, i)
end

for i in PowerModels.ids(pm, n, :bus)
    constraint_kcl_shunt_aggregated(pm, n, i)
    constraint_load_gen_aggregation_sheddable(pm, n, i)
end

for i in PowerModels.ids(pm, n, :load)
    constraint_fixed_load(pm, n, i)
end

for i in PowerModels.ids(pm, n, :gen)
    constraint_flexible_gen(pm, n, i)
    constraint_redispatch_power_gen(pm, n, i)
end

for i in PowerModels.ids(pm, n, :branch)
    branch = PowerModels.ref(pm, n, :branch, i)

    if branch["shiftable"] == false && branch["tappable"] == false
        PowerModels.constraint_ohms_yt_from(pm, n, i)
        PowerModels.constraint_ohms_yt_to(pm, n, i)
        constraint_link_voltage_magnitudes(pm, n, i)
    else
        constraint_variable_transformer_y_from(pm, n, i)
        constraint_variable_transformer_y_to(pm, n, i)
    end
    PowerModels.constraint_voltage_angle_difference(pm, n, i)

    PowerModels.constraint_thermal_limit_from(pm, n, i)
    PowerModels.constraint_thermal_limit_to(pm, n, i)
end
for i in PowerModels.ids(pm, n, :dcline)
    PowerModels.constraint_dcline(pm, n, i)
end
```

### Corrective stage (stage 2)
#### Variables
```julia
for (n, contingency) in second_stage_network_ids
    add_load_model!(pm, n) # To add load data
    add_power_factor!(pm, n) # To add load data
    PowerModels.variable_voltage(pm, n)
    PowerModels.variable_generation(pm, n)
    PowerModels.variable_line_flow(pm, n)
    PowerModels.variable_dcline_flow(pm, n)
    variable_transformation(pm, n)
    #variable_dispatch_cost(pm, n)
    variable_node_aggregation(pm, n)
    variable_load(pm, n)
    variable_action_indicator(pm, n)
    variable_auxiliary_power(pm, n)
end
```

#### Constraints
```julia
for (n, contingency) in second_stage_network_ids
    PowerModels.constraint_voltage(pm, n)
    for i in PowerModels.ids(pm, n, :ref_buses)
        PowerModels.constraint_theta_ref(pm, n, i)
    end

    for i in PowerModels.ids(pm, n, :bus)
        constraint_kcl_shunt_aggregated(pm, n, i)
        constraint_load_gen_aggregation_sheddable(pm, n, i)
    end

    for i in PowerModels.ids(pm, n, :load)
        constraint_flexible_load(pm, n, i)
        constraint_second_stage_redispatch_power_load(pm, n, i, first_stage_network_id)
    end

    contingencies = PowerModels.ref(pm, n, :contingencies)
    contingency_id = second_stage_network_ids[n]
    for i in PowerModels.ids(pm, n, :gen)
        if contingencies[contingency_id]["gen_id1"] == i || contingencies[contingency_id]["gen_id2"] == i || contingencies[contingency_id]["gen_id3"] == i
            constraint_gen_contingency(pm, n, i)
        else
            constraint_flexible_gen(pm, n, i)
            constraint_second_stage_redispatch_power_gen(pm, n, i, first_stage_network_id)
        end
    end

    for i in PowerModels.ids(pm, n, :branch)
        branch = PowerModels.ref(pm, n, :branch, i)
        if branch["shiftable"] == false && branch["tappable"] == false
            if contingencies[contingency_id]["branch_id1"] == i || contingencies[contingency_id]["branch_id2"] == i || contingencies[contingency_id]["branch_id3"] == i
                constraint_branch_contingency(pm, n, i)
            else
                PowerModels.constraint_ohms_yt_from(pm, n, i)
                PowerModels.constraint_ohms_yt_to(pm, n, i)
                constraint_link_voltage_magnitudes(pm, n, i)
            end
        else
            if contingencies[contingency_id]["branch_id1"] == i || contingencies[contingency_id]["branch_id2"] == i || contingencies[contingency_id]["branch_id3"] == i
                constraint_branch_contingency(pm, n, i)
            else
                constraint_variable_transformer_y_from(pm, n, i)
                constraint_variable_transformer_y_to(pm, n, i)
            end
        end
        PowerModels.constraint_voltage_angle_difference(pm, n, i)

        PowerModels.constraint_thermal_limit_from(pm, n, i)
        PowerModels.constraint_thermal_limit_to(pm, n, i)
    end
    for i in PowerModels.ids(pm, n, :dcline)
        PowerModels.constraint_dcline(pm, n, i)
    end
end
```



## Unbalanced Optimal Power Flow (SCOPF)
OPF with three explicit phases. The impedance matrix is fixed at `3x3` size, but it can be filled up with zeros.

The line model has
- a `3x3` series sequence impedance (`Zuvw`), which can be a full matrix
- a `3x3` shunt admittance (`Yuvw`, identical for to and from side), which can be a full matrix

For simplicity, in the parsing, the line model parameters are parse as follows:
- a full `3x3` series impedance is derived based on the `Z1 = R1 + jG1` direct impedance and `Z0` homopolar impedance. The homopolar impedance is assumed to be `3xZ1`.
- the shunt admittance matrix is assumed to be diagonal. Only a single value `Y1 = G1 + jB1` is needed to instantiate this diagonal matrix.

Phase variables internally are denoted `u,v,w`; "to" side `t` and from side `f`.

The model is implemented with support for multiperiod extensions, but has not been tested in this context








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
