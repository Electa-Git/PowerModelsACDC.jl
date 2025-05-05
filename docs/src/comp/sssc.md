# Static series synchronous compenstion devices, e.g. smart wires$

The series compensation devices inject a voltage in quadrature of the line voltage in order to control active and reactive power flows.

## Parameters

Set of parameters used to model static series synchronous compenstion devices as defined in the input data

| name          | symb.                     | unit  | type      | default  | definition                                                           |
|---------------|---------------------------|-------|-----------|----------|----------------------------------------------------------------------|
| index         | $sc$                      | -     | Int       | -        | unique index of the sereies compensator                                  |
| f_bus         | $i$                       | -     | Int       | -        | unique index of the bus to which the series compensator is originating from |
| t_bus         | $j$                       | -     | Int       | -        | unique index of the bus to which the series compensator is terminating at |
| sssc_r        | $r_{sssc}$                | p.u.  | Real      | -        | resistance of the series compensator |
| sssc_x        | $x_{sssc}$                | p.u.  | Real      | -        | inductance of the series compensator |
| rate_a        | $\overline{S_{sssc}}$     | MVA   | Real      | -        | long term rating of series compensator |
| rate_b        | $\overline{S^{st}_{sssc}}$| MVA   | Real      | -        | short term term rating of series compensator |
| rate_c        | $\overline{S^{em}_{sssc}}$| MVA   | Real      | -        | emergency rating of series compensator |
| sssc_status   | $\alpha_{sssc}$           | -     | Int       | -        | status indicator of series compensator |
| vqmin         | $\underline{v_{q}}$       | p.u.  | Real      | -        | minimum quadrature voltage |
| vqmax         | $\overline{v_{q}}$        | p.u.  | Real      | -        | maximum quadrature voltage |

## Variables

Optimisation variables representing SSSC behaviour

| name          | symb.                 | unit  | formulation     | definition                                                                  |
|---------------|-----------------------|-------|-----------------|----------------------------------------------------------------------------|
| vqsssc        |$v_{q}$                | p.u.  | ACP,  ACR      | Voltage injected in quadrature                      |
| alphaqsssc    |$\alpha_{q}$           | rad   | DCP             | Equivalent phase angle shift induced by SSSC |
| psssc         |$p_{i,j,sc}$           | p.u.  | ACP, ACR,  DCP | Active power flow through SSSC |
| qsssc         |$q_{i,j,sc}$           | p.u.  | ACP, ACR      | Reactive power flow through SSSC |

## Constraints

### Flow, voltage, angle limits

Active, reactive, and apparent power limits:
```math
\begin{align}
- \underline{S_{sssc}} \leq p_{i,j,sc} \leq \overline{S_{sssc}} \\
- \underline{S_{sssc}} \leq q_{i,j,sc} \leq \overline{S_{sssc}} \\
p_{i,j,sc}^{2} + q_{i,j,sc}^{2} \leq \overline{S^{st}_{sssc}}^{2}
\end{align}
```

Voltage range for the induced quadrature voltage:
```math
\begin{align}
\underline{v_{q}} \leq v_{q} \leq \overline{v_{q}}
\end{align}
```

Range for equivalent phase angle shift:
```math
\begin{align}
-atan(\underline{v_{q}}) \leq \alpha_{q} \leq atan(\overline{v_{q}})
\end{align}
```

## Constraints

### Ohm's law:
ACP model:

ACR model:

DCP model:
```math
\begin{align}
b_{sssc} = \Im{\frac{1} {r_{sssc} + j \cdot x_sssc}} \\
p_{i,j,sc} = - b_{sssc} \cdot (\theta_{i} - \theta_{j} - \alpha_{q})
\end{align}
```
