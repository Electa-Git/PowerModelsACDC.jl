function add_ref_dcgrid!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (n, nw_ref) in ref[:it][:pm][:nw]
        if haskey(nw_ref, :branchdc)
            nw_ref[:branchdc] = Dict([x for x in nw_ref[:branchdc] if (x.second["status"] == 1 && x.second["fbusdc"] in keys(nw_ref[:busdc]) && x.second["tbusdc"] in keys(nw_ref[:busdc]))])
            # DC grid arcs for DC grid branches
            nw_ref[:arcs_dcgrid_from] = [(i,branch["fbusdc"],branch["tbusdc"]) for (i,branch) in nw_ref[:branchdc]]
            nw_ref[:arcs_dcgrid_to]   = [(i,branch["tbusdc"],branch["fbusdc"]) for (i,branch) in nw_ref[:branchdc]]
            nw_ref[:arcs_dcgrid] = [nw_ref[:arcs_dcgrid_from]; nw_ref[:arcs_dcgrid_to]]
            #bus arcs of the DC grid
            bus_arcs_dcgrid = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            for (l,i,j) in nw_ref[:arcs_dcgrid]
                push!(bus_arcs_dcgrid[i], (l,i,j))
            end
            nw_ref[:bus_arcs_dcgrid] = bus_arcs_dcgrid
        else
            nw_ref[:branchdc] = Dict{String, Any}()
            nw_ref[:arcs_dcgrid] = Dict{String, Any}()
            nw_ref[:arcs_dcgrid_from] = Dict{String, Any}()
            nw_ref[:arcs_dcgrid_to] = Dict{String, Any}()
            nw_ref[:arcs_conv_acdc] = Dict{String, Any}()
            if haskey(nw_ref, :busdc)
                nw_ref[:bus_arcs_dcgrid] = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            else
                nw_ref[:bus_arcs_dcgrid] = Dict{String, Any}()
            end

        end
        if haskey(nw_ref, :convdc)
            #Filter converters & DC branches with status 0 as well as wrong bus numbers
            nw_ref[:convdc] = Dict([x for x in nw_ref[:convdc] if (x.second["status"] == 1 && x.second["busdc_i"] in keys(nw_ref[:busdc]) && x.second["busac_i"] in keys(nw_ref[:bus]))])

            nw_ref[:arcs_conv_acdc] = [(i,conv["busac_i"],conv["busdc_i"]) for (i,conv) in nw_ref[:convdc]]


            # Bus converters for existing ac buses
            bus_convs_ac = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            nw_ref[:bus_convs_ac] = assign_bus_converters!(nw_ref[:convdc], bus_convs_ac, "busac_i")    

            # Bus converters for existing ac buses
            bus_convs_dc = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            nw_ref[:bus_convs_dc]= assign_bus_converters!(nw_ref[:convdc], bus_convs_dc, "busdc_i") 


            # Add DC reference buses
            ref_buses_dc = Dict{String, Any}()
            for (k,v) in nw_ref[:convdc]
                if v["type_dc"] == 2
                    ref_buses_dc["$k"] = v
                end
            end

            if length(ref_buses_dc) == 0
                for (k,v) in nw_ref[:convdc]
                    if v["type_ac"] == 2
                        ref_buses_dc["$k"] = v
                    end
                end
                Memento.warn(_PM._LOGGER, "no reference DC bus found, setting reference bus based on AC bus type")
            end

            for (k,conv) in nw_ref[:convdc]
                conv_id = conv["index"]
                if conv["type_ac"] == 2 && conv["type_dc"] == 1
                    Memento.warn(_PM._LOGGER, "For converter $conv_id is chosen P is fixed on AC and DC side. This can lead to infeasibility in the PF problem.")
                elseif conv["type_ac"] == 1 && conv["type_dc"] == 1
                    Memento.warn(_PM._LOGGER, "For converter $conv_id is chosen P is fixed on AC and DC side. This can lead to infeasibility in the PF problem.")
                end
                convbus_ac = conv["busac_i"]
                if conv["Vmmax"] < nw_ref[:bus][convbus_ac]["vmin"]
                    Memento.warn(_PM._LOGGER, "The maximum AC side voltage of converter $conv_id is smaller than the minimum AC bus voltage")
                end
                if conv["Vmmin"] > nw_ref[:bus][convbus_ac]["vmax"]
                    Memento.warn(_PM._LOGGER, "The miximum AC side voltage of converter $conv_id is larger than the maximum AC bus voltage")
                end
            end

            if length(ref_buses_dc) > 1
                ref_buses_warn = ""
                for (rb) in keys(ref_buses_dc)
                    ref_buses_warn = ref_buses_warn*rb*", "
                end
                Memento.warn(_PM._LOGGER, "multiple reference buses found, i.e. "*ref_buses_warn*"this can cause infeasibility if they are in the same connected component")
            end
            nw_ref[:ref_buses_dc] = ref_buses_dc
            nw_ref[:buspairsdc] = buspair_parameters_dc(nw_ref[:arcs_dcgrid_from], nw_ref[:branchdc], nw_ref[:busdc])
        else
            nw_ref[:convdc] = Dict{String, Any}()
            nw_ref[:busdc] = Dict{String, Any}()
            nw_ref[:bus_convs_dc] = Dict{String, Any}()
            nw_ref[:ref_buses_dc] = Dict{String, Any}()
            nw_ref[:buspairsdc] = Dict{String, Any}()
            # Bus converters for existing ac buses
            bus_convs_ac = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            nw_ref[:bus_convs_ac] = assign_bus_converters!(nw_ref[:convdc], bus_convs_ac, "busac_i")    
        end
    end
