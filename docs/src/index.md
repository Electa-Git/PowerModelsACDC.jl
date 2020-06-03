# PowerModelACDC.jl Documentation

```@meta
CurrentModule = PowerModelsACDC
```

## Overview

PowerModelsACDC.jl is a Julia/JuMP package extending PowerModels.jl, which focuses on Steady-State Power Network Optimization. PowerModels.jl provides utilities for parsing and modifying network data and is designed to enable computational evaluation of emerging power network formulations and algorithms in a common platform.

PowerModelsACDC.jl adds new problem types:
- Power flow with both ac and dc lines, from point-to-point connections to meshed grids, with converters connecting ac and dc grid lines
- The equivalent optimal power flow problem type and TNEP problem type

PowerModelsACDC.jl extends the formulation hierarchy developed for AC grids, with equivalent DC grid and converter station formulations:
- ACPPowerModel
- DCPPowerModel
- SOCWRPowerModel
- SDPWRMPowerModel
- QCWRPowerModel
- QCWRTriPowerModel
- LPACPowerModel

Developed by:
- Hakan Ergun, Jay Dave KU Leuven / EnergyVille
- Frederik Geth, CSIRO


## Installation of PowerModelACDC

The latest stable release of PowerModelACDC can be installed using the Julia package manager with

```julia
Pkg.add("PowerModelsACDC")
```
The current version of PowerModelsACDC is 0.3.1 and is compatible with PowerModels v0.17.1, InfrastrucureModels v0.5.0

!!! Important
    This is a research-grade optimization package.

## Special Thanks To
Jef Beerten (KU Leuven/EnergyVille) for his insights in AC/DC power flow modelling.
Carleton Coffrin (Los Alamos National Laboratory) for his countless design tips.  
