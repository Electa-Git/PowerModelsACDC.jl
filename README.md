# PowerModelsACDC.jl

Dev:
[![Build Status](https://travis-ci.org/hakanergun/PowerModelsACDC.jl.svg?branch=master)](https://travis-ci.org/hakanergun/PowerModelsACDC.jl)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://hakanergun.github.io/PowerModelsACDC.jl/latest)


PowerModelsACDC.jl is a Julia/JuMP/PowerModels package with models for DC lines, meshed DC networks, and AC DC converters.
Building upon the PowerModels architecture, the code is engineered to decouple problem specifications (e.g. Power Flow, Optimal Power Flow, ...) from the power network formulations (e.g. AC, DC-approximation, SOC-relaxation, ...).

**Core Problem Specifications**
* Optimal Power Flow with both point-to-point and meshed and dc grid support
* Power Flow with both point-to-point and meshed ac and dc grid support


**Core Formulations**
All AC formulations of PowerModels are re-used.
Therefore, the core formulations in this package are twofold: those for the DC network and those for the AC/DC converters.

DC network connecting dc nodes:
* DC nonlinear nonconvex formulation (NLP)
* Convexified (SOC) bus injection model and branch flow model for the DC grid (which can be used with both the SDP and SOC convex relaxation formulations for the AC side)
* Linearized (LP) active power only formulation, extending the linearized 'DC' approximation of AC grids to DC grids

AC/DC converter stations, connecting ac nodes and dc nodes, are composed of a transformer, filter, phase reactor and LCC/VSC converter. The passive components can be removed/disabled. Convex relaxation and linearized models for the passive components have been described, therefore, the converter station formulation is categorized by converter model complexity. The converter model includes constant losses and losses proportional to the current magnitude as well as current magnitude squared.
* Nonlinear nonconvex formulation (NLP)
* Convexified formulation (SOC)
* Linearized formulation (LP)

**Network Data Formats**
* MatACDC-style ".m" files (matpower ".m"-derived).
* Matpower-style ".m" files, including matpower's dcline extenstions.
* PTI

Note that the matpower-style `dcline` is transformed internally to two converters + a dcline connecting them. Such a transformation is exact for the 'dc'-style linearized models, but not for the AC models.

For further information, consult the PowerModels [documentation](https://lanl-ansi.github.io/PowerModels.jl/stable/).


## Acknowledgments

The developers thank Carleton Coffrin (LANL) for his support.

## Citing PowerModelsACDC

If you find PowerModelsACDC useful in your work, we kindly request that you cite the following [publication](https://ieeexplore.ieee.org/document/8636236):

```
@ARTICLE{8636236,
author={H. Ergun and J. Dave and D. Van Hertem and F. Geth},
journal={IEEE Transactions on Power Systems},
title={Optimal Power Flow for AC/DC Grids: Formulation, Convex Relaxation, Linear Approximation and Implementation},
year={2019},
volume={},
number={},
pages={1-1},
keywords={Mathematical model;HVDC transmission;AC-DC power converters;Numerical models;Inductors;Impedance;Linear approximation;HVDC transmission;flexible ac transmission systems;power system analysis computing},
doi={10.1109/TPWRS.2019.2897835},
ISSN={0885-8950},
month={},}
```

## License

This code is provided under a BSD license.