end


"compute bus pair level structures"
function buspair_parameters_dc(arcs_dcgrid_from, branches, buses)
    buspair_indexes = collect(Set([(i,j) for (l,i,j) in arcs_dcgrid_from]))

    bp_branch = Dict([(bp, Inf) for bp in buspair_indexes])

    for (l,branch) in branches
        i = branch["fbusdc"]
        j = branch["tbusdc"]

        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end

    buspairs = Dict([((i,j), Dict(
    "branch"=>bp_branch[(i,j)],
    "vm_fr_min"=>buses[i]["Vdcmin"],
    "vm_fr_max"=>buses[i]["Vdcmax"],
    "vm_to_min"=>buses[j]["Vdcmin"],
    "vm_to_max"=>buses[j]["Vdcmax"]
    )) for (i,j) in buspair_indexes])

    return buspairs
end

function find_all_ac_grids(branches_ac, buses_ac)
    ACgrids = Dict{String, Any}()

    if isempty(branches_ac)
        for (i, bus) in buses_ac
            ACgrids["$i"] = Dict{String, Any}()
            ACgrids["$i"]["Buses"] = bus["index"]
        end
    else
        ACgrids["1"] = Dict{String, Any}()
        ACgrids["1"]["Buses"] = [branches_ac[1]["f_bus"] branches_ac[1]["t_bus"]]
        closed_buses = [branches_ac[1]["f_bus"] branches_ac[1]["t_bus"]]
        closed_branches = [1]
        buses = []
        for (i, bus) in buses_ac
            if VERSION < v"0.7.0-"
                buses = cat(1,buses,bus["index"])
            else
                buses = cat(buses, bus["index"], dims = 1)
            end
        end
        grid_id = 1
        iter_id = 1
        branch_iter = 1
        while length(closed_buses) != length(buses) && iter_id < 10
            while branch_iter <= length(branches_ac)
                for (i, branch) in branches_ac
                    for (index, grid) in ACgrids
                        if (branch["t_bus"] in grid["Buses"]) && (branch["f_bus"] in grid["Buses"])
                            if !(branch["index"] in closed_branches)
                                closed_branches = [closed_branches branch["index"]]
                            end
                        elseif (branch["f_bus"] in grid["Buses"])
                            if !(branch["t_bus"] in grid["Buses"])
                                ACgrids["$index"]["Buses"] = [grid["Buses"] branch["t_bus"]]
                                closed_buses = [closed_buses branch["t_bus"]]
                                closed_branches = [closed_branches branch["index"]]
                            end
                        elseif (branch["t_bus"] in grid["Buses"])
                            if !(branch["f_bus"] in grid["Buses"])
                                ACgrids["$index"]["Buses"] = [grid["Buses"] branch["f_bus"]]
                                closed_buses = [closed_buses branch["f_bus"]]
                                closed_branches = [closed_branches branch["index"]]
                            end
                        end
                    end
                end
                branch_iter = branch_iter + 1
            end
            if length(closed_branches) < length(branches_ac)
                grid_id = grid_id + 1
                branch_iter = 1
                ACgrids["$grid_id"] = Dict{String, Any}()
                for (i, branch) in branches_ac
                    if !(branch["index"] in closed_branches) && isempty(ACgrids["$grid_id"])
                        ACgrids["$grid_id"]["Buses"] = [branch["f_bus"] branch["t_bus"]]
                        closed_branches = [closed_branches branch["index"]]
                    end
                end
            end
            iter_id = iter_id + 1 # to avoid infinite loop -> if not all subgrids detected
        end
    end
    return ACgrids
