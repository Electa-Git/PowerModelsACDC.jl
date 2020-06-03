# PowerModelsACDC.jl

Dev:
[![Build Status](https://travis-ci.org/hakanergun/PowerModelsACDC.jl.svg?branch=master)](https://travis-ci.org/hakanergun/PowerModelsACDC.jl)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://hakanergun.github.io/PowerModelsACDC.jl/latest)


PowerModelsACDC.jl is a Julia/JuMP/PowerModels package with models for DC lines, meshed DC networks, and AC DC converters.
Building upon the PowerModels architecture, the code is engineered to decouple problem specifications (e.g. Power Flow, Optimal Power Flow, ...) from the power network formulations (e.g. AC, DC-approximation, SOC-relaxation, ...).

**Installation**
The latest stable release of PowerModelACDC can be installed using the Julia package manager with

```julia
Pkg.add("PowerModelsACDC")
```
The current version of PowerModelsACDC is 0.3.1 and is compatible with PowerModels v0.17.1, InfrastrucureModels v0.5.0


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

For further information, consult the PowerModels [documentation](https://lanl-ansi.github.io/_PM.jl/stable/).


## Acknowledgments

The developers thank Carleton Coffrin (LANL) for his support.

## Citing PowerModelsACDC

If you find PowerModelsACDC useful in your work, we kindly request that you cite the following publications:
[AC/DC OPF Core](https://ieeexplore.ieee.org/document/8636236):
```
@ARTICLE{8636236,
author={H. {Ergun} and J. {Dave} and D. {Van Hertem} and F. {Geth}},
journal={IEEE Transactions on Power Systems},
title={Optimal Power Flow for AC�DC Grids: Formulation, Convex Relaxation, Linear Approximation, and Implementation},
year={2019},
volume={34},
number={4},
pages={2980-2990},
keywords={AC-DC power convertors;approximation theory;HVDC power convertors;HVDC power transmission;power grids;power transmission control;reactive power control;AC-DC grids;linear approximation;active power control capabilities;reactive power control capabilities;HVDC converter stations;power systems;ancillary services;optimal power flow model;convex relaxation formulation;parameterized ac-dc converter model;common ac optimal power flow formulations;dc nodes;converter station technologies;ac nodes;ancillary security;open-source tool;Mathematical model;HVDC transmission;AC-DC power converters;Numerical models;Inductors;Impedance;Linear approximation;HVDC transmission;flexible ac transmission systems;power system analysis computing},
doi={10.1109/TPWRS.2019.2897835},
ISSN={0885-8950},
month={July},}
```
[TNEP Extension 1](https://digital-library.theiet.org/content/journals/10.1049/iet-gtd.2019.0383):
```
@ARTICLE{
   iet:/content/journals/10.1049/iet-gtd.2019.0383,
   author = {Jay Dave},
   author = {Hakan Ergun},
   author = {Ting An},
   author = {Jingjing Lu},
   author = {Dirk Van Hertem},
   keywords = {power systems;meshed HVDC grids;increased utilisation;presented formulations;convex formulations;second-order cone convex relaxation;multiple HVDC links;linear approximation;dc grids;transmission network expansion planning problem;high-voltage direct current;traditional ac grid;TNEP problem;nonlinear formulation;},
   ISSN = {1751-8687},
   title = {TNEP of meshed HVDC grids: ‘AC’, ‘DC’ and convex formulations},
   journal = {IET Generation, Transmission & Distribution},
   issue = {24},   
   volume = {13},
   year = {2019},
   month = {December},
   pages = {5523-5532(9)},
   publisher ={Institution of Engineering and Technology},
   copyright = {© The Institution of Engineering and Technology},
   url = {https://digital-library.theiet.org/content/journals/10.1049/iet-gtd.2019.0383}
}
```
## License

This code is provided under a BSD license.
