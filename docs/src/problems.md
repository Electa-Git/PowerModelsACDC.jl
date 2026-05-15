# Problem types
Following problem types have been implemented within PowerModelsACDC.jl. Example scripts to run the various problem types can be found under test/scripts.

#### Hybrid AC/DC optimal power flow
```julia
solve_acdcopf(file or data, formulation, solver, setting)
```

#### Hybrid AC/DC power flow
```julia
solve_acdcpf(file or data, formulation, solver, setting)
```

#### Sequential Hybrid AC/DC power flow (Native)
```julia
solve_sacdcpf(file or data)
```

#### AC/DC grid TNEP problem (optimal placement of ac branches, converters and dc branches)
```julia
solve_tnep(file or data, formulation, solver, setting)
```
