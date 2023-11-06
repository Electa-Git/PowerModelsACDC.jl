# Problem types
Following problem types have been implemented within PowerModelsACDC.jl. Example scripts to run the various problem types can be found under test/scripts.

## Hybrid AC/DC optimal power flow
```julia
run_acdcopf(file or data, formulation, solver, setting)
```

## Hybrid AC/DC power flow
```julia
run_acdcpf(file or data, formulation, solver, setting)
```

## Sequential Hybrid AC/DC power flow (Native)
```julia
run_sacdcpf(file or data)
```

## DC grid TNEP problem (optimal placement of converters and dc branches)
```julia
run_tnepopf(file or data, formulation, solver, setting)
```

## DC grid TNEP problem in branch flow formulation (optimal placement of converters and dc branches)
```julia
run_tnepopf_bf(file or data, formulation, solver, setting)
```

## Multi-period DC grid TNEP problem (optimal placement of converters and dc branches)
```julia
run_mp_tnepopf(data, formulation, solver, setting)
```
This problem type uses the multi-network functionality of PowerModels.jl.

## Multi-period DC grid TNEP problem in branch flow formulation (optimal placement of converters and dc branches)
```julia
run_mp_tnepopf_bf(data, formulation, solver, setting)
```
This problem type uses the multi-network functionality of PowerModels.jl.

## AC/DC grid TNEP problem (optimal placement of ac branches, converters and dc branches)
```julia
run_acdctnepopf(file or data, formulation, solver, setting)
```

## AC/DC grid TNEP problem in branch flow formulation (optimal placement of ac branches, converters and dc branches)
```julia
run_acdctnepopf_bf(file or data, formulation, solver, setting)
```
This problem type is currently not working as the ac grid TNEP problem in branch flow formulation is not implemented in PowerModels.jl.

## Multi-period AC/DC grid TNEP problem (optimal placement of converters and dc branches)
```julia
run_mp_tnepopf(data, formulation, solver, setting)
```
This problem type uses the multi-network functionality of PowerModels.jl.

## Multi-period AC/DC grid TNEP problem in branch flow formulation (optimal placement of converters and dc branches)
```julia
run_mp_tnepopf_bf(data, formulation, solver, setting)
```
This problem type uses the multi-network functionality of PowerModels.jl.
This problem type is currently not working as the ac grid TNEP problem in branch flow formulation is not implemented in PowerModels.jl.
