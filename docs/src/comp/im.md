# Induction machine 

Induction machine model for detailed representation of electrical loads.

**Disclaimer**: This model has only been tested for the power flow problem with ACP formulation.

## Parameters

Set of parameters used to model the induction machine as defined in the input data

| name              | symb.                     | unit  | type      | default  | definition                                                           |
|-------------------|---------------------------|-------|-----------|----------|----------------------------------------------------------------------|
| index             | $im$                       | -     | Int       | -        | unique index of the induction machine                                  |
| im_bus           | $i$                       | -     | Int       | -        | unique index of the bus to which the induction machine is connected to |
| P_ag                | $P_{ag}$                   | p.u.  | Real      | -        | Starting value for active power of induction machine - positive for consumption |
| Q_ag                | $Q_{ag}$                   | p.u.  | Real      | -        |Starting value for active power of induction machine - positive for consumption |
| Pacmin              | $\underline{P_{im}}$       | p.u.  | Real      | -        | minimum stable operating power of the induction machine |
| Pacmax              | $\overline{P_{im}}$        | p.u.  | Real      | -        | maximum power rating of the induction machine |
| Pacrated              | $P_{im}$       | p.u.  | Real      | -        | minimum reactive power of the induction machine|
| status | $\delta_{im}$ | - | Int | - | Status indicator of the induction machine |
| x_m | $x_{m}$ | p.u. | Real | - | Magnetizing inductance of induction machine |
| x_sl | $x_{sl}$ | p.u. | Real | - | Stator leakage inductance of induction machine |
| x_rl | $x_{rl}$ | p.u. | Real | - | Rotor leakage inductance of induction machine |
| r_s | $r_{s}$ | p.u. | Real | - | Stator resistance of induction machine |
| r_r | $r_{r}$ | p.u. | Real | - | Rotor resistance of induction machine |
| torque | - | - | - | - | Torque model parameters of induction machine |

**Torque parameter**

The torque model is implemented as $T(\omega) = T_0 * (A*\omega^m+B \omega + C)$. This representation includes both quadratic models (m=2) or power functions (B=C=0) (see Kundur).



| Name | Symbol | Unit | Type | Default | Description |
|------|--------|------|------|---------|-------------|
| T_0 | $T_0$ | p.u. | Real | - | Per-unit torque scaling factor (base torque is approximately equal to the system base power) |
| A | $A$ | $\mathrm{s}^2/\mathrm{rad}^2$ | Real | - | Quadratic coefficient of the mechanical torque characteristic (load component typical for centrifugal devices or aerodynamic drag) |
| B | $B$ | $\mathrm{s}/\mathrm{rad}$ | Real | - | Linear coefficient of the mechanical torque characteristic (friction load component) |
| C | $C$ | - | Real | - | Constant coefficient of the mechanical torque characteristic (static load component) |
| m | $m$ | - | Real | - | Mechanical torque exponent describing the load type (see Kundur) |



## Variables

The main optimisation variables of interest are:

| name          | symb.                 | unit  | formulation                       | definition                                                                 |
|---------------|-----------------------|-------|-----------------------------------|----------------------------------------------------------------------------|  
| pg            |$P_{g}$                | p.u.  | ACP | Active power of induction machine g |
| qg            |$Q_{g}$                | p.u.  | ACP | Reactive power of induction machine g |




## Constraints

See Kundur or Van Cutsem for detailed derivation of equations. 

**Stator constrains**

```@docs
constraint_im_stator
```



**Rotor inductance constraints**

```@docs
constraint_im_rotor_inductance
```



**Magnetistation branch constraints**

```@docs
constraint_im_magnetisation
```


**Slip constraints**

```@docs
constraint_im_slip
```

