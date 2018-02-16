# PowerModelsACDC.jl

PowerModelsACDC.jl is a Julia/JuMP/PowerModels package with extensions for DC lines and networks.
Building upon  PowerModels, the code is engineered to decouple problem specifications (e.g. Power Flow, Optimal Power Flow, ...) from the power network formulations (e.g. AC, DC-approximation, SOC-relaxation, ...).

**Core Problem Specifications**
* Power Flow with both point-to-point and meshed ac and dc grid support
* Optimal Power Flow with both point-to-point and meshed and dc grid support


**Core Network Formulations**
* AC
* SOC bus injection model for the DC grid, which can be used with both the SDP and SOC convex relaxation formulations for the AC side

**Network Data Formats**
* MatACDC-style ".m" files (matpower ".m"-derived)

For further information, consult the PowerModels [documentation](https://lanl-ansi.github.io/PowerModels.jl/stable/).


## Acknowledgments

The developers thank Carleton Coffrin for his support

## License

This code is provided under a BSD license.
