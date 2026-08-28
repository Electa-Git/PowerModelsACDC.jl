# DC Converter Stations

DC converter stations connect an AC bus i with a DC bus d. A converter station model in PowerModelsACDC includes:
- a station transformer,
- a harmonic filter (capacitive bank + series phase inductor),
- the power-electronic converter (VSC or LCC variants),
- auxiliary device models (reactor, transformer leakage, control blocks).

See diagram: [Converter](../images/converter.pdf)

## Overview

Converters provide an interface between AC and DC systems and can:
- exchange active power between AC and DC sides,
- absorb/generate reactive power on the AC side (VSC),
- enforce DC-side voltage/flow setpoints,
- contribute to system frequency response via droop or synthetic inertia (VSC/HVDC controls),
- be modeled with losses, current limits and device-specific constraints (firing angle for LCC).

The documentation below lists the standard model parameters, optimisation variables and the main constraints implemented in the package. See companion component docs (AC branches, DC branches, converters) for related primitives.

## Converter Models and Equations

Two principal converter formulations are supported:

1. VSC (Voltage-Source Converter)
   - Behaviour: controllable AC active and reactive power at the AC terminal; DC-side power is matched with AC-side power minus losses.
   - Key relations:
     - AC/DC power balance:
       pconv_dc = pconv_ac - Ploss(pconv_ac)
     - Reactive capability constraint (if modeled):
       -Q_rated ≤ qconv_ac ≤ Q_rated
     - Current limit (thermal constraint):
       i_conv^2 ≥ (pconv_ac^2 + qconv_ac^2) / v_ac^2 (or equivalent on DC side)
     - Droop / FCR participation:
       pg_droop and pconv_in variables are linked through droop law constraints if droop/HVDC inertia is enabled.

2. LCC (Line-Commutated Converter) — islcc == 1
   - Behaviour: firing-angle controlled; active power related to firing angle and DC voltage.
   - Typical relations (simplified representation used in optimization):
     - pconv_ac approximated as function of firing angle α and DC quantities (nonlinear). In practice PowerModelsACDC implements a linearised or constrained surrogate:
       pconv_ac = f(α, v_ac, v_dc)  (implemented via heuristic constraints or convex relaxations)
     - Firing-angle constraints:
       α_min ≤ α ≤ α_max
     - When converter outage is enforced, α and powers are forced to zero.

Loss modelling:
- Polynomial loss model (if coefficients provided): Ploss(P) = a P^2 + b P + c
- Alternatively, fixed efficiency ηconv may be used: pconv_dc = ηconv * pconv_ac
- Loss proxies and linearisations are used where necessary to keep the problem tractable (linear/quadratic/conic relaxations depending on backend).

## Converter Constraints (implemented primitives)

The package exposes and applies a consistent set of converter constraints. The key constraints commonly added by builder functions include:

- constraint_converter_losses(pm, i; nw)
  - Enforces the relationship between AC- and DC-side active powers and the chosen loss model (polynomial or efficiency).
  - For polynomial losses: p_dc + Ploss(p_ac) == p_ac (sign conventions applied).
  - For efficiency: p_dc == ηconv * p_ac.

- constraint_converter_current(pm, i; nw)
  - Enforces current-based thermal limits. Depending on backend:
    - For full AC models: I_conv^2 ≥ (pconv_ac^2 + qconv_ac^2)/V_ac^2 (or equivalent)
    - For DC-side aggregation: use ccm_dcgrid variables or dedicated current proxies.
  - Applies Imax bound: 0 ≤ I_conv ≤ Imax.

- constraint_conv_transformer(pm, i; nw)
  - Models the station transformer tap/shifts and limits if present. Ensures voltage/angle linking between AC bus and converter internal node.

- constraint_conv_reactor(pm, i; nw)
  - Models series reactor behaviour (used in filtering and LCC smoothing). Connects converter internal node to DC filter/reactor variables.

