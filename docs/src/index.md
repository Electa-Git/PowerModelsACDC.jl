# PowerModelACDC.jl Documentation

```@meta
CurrentModule = PowerModelsACDC
```

## Overview

PowerModelsACDC.jl is a Julia/JuMP package extending PowerModels.jl, which focuses on Steady-State Power Network Optimization. PowerModels.jl provides utilities for parsing and modifying network data and is designed to enable computational evaluation of emerging power network formulations and algorithms in a common platform.

PowerModelsACDC.jl adds new formulations and problem types:
- Power flow with both ac and dc lines, from point-to-point connections to meshed grids, with converters connecting ac and dc grid lines
- The equivalent optimal power flow problem type


## Installation of PowerModelACDC

The latest stable release of PowerModelACDC can be installed using the Julia package manager with

```julia
Pkg.clone("https://github.com/hakanergun/PowerModelsACDC.jl.git")
```

!!! note
    This is a research-grade optimization package. There may be issues with the code.
