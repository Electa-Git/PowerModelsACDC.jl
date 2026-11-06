# Power Flow Controller (DC grid)

Power flow controllers (PFCs) control power flows in a DC grid by introducing controllable voltage differences between a common terminal and two output terminals. The model represents a three-terminal device with a duty cycle and an internal capacitor voltage.

The PFC model is implemented for the OPF current-voltage (IVR) formulation. The DC bus current balance constraints are extended to include the PFC currents at each of the connected terminals.

## Parameters

Set of parameters used to model PFC devices as defined in the input data.

| name           | symb.             | unit | type | default | definition |
|----------------|-------------------|------|------|---------|------------|
| index          | $pfc$               | -    | Int  | -       | Unique index of the PFC device |
| terminal1_bus  | $t_1$             | -    | Int  | -       | Unique index of the DC bus connected to the common terminal 1 |
| terminal2_bus  | $t_2$             | -    | Int  | -       | Unique index of the DC bus connected to output terminal 2 |
| terminal3_bus  | $t_3$             | -    | Int  | -       | Unique index of the DC bus connected to output terminal 3 |
| duty_cycle_min | $\underline{D_{pfc}}$ | -    | Real | 0.00    | Minimum duty cycle |
| duty_cycle_max | $\overline{D_{pfc}}$  | -    | Real | 1.00    | Maximum duty cycle |
| c_voltage_min  | $\underline{E_{pfc}}$ | kV   | Real | -       | Minimum internal capacitor voltage |
| c_voltage_max  | $\overline{E_{pfc}}$  | kV   | Real | -       | Maximum internal capacitor voltage |

## Variables

Optimisation variables representing PFC behaviour.

| name       | symb.       | unit | formulation | definition |
|------------|-------------|------|-------------|------------|
| duty_cycle | $d_{pfc}$       | -    | IVR | Duty cycle of the PFC |
| c_voltage  | $e_{pfc}$       | p.u. | IVR | Internal capacitor voltage of the PFC |
| ipfc_dc    | $I_{pfc,a,b}$ | p.u. | IVR | Directed PFC current from terminal $a$ towards terminal $b$ |

The directed terminal pairs are

```math
(a,b) \in
\left\{
(t_1,t_2),\,
(t_2,t_1),\,
(t_1,t_3),\,
(t_3,t_1)
\right\}.
```

## Constraints

The following constraints apply to each modelled PFC.

### Duty cycle limits

The duty cycle is bounded by:

```math
\underline{D_{pfc}}
\leq d_{pfc}
\leq \overline{D_{pfc}}
```

### Internal capacitor voltage limits

The internal capacitor voltage is bounded by the input parameters:

```math
\underline{E_{pfc}}
\leq e_{pfc}
\leq \overline{E_{pfc}}
```

### Terminal voltage relationships

The voltage difference between the common terminal 1 and terminal 2 is determined by the duty cycle and capacitor voltage:

```math
U^{dc}_{t_1} - U^{dc}_{t_2} - d_{pfc} \cdot e_{pfc} = 0
```

The voltage difference between the common terminal 1 and terminal 3 is given by

```math
U^{dc}_{t_1} - U^{dc}_{t_3} + (1-d_{pfc})\cdot e_{pfc} = 0
```

### Energy balance constraints

The PFC is modelled as a lossless device, the resulting equation linking both currents is determined by:

```math
e_{pfc}
\left[
(1-d_{pfc}) \cdot I_{pfc,t_3t_1}
-
d_{pfc} \cdot I_{pfc,t_2t_1}
\right]
= 0
```

### Current balance constraints

The directed currents associated with each terminal pair are equal in magnitude and opposite in sign:

```math
\begin{aligned}
I_{pfc,t_1t_2} + I_{pfc,t_2t_1} &= 0 \\
I_{pfc,t_1t_3} + I_{pfc,t_3t_1} &= 0
\end{aligned}
```