- constraint_conv_filter(pm, i; nw)
  - Enforces the effect of harmonic filter capacitance and series inductance on the AC terminal current/voltage balance.

- constraint_conv_firing_angle(pm, i; nw)
  - LCC-specific constraint that imposes bounds on firing angle and (where linearised) connects α to active power setpoints.
  - Applied only when islcc == 1 for converter i.

- constraint_active_conv_setpoint(pm, i; nw, slack = 0.01)
  - Optional helper that fixes (or tightly bounds) the active setpoint of converters (used for debugging or warm-starts).

- constraint_converter_contingencies / constraint_converter_outage
  - Used in SCOPF/FCUC contingency stages to force converter behaviour during an outage (e.g., set pconv_ac == 0, disable α for LCC, zero flows, etc.).

## Frequency / HVDC contributions

When frequency-security modelling is enabled, converters may be allowed to:
- provide a transient FFR contribution (fast frequency response) or droop-based FCR,
- contribute synthetic inertia approximations scaled by converter capability and time-constants t_hvdc.

Variables and constraints used:
- variable_hvdc_contribution: creates Δpconv (pconv_in) and absolute proxies used in frequency inequalities.
- calculate_hvdc_ffr_contribution, calculate_hvdc_fcr_contribution: helper expressions used in frequency nadir / settling inequalities.

Time-constant based approximation:
- Converter FFR contribution often modelled as pconv_in * min(1, ΔT/t_hvdc) × shape-factor (see calculate_hvdc_ffr_contribution).

## Contingency handling

Converters are integrated into contingency primitives:
- During contingency stages the package can enforce converter outages, re-allocate droop variables and re-evaluate DC-side balance using auxiliary DC voltages (vdcm_star).
- Variables such as pconv_ac (reference stage) are linked to contingency stage variables via big-M indicator constraints and selection binaries for contingency selection.

## Implementation notes & backend differences

- Many converter constraints are implemented with different relaxations depending on the optimization backend (AC polar/cartesian, IVR, BFQP, BFConic, SOC/QC relaxations).
- LCC firing-angle nonlinearities are commonly linearised or represented by convex relaxations to keep problems tractable. The exact formulation depends on the builder and active ref_extensions.
- TNEP / candidate converters use "ne" variants of variables and constraints (e.g., :convdc_ne, constraint_conv_transformer_ne, constraint_conv_firing_angle_ne) to support on/off linking with candidate indicator variables.

## Examples

- Typical VSC modelling (steady-state dispatch):
  - set pconv_ac as variable, qconv_ac variable, enforce converter losses and current limits, allow qconv_ac to be used for voltage support.

- LCC modelling (HVDC bulk link):
  - set islcc==1 for converter entries, use constraint_conv_firing_angle to limit α and link to pconv_ac, include station transformer and reactor constraints.

## See also

- docs/src/comp/ (other component descriptions: acbranch.md, branchdc.md, pst.md, sssc.md)
- images/converter.pdf — schematic diagram used throughout the docs
- source code primitives in src/components/ and src/formdcgrid/ for exact mathematical forms used by each modeling backend.

## Parameters

Common per-converter input parameters (data file keys and typical semantics):

| name | symbol | unit | type | default | description |
|------|--------|------|------|---------|-------------|
| index | c | - | Int | - | unique converter id |
| ac_bus | i | - | Int | - | connected AC bus index |
| dc_bus | d | - | Int | - | connected DC bus index |
| Pacrated | P_rated | MW | Real | - | rated AC active power capability |
| Qrated | Q_rated | MVAr | Real | - | rated reactive power capability (VSC only) |
| islcc | islcc | {0,1} | Int | 0 | 1 if LCC converter model (firing-angle representation), 0 for VSC |
| ηconv | eta | - | Real | 1.0 | converter efficiency (optional) |
| Ploss_coeff | a,b,c | MW | Real vec | [0,0,0] | loss polynomial coefficients (a*P^2 + b*P + c) |
| Imax | Imax | A (p.u.) | Real | - | maximum AC (or DC) current magnitude |
| Pac_min | Pmin | MW | Real | -P_rated | minimum controllable AC power |
| Pac_max | Pmax | MW | Real | P_rated | maximum controllable AC power |
| droop_enabled | bool | - | Bool | false | enable droop/FCR contribution modeling |
| t_hvdc | tau | s | Real | - | HVDC time-constant for FFR/FCR modelling (for HVDC contribution) |
| firing_angle_limits | [α_min, α_max] | deg | Real vec | [-π/2, 0] | limits for LCC firing angle (if islcc==1) |
| status | δ | {0,1} | Int | 1 | converter online indicator |

