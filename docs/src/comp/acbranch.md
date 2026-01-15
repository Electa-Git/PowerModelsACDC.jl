# AC Branches 

AC Branches represent overhead lines, transformers and underground cables within AC grids.

## Parameters

Set of parameters used to model DC branches as defined in the input data

| name              | symb.                     | unit  | type      | default  | definition                                                           |
|-------------------|---------------------------|-------|-----------|----------|----------------------------------------------------------------------|
| index             | $b$                       | -     | Int       | -        | unique index of the AC branch                                  |
| f_bus             | $i$                       | -     | Int       | -        | unique index of the bus to which the AC branch is originating from |
| t_bus             | $j$                       | -     | Int       | -        | unique index of the bus to which the AC branch is terminating at |
| r                 | $r_{ac}$                  | p.u.  | Real      | -        | resistance of the AC branch |
| l                 | $l_{ac}$                  | p.u.  | Real      | -        | inductance of the AC branch |
| c                 | $c_{ac}$                  | p.u.  | Real      | -        | capacitance of the AC branch|
| rateA             | $\overline{S_{b}}$       | MW    | Real      | -        | long term rating of the AC branch |
| rateB             | $\overline{S^{st}_{b}}$  | MW    | Real      | -        | short term term rating of the AC branch |
| rateC             | $\overline{S^{em}_{b}}$  | MW    | Real      | -        | emergency rating of the AC branch |
| status            | $\delta_{b}$             | -     | Int       | -        | status indicator of the AC branch |
| tap               | $\tau$                    | -     | Real      | -        | tap ratio of potential transformer tap |
| shift             | $\varphi$                 | -     | Real      | -        | phase shift induced by PST if modelled as a fixed element |
| angmin            | $\underline{\theta}$      | -     | Real      | -        | minimum allowable phase angle difference over AC branch |
| angmax            | $\overline{\theta}$       | -     | Real      | -        | maximum allowable phase angle difference over AC branch |
| construction_cost | $C_{ac}$                  | -     | Real      | -        | investment cost for AC branch used in TNEP problems  |



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



## Constraints

### Flow and voltage angle limits

```math
\begin{align}
- \overline{S_{b}} &\leq P_{d,i,j} \leq \overline{S_{b}} \\
- \overline{S_{b}} &\leq Q_{d,i,j} \leq \overline{S_{b}} \\
\sqrt{(P_{d,i,j})^2 +(Q_{d,i,j})^2 } &\leq \overline{S_{b}} \\
0 &\leq I_{b,i,j} \leq \overline{I_{b}}  \\
0 &\leq W_{b,i,j} \leq max(V_{i}^{2}, V_{j}^{2})
\end{align}
```

### Ohm's law
**ACP model**: consult power models for full implementation

```math
\begin{align}
p_{b,i,j} &= g_{b} \cdot (v_{i})^{2} - g_{b} \cdot v_{i} \cdot v_{j} \cdot cos(\theta_{i} - \theta_{j} ) - b_{b} \cdot v_{i} \cdot v_{j} \cdot sin(\theta_{i} - \theta_{j})\\
q_{b,i,j} &= -b_{b} \cdot (v_{i})^{2} + b_{b} \cdot v_{i} \cdot v_{j} \cdot cos(\theta_{i} - \theta_{j} ) - g_{b} \cdot v_{i} \cdot v_{j} \cdot sin(\theta_{i} - \theta_{j}) \\
p_{b,j,i} &= g_{b} \cdot (v_{j})^{2} - g_{b} \cdot v_{i} \cdot v_{j} \cdot cos(\theta_{j} - \theta_{i} ) - b_{b} \cdot v_{i} \cdot v_{j} \cdot sin(\theta_{j} - \theta_{i}) \\
q_{b,j,i} &= -b_{b} \cdot (v_{j})^{2} + b_{b} \cdot v_{i} \cdot v_{j} \cdot cos(\theta_{j} - \theta_{i} ) - g_{b} \cdot v_{i} \cdot v_{j} \cdot sin(\theta_{j} - \theta_{i}) \\
\end{align}
```

**ACR model**: consult power models for full implementation