end

function add_candidate_dcgrid!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (n, nw_ref) in ref[:it][:pm][:nw]
        if !haskey(nw_ref, :busdc_ne)
            nw_ref[:busdc_ne] = Dict{String, Any}()
            nw_ref[:ref_buses_dc_ne] = Dict{String, Any}()
        else
            nw_ref[:ref_buses_dc_ne] = Dict{String, Any}()
        end
        if haskey(nw_ref, :branchdc_ne)
            nw_ref[:arcs_dcgrid_from_ne] = [(i,branch["fbusdc"],branch["tbusdc"]) for (i,branch) in nw_ref[:branchdc_ne]]
            nw_ref[:arcs_dcgrid_to_ne]   = [(i,branch["tbusdc"],branch["fbusdc"]) for (i,branch) in nw_ref[:branchdc_ne]]
            nw_ref[:arcs_dcgrid_ne] = [nw_ref[:arcs_dcgrid_from_ne]; nw_ref[:arcs_dcgrid_to_ne]]
            #bus arcs of the DC grid
            bus_arcs_dcgrid_ne = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc_ne]])
            for (l,i,j) in nw_ref[:arcs_dcgrid_ne]
                if haskey(bus_arcs_dcgrid_ne, i)
                    push!(bus_arcs_dcgrid_ne[i], (l,i,j))
                elseif  haskey(nw_ref[:bus_arcs_dcgrid], i)
                    bus_arcs_dcgrid_ne[i] = []
                    push!(bus_arcs_dcgrid_ne[i], (l,i,j))
                else
                    bus_arcs_dcgrid_ne[i] = []
                end
            end
            nw_ref[:bus_arcs_dcgrid_ne] = bus_arcs_dcgrid_ne
            nw_ref[:buspairsdc_ne] = buspair_parameters_dc_ne(nw_ref[:arcs_dcgrid_from_ne], nw_ref[:branchdc_ne], nw_ref[:busdc_ne], nw_ref[:busdc])
        else
            nw_ref[:branchdc_ne] = Dict{String, Any}()
            nw_ref[:arcs_dcgrid_from_ne] = Dict{String, Any}()
            nw_ref[:arcs_dcgrid_to_ne]   = Dict{String, Any}()
            nw_ref[:arcs_dcgrid_ne] = Dict{String, Any}()
            nw_ref[:buspairsdc_ne] = Dict{String, Any}()
            if haskey(nw_ref, :busdc_ne)
                nw_ref[:bus_arcs_dcgrid_ne] = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc_ne]])
            else
                nw_ref[:bus_arcs_dcgrid_ne] = Dict{String, Any}()
            end
        end
        if haskey(nw_ref, :convdc_ne)
            nw_ref[:arcs_conv_acdc_ne] = [(i,conv["busac_i"],conv["busdc_i"]) for (i,conv) in nw_ref[:convdc_ne]]
            nw_ref[:arcs_conv_acdc_acbus_ne] = [(i,conv["busac_i"]) for (i,conv) in nw_ref[:convdc_ne]]
            
            # Bus converters for existing ac buses
            bus_convs_ac_ne = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            nw_ref[:bus_convs_ac_ne] = assign_bus_converters!(nw_ref[:convdc_ne], bus_convs_ac_ne, "busac_i")
            # Bus converters forexisting DC buses
            bus_convs_dc_ne = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            nw_ref[:bus_convs_dc_ne] = assign_bus_converters!(nw_ref[:convdc_ne], bus_convs_dc_ne, "busdc_i")
            # Bus converters for candidate DC buses
            bus_ne_convs_dc_ne = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc_ne]])
            nw_ref[:bus_ne_convs_dc_ne] = assign_bus_converters!(nw_ref[:convdc_ne], bus_ne_convs_dc_ne, "busdc_i")
        else
            nw_ref[:convdc_ne] = Dict{String, Any}()
            nw_ref[:arcs_conv_acdc_ne] = Dict{String, Any}()
            nw_ref[:arcs_conv_acdc_acbus_ne] = Dict{String, Any}()

            # Bus converters for existing ac buses
            bus_convs_ac_ne = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            nw_ref[:bus_convs_ac_ne] = assign_bus_converters!(nw_ref[:convdc_ne], bus_convs_ac_ne, "busac_i")
            # Bus converters forexisting DC buses
            bus_convs_dc_ne = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            nw_ref[:bus_convs_dc_ne] = assign_bus_converters!(nw_ref[:convdc_ne], bus_convs_dc_ne, "busdc_i")
            # Bus converters for candidate DC buses
            bus_ne_convs_dc_ne = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc_ne]])
            nw_ref[:bus_ne_convs_dc_ne] = assign_bus_converters!(nw_ref[:convdc_ne], bus_ne_convs_dc_ne, "busdc_i")
        end
    end