Notes:
- Additional per-converter keys may appear depending on the reference extensions (e.g., droop parameters, control-mode flags, DC filter/reactor values). Consult the input data for your case.

## Variables

Major optimisation variables created per converter:

| variable name | symbol | domain | purpose |
|---------------|--------|--------|---------|
| pconv_ac | P_conv | ℝ | AC-side active power of converter (positive from AC->DC or as signed convention used in data) |
| qconv_ac | Q_conv | ℝ | AC-side reactive power (VSC only) |
| pconv_dc | P_dc | ℝ | DC-side signed power variable (linked to pconv_ac through loss relation or efficiency) |
| i_conv | I_conv | ℝ≥0 | AC (or DC) current magnitude (for thermal limits) |
| alpha_conv | α (or firing_angle) | ℝ | firing angle variable (LCC only) |
| conv_on | z_conv | {0,1} | on/off indicator for candidate or outage modelling |
| rd_conv | rdc | ℝ | converter droop coefficient (if droop optimization enabled) |
| pconv_in / pconv_in_abs | Δpconv, |ℝ / ℝ≥0| HVDC frequency-response change and its absolute proxy |

Auxiliary variables (per converter / per-zone) used in frequency/security models:
- zone-aggregated converter contributions, absolute-value proxies for reserve sizing, converter auxiliary DC voltage variables for contingency stages.

All variables are registered via PowerModels.var(pm, nw) and prepared for reporting when enabled.


## Variables

Optimisation variables representing AC Branch behaviour

| name          | symb.                 | unit  | formulation                       | definition                                                                 |
|---------------|-----------------------|-------|-----------------------------------|----------------------------------------------------------------------------|
| p             |$p_{b,i,j}$            | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Active power flow through AC branch b, connecting AC nodes i and j |
| q             |$q_{b,i,j}$            | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Reactive power flow through AC branch b, connecting AC nodes i and j |
| cr            |$\Re(i_{b,i,j})$       | p.u.  | IVR | Real current flow through AC branch b, connecting AC nodes i and j |
| ci            |$\Im(i_{b,i,j})$       | p.u.  | IVR | Imaginary current flow through AC branch b, connecting AC nodes i and j |
| csr            |$\Re(i^{s}_{b,i,j})$       | p.u.  | IVR| Real current series flow through AC branch b, connecting AC nodes i and j |
| csi            |$\Im(i^{s}_{b,i,j})$       | p.u.  | IVR | Imaginary series current flow through AC branch b, connecting AC nodes i and j |
| cshr_fr            |$\Re(i^{sh}_{b,i})$       | p.u.  | IVR | Real shunt current of AC branch b, at node i |
| cshi_fr            |$\Im(i^{sh}_{b,i})$       | p.u.  | IVR | Imaginary shunt current of AC branch b, at node i|
| cshr_to            |$\Re(i^{sh}_{b,j})$       | p.u.  | IVR | Real shunt current of AC branch b, at node j |
| cshi_to            |$\Im(i^{sh}_{b,j})$       | p.u.  | IVR | Imaginary shunt current of AC branch b, at node j|



**NF model**: In this model there are no losses, no impedances, as such only the active power limits are binding.



# AC/DC converter constraints