```math
\begin{align}
p_{b,i,j} &= (g_{b}+g_{b,fr}) \cdot (\Re(v_{i})^2 + \Im(v_{i})^2) + (-g_{b} + b_{b}) \cdot (\Re(v_{i})\Re(v_{j}) + \Im(_{i})\Im(v_{j})) + (-g_{b} - b_{b}) \cdot (\Im(v_{i})\Re(v_{j}) - \Re(v_{i})\Im(v_{j}))  \\
q_{b,i,j} &= -(b_{b}+b_{b,fr}) \cdot (\Re(v_{i})^2 + \Im(v_{i})^2) - (-g_{b} - b_{b}) \cdot (\Re(v_{i})\Re(v_{j}) + \Im(_{i})\Im(v_{j})) + (-g_{b} + b_{b}) \cdot (\Im(v_{i})\Re(v_{j}) - \Re(v_{i})\Im(v_{j}))  \\
p_{b,j,i} &= (g_{b}+g_{b,to}) \cdot (\Re(v_{j})^2 + \Im(v_{j})^2) + (-g_{b} + b_{b}) \cdot (\Re(v_{i})\Re(v_{j}) + \Im(_{i})\Im(v_{j})) + (-g_{b} - b_{b}) \cdot (-(\Im(v_{i})\Re(v_{j}) - \Re(v_{i})\Im(v_{j})))  \\
q_{b,j,i} &= -(b_{b}+b_{b,to}) \cdot (\Re(v_{j})^2 + \Im(v_{j})^2) - (-g_{b} - b_{b}) \cdot (\Re(v_{i})\Re(v_{j}) + \Im(_{i})\Im(v_{j})) + (-g_{b} + b_{b}) \cdot (-(\Im(v_{i})\Re(v_{j}) - \Re(v_{i})\Im(v_{j})))  \\
\end{align}
```

**IVR model**: models the current flow explicitely, using a series current $c_{b}^{s}$ and a shunt current $c_{b}^{sh}$

Liniking powee flow to voltage and current:
```math
\begin{align}
p_{b,i,j} &= \Re(v_{i}) \cdot \Re(i_{b,i,j}) + \Im(v_{i}) \cdot \Im(i_{b,i,j})  \\
q_{b,i,j} &= \Im(v_{i}) \cdot \Re(i_{b,i,j}) - \Re(v_{i}) \cdot \Im(i_{b,i,j})  \\
p_{b,j,i} &= \Re(v_{j}) \cdot \Re(i_{b,j,i}) + \Im(v_{j}) \cdot \Im(i_{b,j,i})  \\
q_{b,j,i} &= \Im(v_{j}) \cdot \Re(i_{b,j,i}) - \Re(v_{j}) \cdot \Im(i_{b,j,i})  \\
\end{align}
```

Linking series and shunt currents:
```math
\begin{align}
\Re(i_{b,i,j}) &=  \Re(i^{s}_{b,i,j}) + g_{b,fr}  \cdot \Re(v_{i}) - b_{b,fr} \cdot \Im(v_{i}) \\
\Im(i_{b,i,j}) &=  \Im(i^{s}_{b,i,j}) + g_{b,fr}  \cdot \Im(v_{i}) - b_{b,fr} \cdot \Re(v_{i})  \\
\Re(i_{b,j,i}) &=  \Re(i^{s}_{b,j,i}) + g_{b,to}  \cdot \Re(v_{j}) - b_{b,to} \cdot \Im(v_{j}) \\
\Im(i_{b,j,i}) &=  \Im(i^{s}_{b,j,i}) + g_{b,to}  \cdot \Im(v_{j}) - b_{b,to} \cdot \Re(v_{j}) \\
\end{align}
```
Voltage drop:
```math
\begin{align}
\Re(v_{j}) &=  \Re(v_{i}) - r_{b} \cdot \Re(i^{s}_{b,i,j}) + x_{b} \cdot \Im(i^{s}_{b,i,j}) \\
\Im(v_{j}) &=  \Im(v_{i}) - r_{b} \cdot \Im(i^{s}_{b,i,j}) - x_{b} \cdot \Re(i^{s}_{b,i,j}) \\
\end{align}
```

**SOC, QC bus injection model (BIM)**:
#todo

**SOC, QC branch flow model (BFM)**:
#todo

**DCP model**:
```math
\begin{align}
    p_{b,i,j} &= -b_{b} \cdot(\theta{i} - \theta{j}) \\
    p_{b,j,i} &= -b_{b} \cdot(\theta{j} - \theta{i}) \\
\end{align}
```

**NF model**: In this model there are no losses, no impedances, as such only the active power limits are binding.