end


"compute bus pair level structures"
function buspair_parameters_dc_ne(arcs_dcgrid_from, branches, busesdc_ne, busesdc)
    buspair_indexes = collect(Set([(i,j) for (l,i,j) in arcs_dcgrid_from]))

    bp_branch = Dict([(bp, Inf) for bp in buspair_indexes])
    for (l,branch) in branches
        i = branch["fbusdc"]
        j = branch["tbusdc"]
        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end
    buspairs = Dict([((i,j), Dict{String,Any}(
    "branch" => nothing,
    "vm_fr_min" => nothing,
    "vm_fr_max" => nothing,
    "vm_to_min" => nothing,
    "vm_to_max" => nothing
    )) for (i,j) in buspair_indexes])

    for (i,j) in buspair_indexes
        buspairs[(i,j)]["branch"] = bp_branch[(i,j)]
        for (k, bus) in busesdc_ne
            if i == bus["busdc_i"]
                buspairs[(i,j)]["vm_fr_min"] = bus["Vdcmin"]
                buspairs[(i,j)]["vm_fr_max"] = bus["Vdcmax"]
            end
            if j == bus["busdc_i"]
                buspairs[(i,j)]["vm_to_min"] = bus["Vdcmin"]
                buspairs[(i,j)]["vm_to_max"] = bus["Vdcmax"]
            end
        end
        for (k, bus) in busesdc
            if i == bus["busdc_i"]
                buspairs[(i,j)]["vm_fr_min"] = bus["Vdcmin"]
                buspairs[(i,j)]["vm_fr_max"] = bus["Vdcmax"]
            end
            if j == bus["busdc_i"]
                buspairs[(i,j)]["vm_to_min"] = bus["Vdcmin"]
                buspairs[(i,j)]["vm_to_max"] = bus["Vdcmax"]
            end
        end
    end

    return buspairs
