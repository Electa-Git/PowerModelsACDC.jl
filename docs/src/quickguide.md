# Quick Start Guide

Once PowerModelsADriaN is installed, Ipopt is installed, and a network data file (e.g. `"nesta_case3_lmbd.m"`) has been acquired, an AC Optimal Power Flow can be executed with,

```julia
using PowerModelACDC
using Ipopt

run_ac_scopf("nesta_case3_lmbd.m", IpoptSolver())
```
The unbalanced DistFlow SDP relaxation cannot be run with Ipopt, but can be run with Mosek instead.

## Modifying settings
The flow AC and DC branch results are not written to the result by default. To inspect the flow results, pass a settings Dict
```julia
result = run_opf("case3_dc.m", ACPPowerModel, IpoptSolver(), setting = Dict("output" => Dict("line_flows" => true)))
result["solution"]["dcline"]["1"]
result["solution"]["branch"]["2"]
```

For the unbalanced power flow, the line series flow can be obtained as follows:
```julia
data = PowerModels.parse_file("./test/data/case3_unbalanced.m")
PowerModelsADriaN.process_additional_data!(data) # processing UB OPF specific data
solution = run_ubopf(data, UnbDistPowerModel, MosekSolver(),setting = Dict("output" => Dict("line_flows" => true, "line_series_flows" => true)))
```

Furthermore, the node voltage angles and the rank can be derived for the unbalanced DistFlow SDP formulation as follows:
```julia
data = PowerModels.parse_file("./test/data/case3_unbalanced.m")
PowerModelsADriaN.process_additional_data!(data) # processing UB OPF specific data
solution = run_ubopf(data, UnbDistPowerModel, MosekSolver(),setting = Dict("output" => Dict("line_flows" => true, "line_series_flows" => true, "rank_elements" => true)))
PowerModelsADriaN.ub_post_process!(data, solution, rank_accuracy = 1e-4)
```
!!! note
    The rank is computed by counting how many singular values of M have magnitude greater than `rank_accuracy`. This process is therefore based on the singular value decomposition. Note that the overall solution is relaxed w.r.t. unbalanced AC power flow and may not be feasible w.r.t. AC power flow when the rank of any line differs from 1.
