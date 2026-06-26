### A Pluto.jl notebook ###
# v0.20.24

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ a1db2070-9313-4f11-8780-7253242b15f2
begin
    using Markdown
    using InteractiveUtils
end

# ╔═╡ 7d2da9fc-d707-4716-a89c-7395c5423ea4
begin
    using PowerModelsACDC
    using PowerModels
    using JuMP
    using Ipopt
    using DataFrames
    import Downloads
end

# ╔═╡ 0ba1f34f-28fc-44fd-aedc-1e12977f76bc
md"""
# Simple OPF formulation comparison in PowerModelsACDC.jl

This notebook is intentionally minimal. It solves **the same AC/DC case** with a few OPF formulations and compares:

- AC and DC bus voltage magnitudes;
- AC branch active/reactive power flows;
- DC branch active power flows;
- converter active/reactive power quantities, when available.

The key simplification is that all result post-processing is done in **one function**, `post_process_result`.

Voltage magnitudes are computed as follows:

- Polar formulations: use `vm` when available.
- ACR/IVR formulations: compute `sqrt(vr^2 + vi^2)` from real and imaginary voltage parts.
- SOC/WR formulations: compute `sqrt(w)` when squared voltage `w` is available.
- If a formulation reports real/imaginary parts of squared voltage, `wr` and `wi`, compute `sqrt(sqrt(wr^2 + wi^2))`.
- DC approximation: voltage magnitudes are set to `1.0` p.u. by definition.
"""

# ╔═╡ d9defe09-41db-4634-92f2-c115935e1777
begin
    # Uncomment once if needed.
    # import Pkg
    # Pkg.add(["PowerModelsACDC", "PowerModels", "JuMP", "Ipopt", "DataFrames"])
end

# ╔═╡ 92139ca0-48df-4c75-a34b-59ba1b96ca0a
md"""
## 1. Case, solver, and settings

We use `case5_acdc.m`, the small AC/DC test case used in the package tests/examples.
"""

# ╔═╡ 7811fb63-1df9-4470-a281-2bef250ac482
begin
    package_dir = dirname(dirname(pathof(PowerModelsACDC)))
    case_file = joinpath(package_dir, "test", "data", "case5_acdc.m")

    if !isfile(case_file)
        url = "https://raw.githubusercontent.com/Electa-Git/PowerModelsACDC.jl/master/test/data/case5_acdc.m"
        case_file = joinpath(pwd(), "case5_acdc.m")
        Downloads.download(url, case_file)
    end

    solver = JuMP.optimizer_with_attributes(
        Ipopt.Optimizer,
        "print_level" => 0,
        "sb" => "yes",
    )

    settings = Dict(
        "output" => Dict("branch_flows" => true),
        "conv_losses_mp" => true,
    )

    case_file
end

# ╔═╡ b36f6b99-037b-4bcb-8fe4-4e40a1b382dd
md"""
## 2. Formulations to run

The list is kept short. If `IVRPowerModel` or LPAC is available in your installed version, it is added automatically.
"""

# ╔═╡ 909cab92-c8ff-41fa-ba20-4405dbf7a3d3
begin
    formulations = Any[
        (; name="ACP",   model=ACPPowerModel,   solvefun=solve_acdcopf),
        (; name="ACR",   model=ACRPowerModel,   solvefun=solve_acdcopf),
        (; name="DCP",   model=DCPPowerModel,   solvefun=solve_acdcopf),
        (; name="SOCWR", model=SOCWRPowerModel, solvefun=solve_acdcopf),
    ]

    # Add LPAC if available. The name differs across versions.
    if isdefined(PowerModelsACDC, :LPACCPowerModel)
        push!(formulations, (; name="LPACC", model=getfield(PowerModelsACDC, :LPACCPowerModel), solvefun=solve_acdcopf))
    elseif isdefined(PowerModelsACDC, :LPACPowerModel)
        push!(formulations, (; name="LPAC", model=getfield(PowerModelsACDC, :LPACPowerModel), solvefun=solve_acdcopf))
    elseif isdefined(PowerModels, :LPACPowerModel)
        push!(formulations, (; name="LPAC", model=getfield(PowerModels, :LPACPowerModel), solvefun=solve_acdcopf))
    end

    # Add IVR if the installed package exposes the IVR formulation and solver entry point.
    if isdefined(PowerModelsACDC, :IVRPowerModel) && isdefined(PowerModelsACDC, :solve_acdcopf_iv)
        push!(formulations, (; name="IVR", model=getfield(PowerModelsACDC, :IVRPowerModel), solvefun=getfield(PowerModelsACDC, :solve_acdcopf_iv)))
    end

    DataFrame(formulation=[f.name for f in formulations], model=[string(f.model) for f in formulations])