end


function assign_bus_converters!(convs, dict, key)
    for (i,conv) in convs
        if haskey(dict, conv[key])
            push!(dict[conv[key]], i)
        end
    end
    return dict
end

function assign_bus_generators!(gens, dict, key)
    for (i,gen) in gens
        if haskey(dict, gen[key])
            push!(dict[gen[key]], i)
        end
    end
    return dict
end

# ADD REF MODEL
function ref_add_pst!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:it][:pm][:nw]
        if !haskey(nw_ref, :pst)
            nw_ref[:pst] = Dict()
            Memento.warn(_LOGGER, "required pst data not found")
        end

        nw_ref[:pst] = Dict(x for x in nw_ref[:pst] if (x.second["pst_status"] == 1 && x.second["f_bus"] in keys(nw_ref[:bus]) && x.second["t_bus"] in keys(nw_ref[:bus])))

        nw_ref[:arcs_from_pst] = [(i,pst["f_bus"],pst["t_bus"]) for (i,pst) in nw_ref[:pst]]
        nw_ref[:arcs_to_pst]   = [(i,pst["t_bus"],pst["f_bus"]) for (i,pst) in nw_ref[:pst]]
        nw_ref[:arcs_pst] = [nw_ref[:arcs_from_pst]; nw_ref[:arcs_to_pst]]

        bus_arcs_pst = Dict((i, []) for (i,bus) in nw_ref[:bus])
        for (l,i,j) in nw_ref[:arcs_pst]
            push!(bus_arcs_pst[i], (l,i,j))
        end
        nw_ref[:bus_arcs_pst] = bus_arcs_pst

        if !haskey(nw_ref, :buspairs_pst)
            nw_ref[:buspairs_pst] = calc_buspair_parameters(nw_ref[:bus], nw_ref[:pst], "pst")
        end
    end
end

"Add to `ref` the keys for handling flexible demand"
function ref_add_flex_load!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (n, nw_ref) in ref[:it][_PM.pm_it_sym][:nw]
        # Loads that can be made flexible, depending on investment decision
        nw_ref[:flex_load] = Dict(x for x in nw_ref[:load] if x.second["flex"] == 1)
        # Loads that are not flexible and do not have an associated investment decision
        nw_ref[:fixed_load] = Dict(x for x in nw_ref[:load] if x.second["flex"] == 0)
    end
end

"Add simplified storage model to reference"
function ref_add_storage!(ref::Dict{Symbol,Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:it][:pm][:nw]
        nw_ref[:storage_simple] = Dict(x for x in nw_ref[:storage_simple] if (x.second["status"] == 1 && x.second["storage_bus"] in keys(nw_ref[:bus])))

        bus_storage = Dict((i, Int[]) for (i,bus) in nw_ref[:bus])
        for (i, strg) in nw_ref[:storage_simple]
            push!(bus_storage[strg["storage_bus"]], i)
        end
        nw_ref[:bus_storage] = bus_storage
    end
end

"Add refernce for SSSC"
function ref_add_sssc!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:it][:pm][:nw]
        if !haskey(nw_ref, :sssc)
            nw_ref[:sssc] = Dict()
            Memento.warn(_LOGGER, "required pst data not found")
        end

        nw_ref[:sssc] = Dict(x for x in nw_ref[:sssc] if (x.second["sssc_status"] == 1 && x.second["f_bus"] in keys(nw_ref[:bus]) && x.second["t_bus"] in keys(nw_ref[:bus])))

        nw_ref[:arcs_from_sssc] = [(i,sssc["f_bus"],sssc["t_bus"]) for (i,sssc) in nw_ref[:sssc]]
        nw_ref[:arcs_to_sssc]   = [(i,sssc["t_bus"],sssc["f_bus"]) for (i,sssc) in nw_ref[:sssc]]
        nw_ref[:arcs_sssc] = [nw_ref[:arcs_from_sssc]; nw_ref[:arcs_to_sssc]]

        bus_arcs_sssc = Dict((i, []) for (i,bus) in nw_ref[:bus])
        for (l,i,j) in nw_ref[:arcs_sssc]
            push!(bus_arcs_sssc[i], (l,i,j))
        end
        nw_ref[:bus_arcs_sssc] = bus_arcs_sssc
    end
