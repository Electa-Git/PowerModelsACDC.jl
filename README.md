# PowerModelsACDC.jl

PowerModelsACDC.jl is a Julia/JuMP/PowerModels package with models for DC lines, meshed DC networks, and AC DC converters.
Building upon the PowerModels architecture, the code is engineered to decouple problem specifications (e.g. Power Flow, Optimal Power Flow, ...) from the power network formulations (e.g. AC, DC-approximation, SOC-relaxation, ...).

**Core Problem Specifications**
* Optimal Power Flow with both point-to-point and meshed and dc grid support
* Power Flow with both point-to-point and meshed ac and dc grid support


**Core Network Formulations**
* AC DC nonlinear nonconvex formulation
* Convexified SOC bus injection model for the DC grid, which can be used with both the SDP and SOC convex relaxation formulations for the AC side
* Linearized active power only formulation, extending the 'DC' approximation of AC grids to DC grids

**Network Data Formats**
* MatACDC-style ".m" files (matpower ".m"-derived)

For further information, consult the PowerModels [documentation](https://lanl-ansi.github.io/PowerModels.jl/stable/).


## Acknowledgments

The developers thank Carleton Coffrin for his support

## License

This code is provided under a BSD license.
