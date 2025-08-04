# DC Generators 

DC generators are directly connected to a DC bus, in order to also model ideal voltage sources on the DC side, which can be handy for initialisation of dynamic simulation models. 

## Parameters

Set of parameters used to model DC branches as defined in the input data

| name          | symb.                     | unit  | type      | default  | definition                                                           |
|---------------|---------------------------|-------|-----------|----------|----------------------------------------------------------------------|
| index             | $dg$                       | -     | Int       | -        | unique index of the generator                                  |
| gen_bus           | $e$                       | -     | Int       | -        | unique index of the bus to which the generator is connected to |
| pgdcset           | $P^{dc}_{g,set}$                   | p.u.  | Real      | -        | reference active power generation set point - used as input in power flow calculations |
| pmin              | $\underline{P^{dc}_{g}}$       | p.u.  | Real      | -        | minimum stable operating power of the generator |
| pmax              | $\overline{P^{dc}_{g}}$        | p.u.  | Real      | -        | maximum power rating of the generator |
| gen_status        | $\delta_{dc}$             | -     | Int       | -        | status indicator of the generator |
| mbase             | $P_{base}$                | p.u.  | Real      | -        | MW base of the generator|
| vdcg              | $V^{dc}_{g}^{set}$             | p.u.  | Real      | -        | target voltage of generator - used in power flow calculations for constant and droop control modes |
| idle cost         | $c_{g,1}$                   | Currency / p.u.   | Real  | -     | Generator cost when idle in currency of your choice|
| linear cost       | $c_{g,2}$                   | Currency / p.u.   | Real  | -     | Generator cost in currency / MW(h)|
| quadratic cost    | $c_{g,3}$                   | Currency / p.u.   | Real  | -     | Generator cost in currency / (MW(h))^2|
| idle cost         | $c_{g,1}$                   | Currency / p.u.   | Real  | -     | Generator cost when idle|
| control_type      | $\kappa^{dc}_{g}$         | -                 | Int   | 2     | Used in power flow calculations, 1 = const. power, 2 = const. voltage (slack), 3 = droop |
| droop_const       | $k^{dc}_{g}$              | -                 | Real  | -     | generator active power droop in MW/V, implemented in pu (MW) / pu (kV) |


Warning: THE UNIT COMMITMENT MODEL IS NOT YET IMPLEMENTED FOR DC GENERATORS!

| name          | symb.                     | unit  | type      | default  | definition                                                           |
|---------------|---------------------------|-------|-----------|----------|----------------------------------------------------------------------|
| mut               | $mut_{g}$                 | -     | Int       | -        | minimum up time for generator used in unit commitment problems, expressed as a multiple of the UC time step |
| mdt               | $mdt_{g}$                 | -     | Int       | -        | minimum down time for generator used in unit commitment problems, expressed as a multiple of the UC time step  |
| ramp_rate         | $\Lambda_{g}$             | p.u. / time step | Real      | -        | ramp rate of the generator used in UC problem |
| ramp_rate_per_s   | $\Lambda_{g}^{s}$         | p.u. / s  | Real      | -    | ramp rate of the generator used in frequency constrained UC problem  |
| inertia_constant  | $H_{g}$                   | s     | Real      | -        | inertia constant of the generator used in frequency constrained UC problem  |
| fcr_contribution  | $\delta_{g}^{fcr}$        | -     | Int       | -        | Indicator if generator g participates in providing frequency containtment reserves |
| area              | $a_{g}$                   | -     | Int      | -        |  Area in which the generator is located, used for tie line contingencies in frequency constrained UC problem  |
| zone              | $z_{g}$                   | -     | Int      | -        | Zone in which the generator is located, used for loss of infeed contingencies in frequency constrained UC problem  |
| model             | $m_{g}$                   | -     | Int      | -        | Generator cost model, 1 = piecewise linear, 2 = polynomial (matpower style) |
| ncost             | $n_{g}$                   | -     | Int      | -        | Number of polynomial coefficients for generator costs |
| startup           | $c_{g}^{suc}$             | Currency   | Real | -       | Start-up cost in the currency of your choice|
| shutdown          | $c_{c}^{sdc}$             | Currency   | Real | -        | Shut-down cost in the currency of your choice |
| res               | $res_{g}$                 | -                 | Int   | -     |  True / false indicator for RES generators |



## Variables

Optimisation variables representing DC generator behaviour

| name          | symb.                 | unit  | formulation                       | definition                                                                 |
|---------------|-----------------------|-------|-----------------------------------|----------------------------------------------------------------------------|  
| pgdc          |$P^{dc}_{g}$           | p.u.  | ACP, ACR, LPAC, SOC, DCP, NF | Active power set point of generator g |

Not yet defined for IVR!

## Constraints

### Active power limits

```math
\begin{align}
 \underline{P^{dc}_{g}} &\leq P^{dc}_{g} \leq \overline{P^{dc}_{g}} \\
\end{align}
```

### Generator control mode: used in power flow
```math
\begin{align}

if $\kappa^{dc}_{g}$ = 1:& \\

P^{dc}_{g} &= P^{dc}_{g,set} \\

if $\kappa^{dc}_{g}$ = 2:& \\

vdc_{e} &= $V^{dc}_{g}^{set}$ \\

if $\kappa^{dc}_{g}$ = 3:& \\

P^{dc}_{g} = P^{dc}_{g,set} - 1 / k^{dc}_{g} * (vdc_{e} - $V^{dc}_{g}^{set}$)

\end{align}
```


