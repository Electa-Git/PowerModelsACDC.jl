# Quick Start Guide

Once PowerModelsACDC is installed, Ipopt is installed, and an ACDC network data file (e.g. `"case5_acdc.m"` in the folder `"./test/data"`) has been acquired, an ACDC Optimal Power Flow can be executed with:

```julia
using PowerModelsACDC
import PowerModels
import Ipopt
nlp_solver = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>1e-6, "print_level"=>0)

result = solve_acdcopf("case5_acdc.m", PowerModels.ACPPowerModel, nlp_solver)
result["solution"]["busdc"]["1"]
result["solution"]["convdc"]["1"]
```

You can also find a test script in the folder `"./test/scripts"`.


## Remark
Note that PowerModels’ `solve_ac_opf` still works and runs a classic AC OPF on only the AC part of the described grid.

```julia
result = PowerModels.solve_ac_opf("case5_acdc.m", nlp_solver)
```
