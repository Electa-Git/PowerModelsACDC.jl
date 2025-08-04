# DC Branches 

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
| rateA             | $\overline{P_{dc}}$       | MW    | Real      | -        | long term rating of the AC branch |
| rateB             | $\overline{P^{st}_{dc}}$  | MW    | Real      | -        | short term term rating of the AC branch |
| rateC             | $\overline{P^{em}_{dc}}$  | MW    | Real      | -        | emergency rating of the AC branch |
| status            | $\delta_{dc}$             | -     | Int       | -        | status indicator of the AC branch |
| tap               | $\tau$                    | -     | Real      | -        | tap ratio of potential transformer tap |
| shift             | $\varphi$                 | -     | Real      | -        | phase shift induced by PST if modelled as a fixed element |
| angmin            | $\underline{\theta}$      | -     | Real      | -        | minimum allowable phase angle difference over AC branch |
| angmax            | $\overline{\theta}$       | -     | Real      | -        | maximum allowable phase angle difference over AC branch |
| construction_cost | $C_{ac}$                  | -     | Real      | -        | investment cost for AC branch used in TNEP problems  |



## Variables

Optimisation variables representing AC Branch behaviour

| name          | symb.                 | unit  | formulation                       | definition                                                                 |
|---------------|-----------------------|-------|-----------------------------------|----------------------------------------------------------------------------|  
| p             |$P_{b,i,j}$            | p.u.  | ACP, ACR, LPAC, IVR, SOC, DCP, NF | Active power flow through DC branch d, connecting DC nodes i and j |
| q             |$Q_{b,i,j}$            | p.u.  | IVR                               | Current flow through DC branch d, connecting DC nodes i and j |