end

# ╔═╡ f8cd99a9-7cb7-4ec5-b8ba-3b338e5788cd
md"""
## 3. Run the OPFs

Each row calls either:

```julia
solve_acdcopf(case_file, formulation, solver; setting=settings)
```

or, for IVR when available:

```julia
solve_acdcopf_iv(case_file, IVRPowerModel, solver; setting=settings)
```
"""

# ╔═╡ 182ea6f2-6b98-4d2d-9464-5b5ea06361f8
begin
    results = Dict{String,Any}()
    run_rows = []

    for f in formulations
        try
            t0 = time()
            result = f.solvefun(case_file, f.model, solver; setting=settings)
            elapsed = time() - t0
            results[f.name] = result

            push!(run_rows, (
                formulation=f.name,
                status=string(get(result, "termination_status", get(result, "status", missing))),
                objective=get(result, "objective", missing),
                solve_time_s=elapsed,
                error="",
            ))
        catch err
            push!(run_rows, (
                formulation=f.name,
                status="failed",
                objective=missing,
                solve_time_s=missing,
                error=sprint(showerror, err),
            ))
        end
    end

    run_summary = DataFrame(run_rows)
end

# ╔═╡ 5c2f4d0e-a63a-47e0-a04b-441603a617b9
run_summary

# ╔═╡ 70cdf14a-a0f4-49fc-ad2b-694ff41130c8
md"""
## 4. One post-processing function

This function extracts voltage magnitudes and power-flow quantities from one result dictionary.
"""

# ╔═╡ 84504f28-de98-4d50-ad7d-44e7add1818b
begin
    function post_process_result(result, formulation_name)
        sol = get(result, "solution", Dict{String,Any}())
        voltage_rows = NamedTuple[]
        flow_rows = NamedTuple[]

        get_value(d, keys) = begin
            for k in keys
                if haskey(d, k)
                    return d[k]
                end
            end
            return missing
        end

        function voltage_magnitude(d; dc=false)
            # DCP voltage magnitude is 1.0 p.u. by definition.
            if formulation_name == "DCP"
                return 1.0
            end

            # Direct magnitude, common in polar formulations and often DC-grid results.
            direct_keys = dc ? ["vdc", "vmdc", "vm_dc", "vdcm", "vm", "v"] : ["vm", "v"]
            v_direct = get_value(d, direct_keys)
            if !ismissing(v_direct)
                return Float64(v_direct)
            end

            # Rectangular voltage, common for ACR and IVR formulations.
            vr = get_value(d, ["vr"])
            vi = get_value(d, ["vi"])
            if !ismissing(vr) && !ismissing(vi)
                return sqrt(Float64(vr)^2 + Float64(vi)^2)
            end

            # Squared voltage magnitude, common in SOC/WR formulations.
            w_keys = dc ? ["wdc", "w_dc", "w"] : ["w"]
            w = get_value(d, w_keys)
            if !ismissing(w)
                return sqrt(max(Float64(w), 0.0))
            end

            # Real and imaginary parts of squared voltage.
            wr_keys = dc ? ["wrdc", "wr_dc", "wr"] : ["wr"]
            wi_keys = dc ? ["widc", "wi_dc", "wi"] : ["wi"]
            wr = get_value(d, wr_keys)
            wi = get_value(d, wi_keys)
            if !ismissing(wr) && !ismissing(wi)
                # sqrt(abs(wr + im*wi)) = sqrt(sqrt(wr^2 + wi^2))
                return sqrt(sqrt(Float64(wr)^2 + Float64(wi)^2))
            elseif !ismissing(wr)
                return sqrt(abs(Float64(wr)))
            end

            return missing
        end

        # AC bus voltage magnitudes.
        for (id, bus) in get(sol, "bus", Dict())
            v = voltage_magnitude(bus; dc=false)
            if !ismissing(v)
                push!(voltage_rows, (component="AC bus", id=string(id), quantity="|V| [p.u.]", formulation=formulation_name, value=v))
            end
        end

        # DC bus voltage magnitudes.
        for (id, busdc) in get(sol, "busdc", Dict())
            v = voltage_magnitude(busdc; dc=true)
            if !ismissing(v)
                push!(voltage_rows, (component="DC bus", id=string(id), quantity="|Vdc| [p.u.]", formulation=formulation_name, value=v))
            end
        end

        # AC branch flows.
        for (id, br) in get(sol, "branch", Dict())
            for q in ["pf", "pt", "qf", "qt"]
                val = get_value(br, [q])
                if !ismissing(val)
                    push!(flow_rows, (component="AC branch", id=string(id), quantity=q, formulation=formulation_name, value=Float64(val)))
                end
            end
        end

        # DC branch flows.
        for (id, brdc) in get(sol, "branchdc", Dict())
            for q in ["pf", "pt", "pdcf", "pdct"]
                val = get_value(brdc, [q])
                if !ismissing(val)
                    push!(flow_rows, (component="DC branch", id=string(id), quantity=q, formulation=formulation_name, value=Float64(val)))
                end
            end
        end

        # Converter powers. These are useful in AC/DC cases and are treated as interface flows.
        for (id, conv) in get(sol, "convdc", Dict())
            for q in ["pconv", "qconv", "pconv_ac", "qconv_ac", "pconv_dc", "pgrid", "qgrid", "pdc"]
                val = get_value(conv, [q])
                if !ismissing(val)
                    push!(flow_rows, (component="Converter", id=string(id), quantity=q, formulation=formulation_name, value=Float64(val)))
                end
            end
        end

        return (
            voltages = isempty(voltage_rows) ? DataFrame() : DataFrame(voltage_rows),
            flows = isempty(flow_rows) ? DataFrame() : DataFrame(flow_rows),
        )
    end
