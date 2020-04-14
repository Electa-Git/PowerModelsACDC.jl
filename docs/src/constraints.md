# Constraints
All the OPF constraints for the AC grids have been re-used from _PM.jl, and are therefore not repeated here.

```@meta
CurrentModule = PowerModelsACDC
```

## Unit Constraints

```@docs
constraint_active_load_gen_aggregation
```

## DC Bus Constraints

### Setpoint Constraints

```@docs
constraint_dc_voltage_magnitude_setpoint
```

### KCL Constraints

```@docs
constraint_kcl_shunt_dcgrid
```
## AC Bus Constraints

### KCL Constraints
```@docs
constraint_kcl_shunt
```

## DC Branch Constraints

### Ohm's Law Constraints

```@docs
constraint_ohms_dc_branch

```


## ACDC Converter Constraints

### Ohm's Law Constraints

```@docs
constraint_converter_losses
```

### Current

```@docs
constraint_converter_current
```

### Setpoint Constraints (PF only)

```@docs
constraint_active_conv_setpoint
```

### Converter auxiliary constraints
```@docs
constraint_conv_transformer
constraint_conv_reactor
constraint_conv_filter
```

### Converter firing angle for LCC
```@docs
constraint_conv_firing_angle
```
