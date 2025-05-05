# Phase shifting transformers (PSTs)

PSTs induce an equivalent voltage angle in the lines they are connected in series to by means of a voltage induction in quadrature of the line voltage, and control power flows based on that. In practise, the angle range of PSTs are given (instead of the voltage range), which is used in the power flow equations. This model is based on such PSTs.

## Parameters

Set of parameters used to model static series synchronous compenstion devices as defined in the input data

| name          | symb.                     | unit  | type      | default  | definition                                                           |
|---------------|---------------------------|-------|-----------|----------|----------------------------------------------------------------------|
| index         | $pst$                      | -     | Int       | -        | unique index of the PST                                  |
| f_bus         | $i$                       | -     | Int       | -        | unique index of the bus to which the PST is originating from |
| t_bus         | $j$                       | -     | Int       | -        | unique index of the bus to which the PST is terminating at |
| pst_r        | $r_{pst}$                | p.u.  | Real      | -        | resistance of the PST |
| pst_x        | $x_{pst}$                | p.u.  | Real      | -        | inductance of the PST |
| rate_a        | $\overline{S_{pst}}$     | MVA   | Real      | -        | long term rating of the PST |
| rate_b        | $\overline{S^{st}_{pst}}$| MVA   | Real      | -        | short term term rating of the PSt |
| rate_c        | $\overline{S^{em}_{pst}}$| MVA   | Real      | -        | emergency rating of the PST |
| angle         | $\alpha_{pst}$            | rad     | Real       | -        | current angle set point (used in power flow calculation) |
| pst_status    | $\delta_{pst}$            | -     | Int       | -        | status indicator of the PST |
| angmin      | $\underline{\alpha_{pst}}$ |rad  | Real      | -        | minimum voltage angle shift |
| angmax      | $\overline{\alpha_{pst}}$  | rad  | Real      | -        | maximum voltage angle shift |

## Variables

Optimisation variables representing PST behaviour

| name          | symb.                 | unit  | formulation     | definition                                                                  |
|---------------|-----------------------|-------|-----------------|----------------------------------------------------------------------------|                     |
| psta          |$\alpha_{pst}$         | rad   | ACP, DCP        | Equivalent phase angle shift induced by PST |
| ppst         |$p_{i,j,sc}$           | p.u.  | ACP, DCP        | Active power flow through pst |
| qpst         |$q_{i,j,sc}$           | p.u.  | ACP             | Reactive power flow through pst |

## Constraints

### Flow and angle limits

Active, reactive, and apparent power limits:
```math
\begin{align}
- \overline{S_{pst}} \leq p_{i,j,sc} \leq \overline{S_{pst}} \\
- \overline{S_{pst}} \leq q_{i,j,sc} \leq \overline{S_{pst}} \\
p_{i,j,sc}^{2} + q_{i,j,sc}^{2} \leq \overline{S_{pst}}^{2}
\end{align}
```

Range for equivalent phase angle shift:
```math
\begin{align}
\underline{\alpha_{pst}} \leq \alpha_{q} \leq \overline{\alpha_{pst}}
\end{align}
```

## Constraints

### pst admittance
```math
\begin{align}
g_{pst} = \Re{\frac{1} {r_{pst} + j \cdot x_pst}} \\
b_{pst} = \Im{\frac{1} {r_{pst} + j \cdot x_pst}} \\
\end{align}
```

### Ohm's law
ACP model:
```math
\begin{align}
p_{i,j,pst} &= g_{pst} \cdot (v_{i})^{2} - g_{pst} \cdot v_{i} \cdot v_{j} \cdot cos(\theta_{i} - \theta_{j} - \alpha_{pst}) - b_{pst} \cdot v_{i} \cdot v_{j} \cdot sin(\theta_{i} - \theta_{j} - \alpha_{pst}) \\
q_{i,j,pst} &= -b_{pst} \cdot (v_{i})^{2} + b_{pst} \cdot v_{i} \cdot v_{j} \cdot cos(\theta_{i} - \theta_{j} - \alpha_{pst}) - g_{pst} \cdot v_{i} \cdot v_{j} \cdot sin(\theta_{i} - \theta_{j} - \alpha_{pst}) \\
\end{align}
```
```math
\begin{align}
p_{j,i,pst} &= g_{pst} \cdot (v_{j})^{2} - g_{pst} \cdot v_{i} \cdot v_{j} \cdot cos(\theta_{j} - \theta_{i} + \alpha_{pst}) - b_{pst} \cdot v_{i} \cdot v_{j} \cdot sin(\theta_{j} - \theta_{i} + \alpha_{pst}) \\
q_{j,i,pst} &= -b_{pst} \cdot (v_{j})^{2} + b_{pst} \cdot v_{i} \cdot v_{j} \cdot cos(\theta_{j} - \theta_{i} + \alpha_{pst}) - g_{pst} \cdot v_{i} \cdot v_{j} \cdot sin(\theta_{j} - \theta_{i} + \alpha_{pst}) \\
\end{align}
```

ACR model:

To be derived.....

DCP model:
```math
\begin{align}
p_{i,j,pst} &= - b_{pst} \cdot (\theta_{i} - \theta_{j} - \alpha_{pst}) \\
p_{i,j,pst} + p_{j,i,pst} &= 0
\end{align}
```
