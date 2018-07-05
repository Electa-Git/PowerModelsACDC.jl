# Quick Start Guide

Once PowerModelsACDC is installed, Ipopt is installed, and an ACDC network data file (e.g. `"case5_acdc.m"` in the folder `"./test/data"`) has been acquired, an ACDC Optimal Power Flow can be executed with:

```julia
using PowerModelsACDC
using Ipopt

result = run_acdcopf("case5_acdc.m", ACPPowerModel, IpoptSolver())
result["solution"]["busdc"]["1"]
result["solution"]["convdc"]["1"]
```

You can also find a test script in the folder `"./test/scripts"`.

## Modifying settings
The flow AC and DC branch results are not written to the result by default. To inspect the flow results, pass a settings Dict
```julia
result = run_acdcopf("case5_acdc.m", ACPPowerModel, IpoptSolver(), setting = Dict("output" => Dict("branch_flows" => true)))
result["solution"]["branchdc"]["1"]
result["solution"]["branch"]["2"]
```


## Remark
Note that `run_ac_opf` still works and runs a classic AC OPF on only the AC part of the described grid.

```julia
result = run_ac_opf("case5_acdc.m", IpoptSolver())
```
