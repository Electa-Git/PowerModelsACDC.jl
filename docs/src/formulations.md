# Type Hierarchy
The original type hierarchy of PowerModels is used.

For details on `GenericPowerModel`, see PowerModels.jl documentation.

#  Formulations overview

Extending PowerModels,  formulations for balanced  OPF in DC grids have been implemented for these corresponding AC grid formulations
- DCPPowerModel
- ACPPowerModel
- SOCWRPowerModel
- SDPWRMPowerModel
- QCWRPowerModel
- QCWRTriPowerModel


# Formulation details
## ACPPowerModel
### DC lines
- Active power flow from side: $P^{dc}_{ij}$ = $p \cdot g^{series}_{ij} \cdot U^{dc}_i \cdot (U^{dc}_i - U^{dc}_j)$.
- Active power flow to side: $P^{dc}_{ji}$ = $p \cdot g^{series}_{ij} \cdot U^{dc}_j \cdot (U^{dc}_j - U^{dc}_i)$.


### ACDC converters
- Power balance: $P^{conv, ac}_{ij} + P^{conv, dc}_{ji}$ = $a + b \cdot I^{conv, ac} + c \cdot (I^{conv, ac})^2$.
- Current variable model: $(P^{conv,ac}_{ij})^2$ + $(Q^{conv,ac}_{ij})^2$ = $3 \cdot U_i^2 \cdot  (I^{conv, ac})^2$.


## DCPPowerModel
### DC lines
- Network flow model: $P^{dc}_{ij}$ + $P^{dc}_{ji}$ = $0$


### ACDC converters
- Network flow model: $P^{conv, ac}_{ij}$ + $P^{conv, dc}_{ji}$ = $a$




## SOCWRPowerModel, SDPWRMPowerModel,  QCWRPowerModel and QCWRTriPowerModel
For the SDP formulation, the norm syntax is used to represent the SOCs.


### DC lines
The variable $u^{dc}_{ii}$ represents $(U^{dc}_{i})^2$ and $u^{dc}_{ij}$ represents $U^{dc}_{i}\cdot U^{dc}_{j}$.
- Active power flow from side: $P^{dc}_{ij}$ = $p \cdot g^{series} \cdot (u^{dc}_{ii} - u^{dc}_{ij})$.
- Active power flow to side: $P^{dc}_{ji}$ = $p \cdot g^{series} \cdot (u^{dc}_{jj} - u^{dc}_{ij})$.
- Convex relaxation of voltage products: $(u^{dc}_{ij})^2 \leq u^{dc}_{ii} \cdot u^{dc}_{jj}$.


### ACDC converters
Two separate current variables, $I^{conv, ac}$ and $i^{conv, ac, sq}$ are defined, the nonconvex relation $i^{conv, ac, sq} = (I^{conv, ac})^2$ is convexified, using $U_i \leq U_i^{max}$:
- Power balance: $P^{conv, ac}_{ij} + P^{conv, dc}_{ji}$ = $a + b\cdot I^{conv, ac} + c\cdot i^{conv, ac, sq}$.
- Squared current: $(P^{conv, ac}_{ij})^2 + (Q^{conv, ac}_{ij})^2 \leq 3 \cdot u_{ii} \cdot  i^{conv, ac, sq}$
- Linear current: $(P^{conv, ac}_{ij})^2 + (Q^{conv, ac}_{ij})^2 \leq 3 \cdot (U_i^{max})^2 \cdot  (I^{conv, ac})^2$
- Linking both current variables: $(I^{conv, ac})^2$ $\leq$ $i^{conv, ac, sq}$