This section documents the steady-state AC/DC converter constraints used in PowerModelsACDC. The converter is modelled as the interface between one AC bus and one DC bus, with optional transformer, filter, phase reactor and converter loss model. The constraints below use the variables and parameters introduced in the variables and parser documentation.

The notation follows the rest of the formulation documentation:

- `i` denotes the AC bus connected to converter `c`.
- `j` denotes the DC bus connected to converter `c`.
- $P^{conv,ac}_c,Q^{conv,ac}_c$ are the active and reactive power injections at the AC side of the converter.
- $P^{conv,dc}_c$ is the active power injection at the DC side of the converter.
- $a_c,b_c,c_c$ are the constant, linear-current and quadratic-current converter loss coefficients.
- $I^{conv}_c$ is the converter AC current magnitude and $i^{conv,sq}_c$ is its square.
- $U_i$ is the AC voltage magnitude, $W_i=U_i^2$ is the lifted squared-voltage variable, and $U^{dc}_j$ or $W^{dc}_j$ denote analogous DC voltage variables.

!!! note
    Sign conventions follow the PowerModelsACDC implementation: converter AC and DC powers are injections into their respective AC/DC network equations. The loss balance is therefore written as the sum of AC-side and DC-side converter powers being equal to converter losses.

## Constraints used by AC/DC OPF

The AC/DC OPF model calls the following converter constraint groups for each converter:

- converter loss balance;
- converter AC-current relation;
- optional transformer equations;
- optional phase-reactor equations;
- optional filter equations;
- LCC firing-angle equations when `islcc == 1`.

The mathematical form of these constraints depends on the selected power-flow formulation.

## Common converter loss model

For all non-linear and convexified converter formulations, converter losses are represented by

```math
P^{conv,ac}_c + P^{conv,dc}_c = P^{loss}_c,
```

with

```math
P^{loss}_c = a_c + b_c I^{conv}_c + c_c \left(I^{conv}_c\right)^2.
```

When both current magnitude and squared-current variables are present, the loss model is written as

```math
P^{conv,ac}_c + P^{conv,dc}_c
= a_c + b_c I^{conv}_c + c_c i^{conv,sq}_c.
```

The coefficients are normally non-negative:

```math
a_c \geq 0, \qquad b_c \geq 0, \qquad c_c \geq 0.
```

## ACPPowerModel

In the polar AC formulation, the AC bus voltage magnitude is represented by $U_i$. The converter current relation is non-linear and non-convex:

```math
\left(P^{conv,ac}_c\right)^2 + \left(Q^{conv,ac}_c\right)^2 = U_i^2 \left(I^{conv}_c\right)^2.
```

The converter loss balance is

```math
P^{conv,ac}_c + P^{conv,dc}_c
= a_c + b_c I^{conv}_c + c_c \left(I^{conv}_c\right)^2.
```

If the converter is an LCC converter, active and reactive power are linked by the converter firing-angle or power-factor relation:

```math
P^{conv,ac}_c = \cos(\varphi_c) S^{conv,rated}_c,
```

```math
Q^{conv,ac}_c = \sin(\varphi_c) S^{conv,rated}_c.
```

## ACRPowerModel

In the rectangular AC formulation, the AC bus voltage is represented by real and imaginary parts $U^{r}_i$ and $U^{i}_i$. The squared voltage magnitude is

```math
U_i^2 = \left(U^{r}_i\right)^2 + \left(U^{i}_i\right)^2.
```

The converter current relation becomes

```math
\left(P^{conv,ac}_c
\right)^2 + \left(Q^{conv,ac}_c
\right)^2
= \left(\left(U^{r}_i
\right)^2 + \left(U^{i}_i
\right)^2
\right) i^{conv,sq}_c.
```

The link between the current magnitude and squared-current variable is

```math
\left(I^{conv}_c
\right)^2 = i^{conv,sq}_c.
```

The loss balance is

```math
P^{conv,ac}_c + P^{conv,dc}_c
= a_c + b_c I^{conv}_c + c_c i^{conv,sq}_c.
```

