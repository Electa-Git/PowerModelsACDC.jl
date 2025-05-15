# Generators 

Generators present all type of generation, e.g., both classical and renewable generation

## Parameters

Set of parameters used to model DC branches as defined in the input data

| name              | symb.                     | unit  | type      | default  | definition                                                           |
|-------------------|---------------------------|-------|-----------|----------|----------------------------------------------------------------------|
| index             | $pst$                     | -     | Int       | -        | unique index of the generator                                  |
| gen_bus           | $i$                       | -     | Int       | -        | unique index of the bus to which the generator is connected to |
| pg                | $P_{g}$                   | p.u.  | Real      | -        | active power generation - used as input in power flow calculations |
| qg                | $Q_{g}$                   | p.u.  | Real      | -        | reactive power generation - used as input in power flow calculations, positive sign is an injection |
| pmin              | $\underline{P_{g}}$       | p.u.  | Real      | -        | minimum stable operating power of the generator |
| pmax              | $\overline{P_{g}}$        | p.u.  | Real      | -        | maximum power rating of the generator |
| qmin              | $\underline{Q_{g}}$       | p.u.  | Real      | -        | minimum reactive power of the generator|
| qmax              | $\overline{Q_{g}}$        | p.u.  | Real      | -        | maximum reactive power of the generator |
| gen_status        | $\delta_{dc}$             | -     | Int       | -        | status indicator of the generator |
| mbase             | $P_{base}$                | p.u.  | Real      | -        | MVA base of the generator|
| vg                | $V_{g}^{set}$             | p.u.  | Real      | -        | target voltage of generator - used in power flow calculations for PV nodes|
| mut               | $mut_{g}$                 | -     | Int       | -        | minimum up time for generator used in unit commitment problems, expressed as a multiple of the UC time step |
| mdt               | $mdt_{g}$                 | -     | Int       | -        | minimum down time for generator used in unit commitment problems, expressed as a multiple of the UC time step  |
| ramp_rate         | $\Lambda_{g}$              | p.u. / time step | Real      | -        | ramp rate of the generator used in UC problem |
| ramp_rate_per_s   | $\Lambda_{g}^{s}$          | p.u. / s  | Real      | -    | ramp rate of the generator used in frequency constrained UC problem  |
| inertia_constant  | $H_{g}$                   | s     | Real      | -        | inertia constant of the generator used in frequency constrained UC problem  |
| fcr_contribution  | $\delta_{g}^{fcr}$        | -     | Int       | -        | Indicator if generator g participates in providing frequency containtment reserves |
| area              | $a_{g}$                   | -     | Int      | -        |  Area in which the generator is located, used for tie line contingencies in frequency constrained UC problem  |
| zone              | $z_{g}$                   | -     | Int      | -        | Zone in which the generator is located, used for loss of infeed contingencies in frequency constrained UC problem  |
| model             | $m_{g}$                   | -     | Int      | -        | Generator cost model, 1 = piecewise linear, 2 = polynomial (matpower style) |
| ncost             | $n_{g}$                   | -     | Int      | -        | Number of polynomial coefficients for generator costs |
| startup           | $c_{g}^{suc}$             | Currency   | Real | -       | Start-up cost in the currency of your choice|
| shutdown          | $c_{c}^{sdc}$             | Currency   | Real | -        | Shut-down cost in the currency of your choice |
| cost              | $c_{g}$                   | Currency / p.u.   | Real  | -        | Vector with coeffcients of the polynomial cost function|
| res               | $res_{g}$                 | -     | Int       | -     |  True / false indicator for RES generators |



## Variables

Optimisation variables representing PST behaviour

| name          | symb.                 | unit  | formulation                       | definition                                                                 |
|---------------|-----------------------|-------|-----------------------------------|----------------------------------------------------------------------------|  
| pg            |$P_{g}$                | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Active power set point of generator g |
| qg            |$Q_{g}$                | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Active power set point of generator g |
| alpha_g       |$\alpha_{g}$            | -     | ACP, ACR, LPAC, IVR, SOC, DCP, NF | On / off status of generator g, binary |
| beta_g        |$\beta_{g}$             | -     | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Start-up decision for generator g, binary or continous -> setting "relax_uc_binaries" |
| gamma_g       |$\gamma_{g}$             | -     | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Shut-down decision for generator g, binary or continous -> setting "relax_uc_binaries"|
| dpg_up        |$\Delta P_{g}^{\uparrow}$ | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Upwards re-dispatch of generator g|
| dpg_down      |$\Delta P_{g}^{\downarrow}$ | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Downwards re-dispatch of generator g|
| pg_droop      |$\Delta P_{g}^{fcr}$ | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | FCR contribution of generator g|
| pg_droop_abs  |$\Delta P_{g}^{fcr,abs}$ | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Absolute value of FCR contribution of generator g|



## Constraints

### Active and reactive power limits


```math
\begin{align}
 \underline{P_{g}} &\leq P_{g} \leq \overline{P_{g}} \\
 \underline{Q_{g}} &\leq P_{g} \leq \overline{Q_{g}} \\
\end{align}
```

### Upwards and downwards redispatch limits

```math
\begin{align}
 0 &\leq \Delta P_{g}^{\uparrow} \leq \overline{P_{g}} - \underline{P_{g}}  \\
 0 &\leq \Delta P_{g}^{\downarrow}\leq \overline{P_{g}} - \underline{P_{g}} \\
\end{align}
```

### FCR provision limits

```math
\begin{align}
 -(\overline{P_{g}} - \underline{P_{g}}) \cdot \delta_{g}^{fcr}  &\leq \Delta P_{g}^{fcr} \leq (\overline{P_{g}} - \underline{P_{g}}) \cdot \delta_{g}^{fcr} \\
0 &\leq \Delta P_{g}^{fcr,abs} \leq (\overline{P_{g}} - \underline{P_{g}}) \cdot \delta_{g}^{fcr} \\
\end{align}
```

### Unit commitment constraints

```math
\begin{align}
 \underline{P_{g}} \cdot \alpha_{g,t} &\leq P_{g,t} \leq \overline{P_{g}} \cdot \alpha_{g,t} \\
 P_{g,t} - P_{g,t-1} &\leq \Lambda_{g} \alpha_{g,t} + (\underline{P_{g}} - \Lambda_{g}) \\
 P_{g,t-1} - P_{g,t} &\leq \Lambda_{g} \alpha_{g,t} + \underline{P_{g}} \cdot \gamma_{g,t} \\
 \alpha_{g,t} &\geq \sum_{t'=t+1-mut_{g}}^{t} \beta_{g,t'} \\
1-\alpha_{g,t} &\geq \sum_{t'=t+1-mdt_{g}}^{t} \gamma_{g,t'} \\
0 &=\alpha_{g,t-1} - \alpha_{g,t} + \beta_{g,t} - \gamma_{g,t} \\
\end{align}
```