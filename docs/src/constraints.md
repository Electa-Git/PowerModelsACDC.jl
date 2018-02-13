# Constraints

```@meta
CurrentModule = PowerModelsACDC
```

## Unit Constraints

```@docs
constraint_active_load_gen_aggregation
constraint_reactive_load_gen_aggregation
constraint_active_load_gen_aggregation_sheddable
constraint_reactive_load_gen_aggregation_sheddable
constraint_flexible_active_load
constraint_flexible_reactive_load
constraint_fixed_active_load
constraint_fixed_reactive_load
constraint_flexible_active_gen
constraint_flexible_reactive_gen
constraint_redispatch_active_power_gen
constraint_redispatch_reactive_power_gen
constraint_second_stage_redispatch_active_power_gen
constraint_second_stage_redispatch_reactive_power_gen
constraint_redispatch_active_power_load
constraint_redispatch_reactive_power_load
constraint_second_stage_redispatch_active_power_load
constraint_second_stage_redispatch_reactive_power_load
constraint_tan_phi_load
constraint_active_power_gen_contingency
constraint_reactive_power_gen_contingency
constraint_active_power_branch_contingency
constraint_reactive_power_branch_contingency
```

## Bus Constraints

### Setpoint Constraints

```@docs
constraint_voltage_reference_ub
```

### KCL Constraints

```@docs
constraint_kcl_shunt_ub
```

## Branch Constraints

### Ohm's Law Constraints

```@docs
constraint_ohms_ub
```

### Current

```@docs
constraint_branch_limit_ub
```
