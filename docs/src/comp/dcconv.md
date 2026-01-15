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

All variables are registered via _PM.var(pm, nw) and prepared for reporting when enabled.


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


