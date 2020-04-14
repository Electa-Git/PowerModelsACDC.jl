# Type Hierarchy
The original type hierarchy of PowerModels is used.

For details on `GenericPowerModel`, see _PM.jl [documentation](https://lanl-ansi.github.io/_PM.jl/stable/).

#  Formulations overview

Extending PowerModels,  formulations for balanced  OPF in DC grids have been implemented and mapped to the following AC grid formulations:
- ACPPowerModel
- DCPPowerModel
- LPACPowerModel
- SOCWRPowerModel
- SDPWRMPowerModel
- QCWRPowerModel
- QCWRTriPowerModel


Note that from the perspective of OPF convex relaxation for DC grids, applying the same assumptions as the AC equivalent, the same formulation (and variable space) is obtained for - SOCWRPowerModel,  SDPWRMPowerModel,  QCWRPowerModel and  QCWRTriPowerModel. These are referred to as formulations in the AC WR(M) variable space.

# Formulation details
The formulations are categorized as Bus Injection Model (BIM) or Branch Flow Model (BFM).
- Applied to DC grids, the BIM uses series conductance notation, and adds separate equations for the to and from line flow.
- Conversely, BFM uses series resistance parameters, and adds only a single equation per line, representing $P_{lij} + P_{lji} = P_{l}^{loss}$.

Note that in a DC grid, under the static power flow assumption, power is purely active, impedance reduces to resistance, and voltages and currents are defined by magnitude and direction.


Parameters used:
- $g^{series}=\frac{1}{r^{series}}$, dc line series impedance
- $p \in \{1,2\}$ for single ($1$) or bipole ($2$) DC lines
- $U_i^{max}$ maximum AC node voltage
- $a$ constant power converter loss
- $b$ converter loss proportional to current magnitude
- $c$ converter loss proportional to square of current magnitude

Note that generally, $a \geq 0, b \geq 0, c \geq 0$ as physical losses are positive.



## ACPPowerModel (BIM)
### DC lines
- Active power flow from side: $P^{dc}_{ij}$ = $p \cdot g^{series}_{ij} \cdot U^{dc}_i \cdot (U^{dc}_i - U^{dc}_j)$.
- Active power flow to side: $P^{dc}_{ji}$ = $p \cdot g^{series}_{ij} \cdot U^{dc}_j \cdot (U^{dc}_j - U^{dc}_i)$.


### ACDC converters
- Power balance: $P^{conv, ac}_{ij} + P^{conv, dc}_{ji}$ = $a + b \cdot I^{conv, ac} + c \cdot (I^{conv, ac})^2$.
- Current variable model: $(P^{conv,ac}_{ij})^2$ + $(Q^{conv,ac}_{ij})^2$ = $U_i^2 \cdot  (I^{conv, ac})^2$.
- LCC converters, active /reactive power:

$P^{conv, ac} = \cos\varphi_{c} \cdot S^{conv,ac,rated}$
$Q^{conv, ac} = \sin\varphi_{c} \cdot S^{conv,ac,rated}$

## DCPPowerModel (NF)
Due to the absence of voltage angles in DC grids, the DC power flow model reduces to network flow (NF) under the 'DC' assumptions
### DC lines
- Network flow model: $P^{dc}_{ij}$ + $P^{dc}_{ji}$ = $0$


### ACDC converters
Under the same assumptions as MATPOWER ($U_i \approx 1$), $P^{conv, ac}_{ij} \approx I^{conv, ac}$ allowing the converter model to be formulated as:
- Network flow model: $P^{conv, ac}_{ij}$ + $P^{conv, dc}_{ji}$ = $a + b P^{conv, ac}_{ij}$
- LCC converters, n.a.

## AC WR(M) variable space.  (BFM)
For the SDP formulation, the norm syntax is used to represent the SOC expressions below.


### DC lines
The variable $u^{dc}_{ii}$ represents $(U^{dc}_{i})^2$ and $i^{dc}_{ij}$ represents $(I^{dc}_{ij})^2$.
- Active power flow from side: $P^{dc}_{ij} + P^{dc}_{ji}$ = $p \cdot r^{series} \cdot i^{dc}_{ij}$.
- Convex relaxation of power definition: $(P^{dc}_{ij})^2 \leq u^{dc}_{ii} \cdot i^{dc}_{ij}$.
- Lifted KVL: $u^{dc}_{jj} = u^{dc}_{ii} -2 p \cdot r^{series} P^{dc}_{ij} + (r^{series})^2 i^{dc}_{ij}$

### ACDC converters
Two separate current variables, $I^{conv, ac}$ and $i^{conv, ac, sq}$ are defined, the nonconvex relation $i^{conv, ac, sq} = (I^{conv, ac})^2$ is convexified, using $U_i \leq U_i^{max}$:
- Power balance: $P^{conv, ac}_{ij} + P^{conv, dc}_{ji}$ = $a + b\cdot I^{conv, ac} + c\cdot i^{conv, ac, sq}$.
- Squared current: $(P^{conv, ac}_{ij})^2 + (Q^{conv, ac}_{ij})^2 \leq  u_{ii} \cdot  i^{conv, ac, sq}$
- Linear current: $(P^{conv, ac}_{ij})^2 + (Q^{conv, ac}_{ij})^2 \leq  (U_i^{max})^2 \cdot  (I^{conv, ac})^2$
- Linking both current variables: $(I^{conv, ac})^2$ $\leq$ $i^{conv, ac, sq}$
- LCC converters:
$Q^{conv,ac} \geq Q^{1}_{c} + (P^{conv,ac} - P^{1}_{c})\frac{(Q^{2}_{c}  - Q^{1}_{c})}{(P^{2}_{c}  - P^{1}_{c})}$
$P^{1}_{c} =  \cos  \varphi_{c}^{\text{min}} \cdot S^{conv,ac,rated}$
$P^{2}_{c} =   \cos \varphi_{c}^{\text{max}} \cdot S^{conv,ac,rated}$
$Q^{1}_{c} =   \sin  \varphi_{c}^{\text{min}} \cdot S^{conv,ac,rated}$
$Q^{2}_{c} =   \sin \varphi_{c}^{\text{max}} \cdot S^{conv,ac,rated}$



## AC WR(M) variable space.  (BIM)
For the SDP formulation, the norm syntax is used to represent the SOCs.


### DC lines
The variable $u^{dc}_{ii}$ represents $(U^{dc}_{i})^2$ and $u^{dc}_{ij}$ represents $U^{dc}_{i}\cdot U^{dc}_{j}$.
- Active power flow from side: $P^{dc}_{ij}$ = $p \cdot g^{series} \cdot (u^{dc}_{ii} - u^{dc}_{ij})$.
- Active power flow to side: $P^{dc}_{ji}$ = $p \cdot g^{series} \cdot (u^{dc}_{jj} - u^{dc}_{ij})$.
- Convex relaxation of voltage products: $(u^{dc}_{ij})^2 \leq u^{dc}_{ii} \cdot u^{dc}_{jj}$.


### ACDC converters
An ACDC converter model in BIM is not derived.
