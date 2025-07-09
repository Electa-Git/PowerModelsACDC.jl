# Static series synchronous compenstion devices, e.g. smart wires

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
| sssc_status   | $\delta_{sssc}$           | -     | Int       | -        | status indicator of series compensator |
| vqmin         | $\underline{v_{q}}$       | p.u.  | Real      | -        | minimum quadrature voltage |
| vqmax         | $\overline{v_{q}}$        | p.u.  | Real      | -        | maximum quadrature voltage |

## Variables

Optimisation variables representing SSSC behaviour

| name          | symb.                 | unit  | formulation     | definition                                                                  |
|---------------|-----------------------|-------|-----------------|----------------------------------------------------------------------------|
| vqsssc        |$v_{q}$                | p.u.  | ACP,  ACR      | Voltage injected in quadrature                      |
| alphaqsssc    |$\alpha_{q}$           | rad   | DCP             | Equivalent phase angle shift induced by SSSC |
| psssc         |$p_{sc,i,j}$           | p.u.  | ACP, ACR,  DCP | Active power flow through SSSC |
| qsssc         |$q_{sc,i,j}$           | p.u.  | ACP, ACR      | Reactive power flow through SSSC |

## Constraints

### Flow, voltage, angle limits

Active, reactive, and apparent power limits:
```math
\begin{align}
- \overline{S_{sssc}} \leq p_{sc,i,j} \leq \overline{S_{sssc}} \\
- \overline{S_{sssc}} \leq q_{sc,i,j} \leq \overline{S_{sssc}} \\
p_{sc,i,j}^{2} + q_{sc,i,j}^{2} \leq \overline{S_{sssc}}^{2}
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

### SSSC admittance
```math
\begin{align}
g_{sssc} = \Re{\frac{1} {r_{sssc} + j \cdot x_sssc}} \\
b_{sssc} = \Im{\frac{1} {r_{sssc} + j \cdot x_sssc}} \\
\end{align}
```

### Ohm's law
ACP model:
```math
\begin{align}
v_{i}^{*} &= \sqrt{v_{i}^{2} + 2 \cdot v_{i} \cdot v_{q} + v_{q}^{2}} \\
\theta_{i}^{*} &= atan(\frac{v_{i} \cdot sin(\theta_{i}) + v_{q}}{v_{i} \cdot cos(\theta_{i})})  
\end{align}
```
```math
\begin{align}
p_{sc,i,j} &= g_{sssc} \cdot (v^{*}_{i})^{2} - g_{sssc} \cdot v^{*}_{i} \cdot v_{j} \cdot cos(\theta_{i}^{*} - \theta_{j}) - b_{sssc} \cdot v^{*}_{i} \cdot v_{j} \cdot sin(\theta_{i}^{*} - \theta_{j}) \\
q_{sc,i,j} &= -b_{sssc} \cdot (v^{*}_{i})^{2} + b_{sssc} \cdot v^{*}_{i} \cdot v_{j} \cdot cos(\theta_{i}^{*} - \theta_{j}) - g_{sssc} \cdot v^{*}_{i} \cdot v_{j} \cdot sin(\theta_{i}^{*} - \theta_{j}) \\
\end{align}
```
```math
\begin{align}
p_{j,i,sc} &= g_{sssc} \cdot (v_{j})^{2} - g_{sssc} \cdot v^{*}_{i} \cdot v_{j} \cdot cos(\theta_{j} - \theta_{i}^{*}) - b_{sssc} \cdot v^{*}_{i} \cdot v_{j} \cdot sin(\theta_{j} - \theta_{i}^{*}) \\
q_{j,i,sc} &= -b_{sssc} \cdot (v_{j})^{2} + b_{sssc} \cdot v^{*}_{i} \cdot v_{j} \cdot cos(\theta_{j} - \theta_{i}^{*}) - g_{sssc} \cdot v^{*}_{i} \cdot v_{j} \cdot sin(\theta_{j} - \theta_{i}^{*}) \\
\end{align}
```

ACR model:

```math
\begin{align}
\underline{v_{i}^{*}} &= \underline{v_{i}} + j \cdot v_{q} \\
p_{sc,i,j} &= g_{sssc} \cdot (v_{i}^{*})^{2}- g_{sssc} \cdot (\Re{\underline{v_{i}^{*}}} \cdot \Re{\underline{v_{j}}} + \Im{\underline{v_{i}^{*}}} \cdot \Im{\underline{v_{j}}})  - b_{sssc} \cdot (\Im{\underline{v_{i}^{*}}} \cdot \Re{\underline{v_{j}}} + \Re{\underline{v_{i}^{*}}} \cdot \Im{\underline{v_{j}}}) \\
q_{sc,i,j} &= -b_{sssc} \cdot (v_{i}^{*})^{2} + b_{sssc} \cdot (\Re{\underline{v_{i}^{*}}} \cdot \Re{\underline{v_{j}}} + \Im{\underline{v_{i}^{*}}} \cdot \Im{\underline{v_{j}}})  - g_{sssc} \cdot (\Im{\underline{v_{i}^{*}}} \cdot \Re{\underline{v_{j}}} + \Re{\underline{v_{i}^{*}}} \cdot \Im{\underline{v_{j}}}) \\
\end{align}
```
```math
\begin{align}
p_{j,i,sc} &= g_{sssc} \cdot (v_{j})^{2}- g_{sssc} \cdot (\Re{\underline{v_{i}^{*}}} \cdot \Re{\underline{v_{j}}} + \Im{\underline{v_{i}^{*}}} \cdot \Im{\underline{v_{j}}})  - b_{sssc} \cdot (\Im{\underline{v_{i}^{*}}} \cdot \Re{\underline{v_{j}}} + \Re{\underline{v_{i}^{*}}} \cdot \Im{\underline{v_{j}}}) \\
q_{j,i,sc} &= -b_{sssc} \cdot (v_{j})^{2} + b_{sssc} \cdot (\Re{\underline{v_{i}^{*}}} \cdot \Re{\underline{v_{j}}} + \Im{\underline{v_{i}^{*}}} \cdot \Im{\underline{v_{j}}})  - g_{sssc} \cdot (\Im{\underline{v_{i}^{*}}} \cdot \Re{\underline{v_{j}}} + \Re{\underline{v_{i}^{*}}} \cdot \Im{\underline{v_{j}}}) \\
\end{align}
```

DCP model:
```math
\begin{align}
p_{sc,i,j} &= - b_{sssc} \cdot (\theta_{i} - \theta_{j} - \alpha_{q}) \\
p_{sc,i,j} + p_{j,i,sc} &= 0
\end{align}
```