The LCC firing-angle relation is the same as in the polar formulation.

## IVRPowerModel

In the current-voltage rectangular formulation, converter currents may be represented explicitly by real and imaginary current components. Let $I^{r,conv}_c$ and $I^{i,conv}_c$ denote the converter current components at the AC side. Then

```math
i^{conv,sq}_c = \left(I^{r,conv}_c
\right)^2 + \left(I^{i,conv}_c
\right)^2.
```

The AC-side converter power is linked to voltage and current by

```math
P^{conv,ac}_c = U^r_i I^{r,conv}_c + U^i_i I^{i,conv}_c,
```

```math
Q^{conv,ac}_c = U^i_i I^{r,conv}_c - U^r_i I^{i,conv}_c.
```

The loss balance is

```math
P^{conv,ac}_c + P^{conv,dc}_c
= a_c + b_c I^{conv}_c + c_c i^{conv,sq}_c,
```

with the current-magnitude link

```math
\left(I^{conv}_c
\right)^2 = i^{conv,sq}_c.
```

## SOCWRPowerModel, SDPWRMPowerModel, QCRMPowerModel and QCLSPowerModel

The WR-space relaxations use lifted voltage variables. Let $W_i$ denote the squared voltage magnitude at the AC bus. The non-convex converter current relation is relaxed as

```math
\left(P^{conv,ac}_c
\right)^2 + \left(Q^{conv,ac}_c
\right)^2
\leq W_i i^{conv,sq}_c.
```

Equivalently, this can be represented by a rotated second-order cone:

```math
\left| \begin{bmatrix}
2P^{conv,ac}_c \\
2Q^{conv,ac}_c \\
W_i - i^{conv,sq}_c
\end{bmatrix}
\right|_2
\leq W_i + i^{conv,sq}_c.
```

The current-magnitude link is convexified as

```math
\left(I^{conv}_c
\right)^2 \leq i^{conv,sq}_c.
```

The converter loss balance remains

```math
P^{conv,ac}_c + P^{conv,dc}_c
= a_c + b_c I^{conv}_c + c_c i^{conv,sq}_c.
```

For QC-type formulations, the bilinear and quadratic expressions in the current relation are additionally tightened by the corresponding QC envelopes used for the AC network model. The converter loss balance itself is unchanged.

## DCPPowerModel

In the DC approximation, AC voltage magnitudes are fixed to one per unit and reactive power equations are omitted:

```math
U_i = 1.
```

The active-power-only converter current approximation is

```math
I^{conv}_c \approx \left|P^{conv,ac}_c
\right|.
```

When losses are represented, the active-power loss balance is

```math
P^{conv,ac}_c + P^{conv,dc}_c
= a_c + b_c I^{conv}_c + c_c i^{conv,sq}_c,
```

with

```math
i^{conv,sq}_c \approx \left(P^{conv,ac}_c
\right)^2.
```

When the lossless DC approximation is used, this reduces to

```math
P^{conv,ac}_c + P^{conv,dc}_c = 0.
```

## LPACCPowerModel

The LPAC formulations use a linearized voltage magnitude representation. If $\phi_i$ denotes the voltage magnitude deviation around $1.0$ p.u., then

```math
U_i \approx 1 + \phi_i,
```

and

```math
U_i^2 \approx 1 + 2\phi_i.
```

The converter current relation is linearized around the flat-voltage operating point. For the active-power-dominated approximation,

```math
I^{conv}_c \approx \left|P^{conv,ac}_c
\right|,
```

or, when an auxiliary non-negative current variable is used,

```math
I^{conv}_c \geq P^{conv,ac}_c,
```

```math
I^{conv}_c \geq -P^{conv,ac}_c.
```

The linearized converter loss balance is

```math
P^{conv,ac}_c + P^{conv,dc}_c = a_c + b_c I^{conv}_c,
```

or, if the quadratic-loss term is retained through an auxiliary squared-current variable,