end

# ╔═╡ 581f153f-12dc-446f-8834-8b13085509de
md"""
## 5. Compare voltage magnitudes

Rows are buses, columns are formulations.
"""

# ╔═╡ 28b0e7f3-89d8-4f7b-8f5d-24eac1c86bff
begin
    processed = Dict(name => post_process_result(result, name) for (name, result) in results)

    voltage_long = isempty(processed) ? DataFrame() : vcat([p.voltages for p in values(processed)]...; cols=:union)

    voltage_comparison = if nrow(voltage_long) == 0
        DataFrame(message=["No voltage results available"])
    else
        sort(unstack(voltage_long, [:component, :id, :quantity], :formulation, :value), [:component, :id, :quantity])
    end
end

# ╔═╡ 19e1b2a7-b5d6-4981-873c-2d847e4fce8b
voltage_comparison

# ╔═╡ 269e71c5-9cb4-4126-8dd8-9b9cb743bce9
md"""
## 6. Compare power flows

Rows are component/element/quantity combinations, columns are formulations.
"""

# ╔═╡ 850f8261-832f-4355-8e25-11a735674615
begin
    flow_long = isempty(processed) ? DataFrame() : vcat([p.flows for p in values(processed)]...; cols=:union)

    flow_comparison = if nrow(flow_long) == 0
        DataFrame(message=["No flow results available"])
    else
        sort(unstack(flow_long, [:component, :id, :quantity], :formulation, :value), [:component, :id, :quantity])
    end
end

# ╔═╡ 8617e636-a2bc-4d63-a3dd-0debde4d4032
flow_comparison

# ╔═╡ abe5b3f0-d0ff-46d5-829d-0093226a1015
md"""
## 7. Optional: inspect one raw result

If you want to see the original PowerModelsACDC result dictionary for one formulation, select it here.
"""

# ╔═╡ 1be2bdd6-c448-4778-9ad7-6592898b275d
begin
    result_names = sort(collect(keys(results)))
end

# ╔═╡ 0ed90dd7-2354-4721-8559-aa60c647c64e
if isempty(result_names)
    md"No successful OPF result available."
else
    @bind selected_formulation Select(result_names)
end

# ╔═╡ 6e3b4da0-30d6-44ef-ac6b-645fb33948fa
if isempty(result_names)
    DataFrame(message=["No result selected"])
else
    keys(results[selected_formulation]["solution"])
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Downloads = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
InteractiveUtils = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
Ipopt = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
PowerModels = "c36e90e8-916a-50a6-bd94-075b64ef4655"
PowerModelsACDC = "ff45984e-d068-5f4c-9e32-c4133509d236"

[compat]
DataFrames = "~1.8.1"
Ipopt = "~1.14.1"
JuMP = "~1.30.0"
PowerModels = "~0.21.5"
PowerModelsACDC = "~0.9.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.7"
manifest_format = "2.0"
project_hash = "b5435086a8c6b6bf73cfaa6f22d61f0b44a7a7b0"

