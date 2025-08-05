# DC Branches 

DC Branches represent overhead lines and cables in DC connections and DC grids.

## Parameters

Set of parameters used to model DC branches as defined in the input data

| name          | symb.                     | unit  | type      | default  | definition                                                           |
|---------------|---------------------------|-------|-----------|----------|----------------------------------------------------------------------|
| index         | $d$                       | -     | Int       | -        | unique index of the DC branch                                  |
| f_bus         | $i$                       | -     | Int       | -        | unique index of the bus to which the DC branch is originating from |
| t_bus         | $j$                       | -     | Int       | -        | unique index of the bus to which the DC branch is terminating at |
| r             | $r_{dc}$                  | p.u.  | Real      | -        | resistance of the DC branch |
| l             | $l_{dc}$                  | p.u.  | Real      | -        | inductance of the DC branch (not used) |
| c             | $c_{dc}$                  | p.u.  | Real      | -        | capacitance of the DC branch (not used)|
| rateA         | $\overline{P_{dc}}$       | MW    | Real      | -        | long term rating of the DC branch |
| rateB         | $\overline{P^{st}_{dc}}$  | MW    | Real      | -        | short term term rating of the DC branch |
| rateC         | $\overline{P^{em}_{dc}}$  | MW    | Real      | -        | emergency rating of the DC branch |
| status        | $\delta_{dc}$             | -     | Int       | -        | status indicator of the DC branch |
| p             | $n_{p}$                   | -     | Int       | -        | number of DC poles, specified at test case level |
| cost          | $C_{dc}$                  | -     | Real      | -        | investment cost for DC branch used in TNEP problems  |



## Variables

Optimisation variables representing DC branch behaviour

| name          | symb.                 | unit  | formulation                       | definition                                                                 |
|---------------|-----------------------|-------|-----------------------------------|----------------------------------------------------------------------------|  
| p_dcgrid      |$P_{d,i,j}$            | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Active power flow through DC branch d, connecting DC nodes i and j |
| igrid_dc      |$I_{d,i,j}$            | p.u.  | IVR                               | Current flow through DC branch d, connecting DC nodes i and j |
| ccm_dcgrid    |$J_{d,i,j}$            | p.u.  | SOC, QC                           | Square of current flow through DC branch d, connecting DC nodes i and j |
| wdcr          |$W_{d,i,j}$            | p.u.  | SOC, QC                           | Lifted variable representing bilinear voltage product ($V_{i} \cdot V_{j}$) of branch d, connecting DC nodes i and j |

## Constraints

### Flow and angle limits

Active power, current, and voltage product limits
```math
\begin{align}
- \overline{P_{dc}} &\leq P_{d,i,j} \leq \overline{P_{dc}} \\
- \overline{I_{dc}} &\leq I_{d,i,j} \leq \overline{I_{dc}} \\
0 &\leq J_{d,i,j} \leq \overline{I_{dc}^{2}}  \\
0 &\leq W_{d,i,j} \leq max(V_{i}^{2}, V_{j}^{2})
\end{align}
```

### DC branch admittance

```math
g_{dc} = \frac{1}{r_{dc}}
```
### Ohm's law
ACP, ACR model:

```math
\begin{align}
P_{d,i,j} &= n_{p} \cdot g_{dc} \cdot V_{i} \cdot (V_{i} - V_{j}) \\
P_{d,j,i} &= n_{p} \cdot g_{dc} \cdot V_{j} \cdot (V_{j} - V_{i}) 
\end{align}
```

SOC, QC bus injection model (BIM):
```math
\begin{align}
P_{d,i,j} &= n_{p} \cdot g_{dc} \cdot (W_{i} - W_{d,i,j}) \\
P_{d,j,i} &= n_{p} \cdot g_{dc} \cdot (W_{j} - W_{d,i,j})
\end{align}
```

SOC, QC branch flow model (BFM):
```math
\begin{align}
W_{j} &= W_{i} - \frac{2 \cdot r_{dc} \cdot P_{d,i,j}} {n_{p}} + r_{dc}^{2} \cdot J_{d,i,j}  \\
P_{d,i,j} + P_{d,j,i} &= r_{dc} \cdot n_{p} \cdot J_{d,i,j} \\
P_{d,i,j}^{2} &\leq  n_{p}^{2} \cdot W_{i} \cdot   J_{d,i,j} 
\end{align}
```
IVR model:

```math
\begin{align}
V_{j} = V_{i} - \frac{r_{dc} \cdot I_{d,i,j}}{n_{p}} \\
V_{i} = V_{j} - \frac{r_{dc} \cdot I_{d,j,i}}{n_{p}} \\
P_{d,i,j} = I_{d,i,j} \cdot V_{i}  \\
P_{d,j,i} = I_{d,j,i} \cdot V_{j} 
\end{align}
```

DCP and NF model:

In this model there are no losses, as such only the active power limits are binding.