```math
P^{conv,ac}_c + P^{conv,dc}_c
= a_c + b_c I^{conv}_c + c_c i^{conv,sq}_c.
```

## Transformer, reactor and filter constraints

The converter station may contain a transformer, filter and phase reactor. These elements are modelled on the AC side of the converter and are switched off by setting the corresponding impedance or susceptance to zero.

### Transformer

The transformer links the AC grid bus voltage to the filter-side voltage. Its active and reactive power equations follow the same AC branch equations as the underlying AC formulation, using the transformer admittance and tap ratio:

```math
(P^{tf,fr}_c,Q^{tf,fr}_c,P^{tf,to}_c,Q^{tf,to}_c)
= f^{tf}\left(V^{grid}_i,V^{filt}_c,y^{tf}_c,t^{tf}_c
\right).
```

In ACP this is the polar AC branch equation, in ACR/IVR it is the rectangular AC branch equation, and in WR/QC formulations it is the corresponding lifted or relaxed branch equation.

### Filter

The shunt filter consumes or injects reactive power proportional to the local voltage-squared term:

```math
P^{filter}_c = 0,
```

```math
Q^{filter}_c = - b^{filter}_c U_{filt,c}^2.
```

In WR formulations, $U_{filt,c}^2$ is replaced by the corresponding lifted voltage variable $W_{filt,c}$; in LPAC it is replaced by the linearized squared voltage $1+2\phi_{filt,c}$.

### Phase reactor

The phase reactor links the filter-side voltage to the converter-side AC voltage. Its active and reactive power equations again follow the AC branch equations of the selected formulation:

```math
(P^{pr,fr}_c,Q^{pr,fr}_c,P^{pr,to}_c,Q^{pr,to}_c)
= f^{pr}\left(V^{filt}_c,V^{conv}_c,y^{pr}_c
\right).
```

## Summary by formulation

| Formulation | Voltage representation | Converter current relation | Loss model |
| --- | --- | --- | --- |
| `ACPPowerModel` | $U_i,	heta_i$ | $(P^{ac})^2+(Q^{ac})^2 = U_i^2 I^2$ | $P^{ac}+P^{dc}=a+bI+cI^2$ |
| `ACRPowerModel` | $U^r_i,U^i_i$ | $(P^{ac})^2+(Q^{ac})^2=((U^r_i)^2+(U^i_i)^2)i^{sq}$ | $P^{ac}+P^{dc}=a+bI+ci^{sq}$ |
| `IVRPowerModel` | $U^r_i,U^i_i$ and current components | $P,Q$ linked directly to voltage and current components | $P^{ac}+P^{dc}=a+bI+ci^{sq}$ |
| `SOCWRPowerModel` | $W_i$ | $(P^{ac})^2+(Q^{ac})^2 \leq W_i i^{sq}$ | $P^{ac}+P^{dc}=a+bI+ci^{sq}$ |
| `SDPWRMPowerModel` | voltage matrix variables | lifted relaxation of current relation | $P^{ac}+P^{dc}=a+bI+ci^{sq}$ |
| `QCLSPowerModel` / `QCRMPowerModel` | lifted voltage variables with QC envelopes | QC relaxation of current relation | $P^{ac}+P^{dc}=a+bI+ci^{sq}$ |
| `DCPPowerModel` | $U_i=1$ | active-power-only approximation | $P^{ac}+P^{dc}=0$ or linearized losses |
| `LPACCPowerModel` | $U_i \approx 1+\phi_i$ | linearized active-power-dominated current | linearized losses |

## References

The converter loss model, formulation hierarchy, and convex/linearized converter models are based on:

H. Ergun, J. Dave, D. Van Hertem and F. Geth, "Optimal Power Flow for AC/DC Grids: Formulation, Convex Relaxation, Linear Approximation and Implementation," IEEE Transactions on Power Systems, DOI: 10.1109/TPWRS.2019.2897835.