[[deps.ADTypes]]
git-tree-sha1 = "f7304359109c768cf32dc5fa2d371565bb63b68a"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "1.21.0"

    [deps.ADTypes.extensions]
    ADTypesChainRulesCoreExt = "ChainRulesCore"
    ADTypesConstructionBaseExt = "ConstructionBase"
    ADTypesEnzymeCoreExt = "EnzymeCore"

    [deps.ADTypes.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"

[[deps.ASL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6252039f98492252f9e47c312c8ffda0e3b9e78d"
uuid = "ae81ac8f-d209-56e5-92de-9978fef736f9"
version = "0.1.3+0"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "35ea197a51ce46fcd01c4a44befce0578a1aaeca"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.5.0"

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

    [deps.Adapt.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra"]
git-tree-sha1 = "78b3a7a536b4b0a747a0f296ea77091ca0a9f9a3"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.23.0"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceAMDGPUExt = "AMDGPU"
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceCUDSSExt = ["CUDSS", "CUDA"]
    ArrayInterfaceChainRulesCoreExt = "ChainRulesCore"
    ArrayInterfaceChainRulesExt = "ChainRules"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceMetalExt = "Metal"
    ArrayInterfaceReverseDiffExt = "ReverseDiff"
    ArrayInterfaceSparseArraysExt = "SparseArrays"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "7fecfb1123b8d0232218e2da0c213004ff15358d"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.6.3"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "TranscodingStreams"]
git-tree-sha1 = "84990fa864b7f2b4901901ca12736e45ee79068c"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.8.5"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "9d8a54ce4b17aa5bdce0ea5c34bc5e7c340d16ad"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.18.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ConstructionBase]]
git-tree-sha1 = "b4b092499347b18a015186eae3042f72267106cb"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.6.0"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d8928e9169ff76c6281f39a659f9bca3a573f24c"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.8.1"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "e357641bb3e0638d353c4b29ea0e40ea644066a6"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.3"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.DifferentiationInterface]]
deps = ["ADTypes", "LinearAlgebra"]
git-tree-sha1 = "7ae99144ea44715402c6c882bfef2adbeadbc4ce"
uuid = "a0c0ee7d-e4b9-4e03-894e-1c5f64a51d63"
version = "0.7.16"

    [deps.DifferentiationInterface.extensions]
    DifferentiationInterfaceChainRulesCoreExt = "ChainRulesCore"
    DifferentiationInterfaceDiffractorExt = "Diffractor"
    DifferentiationInterfaceEnzymeExt = ["EnzymeCore", "Enzyme"]
    DifferentiationInterfaceFastDifferentiationExt = "FastDifferentiation"
    DifferentiationInterfaceFiniteDiffExt = "FiniteDiff"
    DifferentiationInterfaceFiniteDifferencesExt = "FiniteDifferences"
    DifferentiationInterfaceForwardDiffExt = ["ForwardDiff", "DiffResults"]
    DifferentiationInterfaceGPUArraysCoreExt = "GPUArraysCore"
    DifferentiationInterfaceGTPSAExt = "GTPSA"
    DifferentiationInterfaceMooncakeExt = "Mooncake"
    DifferentiationInterfacePolyesterForwardDiffExt = ["PolyesterForwardDiff", "ForwardDiff", "DiffResults"]
    DifferentiationInterfaceReverseDiffExt = ["ReverseDiff", "DiffResults"]
    DifferentiationInterfaceSparseArraysExt = "SparseArrays"
    DifferentiationInterfaceSparseConnectivityTracerExt = "SparseConnectivityTracer"
    DifferentiationInterfaceSparseMatrixColoringsExt = "SparseMatrixColorings"
    DifferentiationInterfaceStaticArraysExt = "StaticArrays"
    DifferentiationInterfaceSymbolicsExt = "Symbolics"
    DifferentiationInterfaceTrackerExt = "Tracker"
    DifferentiationInterfaceZygoteExt = ["Zygote", "ForwardDiff"]

    [deps.DifferentiationInterface.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DiffResults = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
    Diffractor = "9f5e2b26-1114-432f-b630-d3fe2085c51c"
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
    EnzymeCore = "f151be2c-9106-41f4-ab19-57ee4f262869"
    FastDifferentiation = "eb9bf01b-bf85-4b60-bf87-ee5de06c00be"
    FiniteDiff = "6a86dc24-6348-571c-b903-95158fe2bd41"
    FiniteDifferences = "26cc04aa-876d-5657-8c51-4c34ba976000"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    GTPSA = "b27dd330-f138-47c5-815b-40db9dd9b6e8"
    Mooncake = "da2b9cff-9c12-43a0-ae48-6db2b0edb7d6"
    PolyesterForwardDiff = "98d1487c-24ca-40b6-b7ab-df2af84e126b"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SparseConnectivityTracer = "9f842d2f-2579-4b1d-911e-f412cf18a3f5"
    SparseMatrixColorings = "0a514795-09f3-496d-8182-132a7b665d35"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "c7e3a542b999843086e2f29dac96a618c105be1d"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.12"

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

    [deps.Distances.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Setfield"]
git-tree-sha1 = "9340ca07ca27093ff68418b7558ca37b05f8aeb1"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.29.0"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffSparseArraysExt = "SparseArrays"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "eef4c86803f47dcb61e9b8790ecaa96956fdd8ae"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "1.3.2"

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

    [deps.ForwardDiff.weakdeps]
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XML2_jll", "Xorg_libpciaccess_jll"]
git-tree-sha1 = "157e2e5838984449e44af851a52fe374d56b9ada"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.13.0+0"

[[deps.InfrastructureModels]]
deps = ["JuMP", "Memento"]
git-tree-sha1 = "f9c1f6bdac8ad3fca6fc24fcf68256958ad84c28"
uuid = "2030c09a-7f63-5d83-885d-db604e0e9cc0"
version = "0.7.8"

[[deps.InlineStrings]]
git-tree-sha1 = "8f3d257792a522b4601c24a577954b0a8cd7334d"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.5"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.InvertedIndices]]
git-tree-sha1 = "6da3c4316095de0f5ee2ebd875df8721e7e0bdbe"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.1"

[[deps.Ipopt]]
deps = ["Ipopt_jll", "LinearAlgebra", "OpenBLAS32_jll", "PrecompileTools"]
git-tree-sha1 = "f1b9bf4b24fa1844f25fe570836f75cdb9f5245e"
uuid = "b6b21f68-93f8-5de0-b562-5493be1d77c9"
version = "1.14.1"
weakdeps = ["MathOptInterface"]

    [deps.Ipopt.extensions]
    IpoptMathOptInterfaceExt = "MathOptInterface"

[[deps.Ipopt_jll]]
deps = ["ASL_jll", "Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "MUMPS_seq_jll", "SPRAL_jll", "libblastrampoline_jll"]
git-tree-sha1 = "8e9d217c63a8c8af96949300180ba0558f7f88b5"
uuid = "9cc047cb-c261-5740-88fc-0cf96f7bdcc7"
version = "300.1400.1901+0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JuMP]]
deps = ["LinearAlgebra", "MacroTools", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays"]
git-tree-sha1 = "4091a1338a0e32766b11b9bd3fac247d34200c77"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.30.0"

    [deps.JuMP.extensions]
    JuMPDimensionalDataExt = "DimensionalData"

    [deps.JuMP.weakdeps]
    DimensionalData = "0703355e-b756-11e9-17c0-8b28908087d0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Printf"]
git-tree-sha1 = "9ea3422d03222c6de679934d1c08f0a99405aa03"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.5.1"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.METIS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "2eefa8baa858871ae7770c98c3c2a7e46daba5b4"
uuid = "d00139f3-1899-568f-a2f0-47f597d42d70"
version = "5.1.3+0"

[[deps.MUMPS_seq_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "METIS_jll", "libblastrampoline_jll"]
git-tree-sha1 = "afbaaa0fa2f001ad8091e27885d69973f8eae3d7"
uuid = "d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"
version = "500.800.200+0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "PrecompileTools", "Printf", "SparseArrays", "SpecialFunctions", "Test"]
git-tree-sha1 = "7fb98657926ccb4de8f9bb96cda453700ca39a8b"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.49.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Memento]]
deps = ["Dates", "Distributed", "Requires", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "bb2e8f4d9f400f6e90d57b34860f6abdc51398e5"
uuid = "f28f55f0-a522-5efc-85c2-fe41dfb9b2d9"
version = "1.4.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "22df8573f8e7c593ac205455ca088989d0a2c7a0"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.6.7"

[[deps.NLSolversBase]]
deps = ["ADTypes", "DifferentiationInterface", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "25a6638571a902ecfb1ae2a18fc1575f86b1d4df"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.10.0"

[[deps.NLsolve]]
deps = ["Distances", "LineSearches", "LinearAlgebra", "NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "019f12e9a1a7880459d0173c182e6a99365d7ac1"
uuid = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
version = "4.5.1"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS32_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "46cce8b42186882811da4ce1f4c7208b02deb716"
uuid = "656ef2d0-ae68-5445-9ca0-591084a874a2"
version = "0.3.30+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.5+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PowerModels]]
deps = ["InfrastructureModels", "JSON", "JuMP", "LinearAlgebra", "Memento", "NLsolve", "PrecompileTools", "SparseArrays"]
git-tree-sha1 = "b8e410e1d827b621e82e7e670967f0efc5845c30"
uuid = "c36e90e8-916a-50a6-bd94-075b64ef4655"
version = "0.21.5"

[[deps.PowerModelsACDC]]
deps = ["InfrastructureModels", "JuMP", "LinearAlgebra", "Memento", "NLsolve", "PowerModels", "SparseArrays"]
git-tree-sha1 = "216c251b8778266d6f8498ed4dea2c242651a1db"
uuid = "ff45984e-d068-5f4c-9e32-c4133509d236"
version = "0.9.4"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "REPL", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "c5a07210bd060d6a8491b0ccdee2fa0235fc00bf"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "3.1.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Profile]]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SPRAL_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "Libdl", "METIS_jll", "libblastrampoline_jll"]
git-tree-sha1 = "139fa63f03a16b3d859d925ee9149dfc15f21ece"
uuid = "319450e9-13b8-58e8-aa9f-8fd1420848ab"
version = "2025.9.18+0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "ebe7e59b37c400f694f52b58c93d26201387da70"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.9"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "c5391c6ace3bc430ca630251d02ea9687169ca68"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.2"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "64d974c2e6fdf07f8155b5b2ca2ffa9069b608d9"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.2"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "5acc6a41b3082920f79ca3c759acbcecf18a8d78"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.7.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6ab403037779dae8c514bad259f32a447262455a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.4"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "178ed29fd5b2a2cfc3bd31c13375ae925623ff36"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.8.0"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "d05693d339e37d6ab134c5ab53c29fce5ee5d7d5"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.4"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "f2c1efbc8f3a609aadf318094f8fc5204bdaf344"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "80d3930c6347cfce7ccf96bd3bafdf079d9c0390"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.9+0"

[[deps.Xorg_libpciaccess_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "4909eb8f1cbf6bd4b1c30dd18b2ead9019ef2fad"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.18.1+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═a1db2070-9313-4f11-8780-7253242b15f2
# ╠═0ba1f34f-28fc-44fd-aedc-1e12977f76bc
# ╠═d9defe09-41db-4634-92f2-c115935e1777
# ╠═7d2da9fc-d707-4716-a89c-7395c5423ea4
# ╠═92139ca0-48df-4c75-a34b-59ba1b96ca0a
# ╠═7811fb63-1df9-4470-a281-2bef250ac482
# ╠═b36f6b99-037b-4bcb-8fe4-4e40a1b382dd
# ╠═909cab92-c8ff-41fa-ba20-4405dbf7a3d3
# ╠═f8cd99a9-7cb7-4ec5-b8ba-3b338e5788cd
# ╠═182ea6f2-6b98-4d2d-9464-5b5ea06361f8
# ╠═5c2f4d0e-a63a-47e0-a04b-441603a617b9
# ╠═70cdf14a-a0f4-49fc-ad2b-694ff41130c8
# ╠═84504f28-de98-4d50-ad7d-44e7add1818b
# ╠═581f153f-12dc-446f-8834-8b13085509de
# ╠═28b0e7f3-89d8-4f7b-8f5d-24eac1c86bff
# ╠═19e1b2a7-b5d6-4981-873c-2d847e4fce8b
# ╠═269e71c5-9cb4-4126-8dd8-9b9cb743bce9
# ╠═850f8261-832f-4355-8e25-11a735674615
# ╠═8617e636-a2bc-4d63-a3dd-0debde4d4032
# ╠═abe5b3f0-d0ff-46d5-829d-0093226a1015
# ╠═1be2bdd6-c448-4778-9ad7-6592898b275d
# ╠═0ed90dd7-2354-4721-8559-aa60c647c64e
# ╠═6e3b4da0-30d6-44ef-ac6b-645fb33948fa
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