end

"Add refernce for DC generators"
function ref_add_gendc!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (nw, nw_ref) in ref[:it][:pm][:nw]
        if !haskey(nw_ref, :gendc)
            nw_ref[:gendc] = Dict()
            Memento.warn(_LOGGER, "required dc generator data not found")
        end

        nw_ref[:gendc] = Dict(x for x in nw_ref[:gendc] if (x.second["gen_status"] == 1 && x.second["gen_bus"] in keys(nw_ref[:busdc])))

        # Bus converters for existing ac buses

        bus_gens_dc = Dict((i, Int[]) for (i,bus) in nw_ref[:busdc])
        nw_ref[:bus_gens_dc]= assign_bus_generators!(nw_ref[:gendc], bus_gens_dc, "gen_bus") 
    end
end

# Adapted version from PowerModels to accomodate more branch types
"compute bus pair level data, can be run on data or ref data structures"
function calc_buspair_parameters(buses, branches, element::String)
    bus_lookup = Dict(bus["index"] => bus for (i,bus) in buses if bus["bus_type"] != 4)

    branch_lookup = Dict(branch["index"] => branch for (i,branch) in branches if branch[element*"_status"] == 1 && haskey(bus_lookup, branch["f_bus"]) && haskey(bus_lookup, branch["t_bus"]))

    buspair_indexes = Set((branch["f_bus"], branch["t_bus"]) for (i,branch) in branch_lookup)

    bp_branch = Dict((bp, typemax(Int)) for bp in buspair_indexes)

    bp_angmin = Dict((bp, -Inf) for bp in buspair_indexes)
    bp_angmax = Dict((bp,  Inf) for bp in buspair_indexes)

    for (l,branch) in branch_lookup
        i = branch["f_bus"]
        j = branch["t_bus"]

        bp_angmin[(i,j)] = max(bp_angmin[(i,j)], branch["angmin"])
        bp_angmax[(i,j)] = min(bp_angmax[(i,j)], branch["angmax"])

        bp_branch[(i,j)] = min(bp_branch[(i,j)], l)
    end

    buspairs = Dict((i,j) => Dict(
        "branch"=>bp_branch[(i,j)],
        "angmin"=>bp_angmin[(i,j)],
        "angmax"=>bp_angmax[(i,j)],
        "tap"=>branch_lookup[bp_branch[(i,j)]]["tap"],
        "vm_fr_min"=>bus_lookup[i]["vmin"],
        "vm_fr_max"=>bus_lookup[i]["vmax"],
        "vm_to_min"=>bus_lookup[j]["vmin"],
        "vm_to_max"=>bus_lookup[j]["vmax"]
        ) for (i,j) in buspair_indexes
    )

    # add optional parameters
    for bp in buspair_indexes
        branch = branch_lookup[bp_branch[bp]]
        if haskey(branch, "rate_a")
            buspairs[bp]["rate_a"] = branch["rate_a"]
        end
        if haskey(branch, "c_rating_a")
            buspairs[bp]["c_rating_a"] = branch["c_rating_a"]
        end
    end

    return buspairs
end