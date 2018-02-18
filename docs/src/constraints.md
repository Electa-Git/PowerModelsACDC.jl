# Constraints
All the OPF constraints for the AC grids have been re-used from PowerModels.jl, and are therefore not repeated here. 

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
constraint_kcl_shunt
```

## DC Branch Constraints

### Ohm's Law Constraints

```@docs
constraint_ohms_dc_branch
constraint_kcl_shunt_dcgrid
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

### Setpoint Constraints

```@docs
constraint_active_conv_setpoint
```
