# PowerModelACDC.jl Documentation

```@meta
CurrentModule = PowerModelsACDC
```

## Overview

PowerModelsADriaN.jl is a Julia/JuMP package extending PowerModels.jl, which focuses on Steady-State Power Network Optimization. PowerModels.jl provides utilities for parsing and modifying network data and is designed to enable computational evaluation of emerging power network formulations and algorithms in a common platform.

PowerModelsAdrian.jl adds new formulations and problem types:
- OPF with shiftable (PST) and tappable (OLTC) transformers `tfopf`
- OPF with shiftable (PST) and tappable (OLTC) transformers, and with load shedding `unittfopf`
- Two-stage SCOPF (generator and line contingencies) with shiftable (PST) and tappable (OLTC) transformers, and with load shedding `scunittfopf`
- Unbalanced OPF with flexible generation `ubopf`
- Unbalanced power flow `ubpf`


## Installation of PowerModelACDC

The latest stable release of PowerModelsADriaN can be installed using the Julia package manager with

```julia
Pkg.clone("https://<USERNAME>@git.vito.be/scm/amo-adn/powermodelsadrian.jl.git")
```

!!! note
    This is a research-grade optimization package. There may be issues with the code. Please consult the [issue tracker](https://jira.vgt.vito.be/browse/ADN-17?filter=-5) to get an overview of the open issues.


## Other useful packages
### SDP solver
For solving SDP problems, an SDP solver is required. Ipopt does not support SDP. Mosek is commercial (free for universities), but SCS and CSDP are open-source solvers which can be used.
Install SCS using `Pkg.add("SCS")`.


### JSON parser and writer
Dicts (including the result struct) can be easily serialized to the JSON format, offering good compatibility with Python. Install using `Pkg.add("JSON")`
