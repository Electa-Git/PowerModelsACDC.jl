# Quick Start Guide

Once PowerModelsACDC is installed, Ipopt is installed, and a network data file (e.g. `"case5_acdc.m"`) has been acquired, an ACDC Optimal Power Flow can be executed with,

```julia
using PowerModelsACDC
using Ipopt

result = run_acdc_opf("case5_acdc.m", IpoptSolver())
result["solution"]["busdc"]["1"]
result["solution"]["convdc"]["1"]
```

## Modifying settings
The flow AC and DC branch results are not written to the result by default. To inspect the flow results, pass a settings Dict
```julia
result = run_opf("case5_acdc.m", ACPPowerModel, IpoptSolver(), setting = Dict("output" => Dict("line_flows" => true)))
result["solution"]["branchdc"]["1"]
result["solution"]["branch"]["2"]
```
