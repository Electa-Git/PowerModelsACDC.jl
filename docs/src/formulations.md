# Network Formulations

Extending PowerModels, new formulations for *unbalanced* (O)PF have been implemented
- AC (NLP) with polar voltage variables and rectangular power variables - `UnbACPowerModel` in `uac.jl`
- Convexified (SDP) unbalanced DistFlow (BFM) per Gan and Low, PSCC 2014, extended for pi-sections, using 3x3 phase sequence representation - `UnbDistPowerModel` in `df.jl`
- Simplified unbalanced DistFlow, where, w.r.t.  the series losses are neglected (and set to zero). This trivializes the SDP constraint, which is then consequently dropped and a linear model is finally obtained. `SUnbDistPowerModel` in `sdf.jl`

Phase sequence impedance models are discussed in [^1]

## Type Hierarchy
```julia
AbstractUnbACForm <: PowerModels.AbstractPowerFormulation
AbstractUnbDistForm <: PowerModels.AbstractPowerFormulation
AbstractSUnbDistForm  <: PowerModels.AbstractPowerFormulation
```

## Power Models
Each of these forms can be used as the type parameter for a PowerModel:
```julia
UnbACPowerModel = PowerModels.GenericPowerModel{AbstractUnbACForm}
UnbDistPowerModel = PowerModels.GenericPowerModel{AbstractUnbDistForm}
SUnbDistPowerModel = PowerModels.GenericPowerModel{AbstractSUnbDistForm}

```

For details on `GenericPowerModel`, see PowerModels.jl documentation.


[^1]: Kersting, W. H., & Philips, W. H. (1995). Distribution feeder line models. IEEE Trans. Ind. Appl., 31(4), 715–720.
