function add_ref_dcgrid!(ref::Dict{Symbol,<:Any}, data::Dict{String,<:Any})
    for (n, nw_ref) in ref[:nw]
        if haskey(nw_ref, :convdc)
            #Filter converters & DC branches with status 0 as well as wrong bus numbers
            nw_ref[:convdc] = Dict([x for x in nw_ref[:convdc] if (x.second["status"] == 1 && x.second["busdc_i"] in keys(nw_ref[:busdc]) && x.second["busac_i"] in keys(nw_ref[:bus]))])
            nw_ref[:branchdc] = Dict([x for x in nw_ref[:branchdc] if (x.second["status"] == 1 && x.second["fbusdc"] in keys(nw_ref[:busdc]) && x.second["tbusdc"] in keys(nw_ref[:busdc]))])

            # DC grid arcs for DC grid branches
            nw_ref[:arcs_dcgrid_from] = [(i,branch["fbusdc"],branch["tbusdc"]) for (i,branch) in nw_ref[:branchdc]]
            nw_ref[:arcs_dcgrid_to]   = [(i,branch["tbusdc"],branch["fbusdc"]) for (i,branch) in nw_ref[:branchdc]]
            nw_ref[:arcs_dcgrid] = [nw_ref[:arcs_dcgrid_from]; nw_ref[:arcs_dcgrid_to]]
            nw_ref[:arcs_conv_acdc] = [(i,conv["busac_i"],conv["busdc_i"]) for (i,conv) in nw_ref[:convdc]]
            #bus arcs of the DC grid
            bus_arcs_dcgrid = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            for (l,i,j) in nw_ref[:arcs_dcgrid]
                push!(bus_arcs_dcgrid[i], (l,i,j))
            end
            nw_ref[:bus_arcs_dcgrid] = bus_arcs_dcgrid

            # bus_convs for AC side power injection of DC converters
            bus_convs_ac = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            for (i,conv) in nw_ref[:convdc]
                push!(bus_convs_ac[conv["busac_i"]], i)
            end
            nw_ref[:bus_convs_ac] = bus_convs_ac

            # bus_convs for AC side power injection of DC converters
            bus_convs_dc = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            for (i,conv) in nw_ref[:convdc]
                push!(bus_convs_dc[conv["busdc_i"]], i)
            end
            nw_ref[:bus_convs_dc] = bus_convs_dc
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


            # if haskey(pm.setting, "find_all_ac_grids") && pm.tetting["find_all_ac_grids"] == true
            #     ACgrids = find_all_ac_grids(nw_ref[:branch], nw_ref[:bus])
            #     for (i, grid) in ACgrids
            #         a = 0
            #         for (j, bus) in nw_ref[:ref_buses]
            #             if (bus["bus_i"] in grid["Buses"])
            #                 a = 1
            #             end
            #         end
            #         if a == 0
            #             Memento.warn(_PM._LOGGER, "Grid $i does not have any voltage reference bus, this might cause infeasibility")
            #         end
            #     end
            # end
            nw_ref[:ref_buses_dc] = ref_buses_dc
            nw_ref[:buspairsdc] = buspair_parameters_dc(nw_ref[:arcs_dcgrid_from], nw_ref[:branchdc], nw_ref[:busdc])
        else
            nw_ref[:convdc] = Dict{String, Any}()
            nw_ref[:busdc] = Dict{String, Any}()
            nw_ref[:branchdc] = Dict{String, Any}()
            # DC grid arcs for DC grid branches
            nw_ref[:arcs_dcgrid] = Dict{String, Any}()
            nw_ref[:arcs_dcgrid_from] = Dict{String, Any}()
            nw_ref[:arcs_dcgrid_to] = Dict{String, Any}()
            nw_ref[:arcs_conv_acdc] = Dict{String, Any}()
            nw_ref[:bus_arcs_dcgrid] = Dict{String, Any}()
            bus_convs_ac = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            for (i,conv) in nw_ref[:convdc]
                push!(bus_convs_ac[conv["busac_i"]], i)
            end
            nw_ref[:bus_convs_ac] = bus_convs_ac
            nw_ref[:bus_convs_dc] = Dict{String, Any}()
            nw_ref[:ref_buses_dc] = Dict{String, Any}()
            nw_ref[:buspairsdc] = Dict{String, Any}()
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
        connections = []
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
    for (n, nw_ref) in ref[:nw]
        if haskey(nw_ref, :convdc_ne)
            nw_ref[:arcs_dcgrid_from_ne] = [(i,branch["fbusdc"],branch["tbusdc"]) for (i,branch) in nw_ref[:branchdc_ne]]
            nw_ref[:arcs_dcgrid_to_ne]   = [(i,branch["tbusdc"],branch["fbusdc"]) for (i,branch) in nw_ref[:branchdc_ne]]
            nw_ref[:arcs_dcgrid_ne] = [nw_ref[:arcs_dcgrid_from_ne]; nw_ref[:arcs_dcgrid_to_ne]]
            nw_ref[:arcs_conv_acdc_ne] = [(i,conv["busac_i"],conv["busdc_i"]) for (i,conv) in nw_ref[:convdc_ne]]
            nw_ref[:arcs_conv_acdc_acbus_ne] = [(i,conv["busac_i"]) for (i,conv) in nw_ref[:convdc_ne]]
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
            # bus_convs for AC side power injection of DC converters
            bus_convs_ac = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            for (i,conv) in nw_ref[:convdc_ne]
                push!(bus_convs_ac[conv["busac_i"]], i)
            end
            nw_ref[:bus_convs_ac_ne] = bus_convs_ac


            # add new converters to existting DC buses
            bus_convs_dc_ne = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc]])
            for (i,conv) in nw_ref[:convdc_ne]
                if haskey(bus_convs_dc_ne, conv["busdc_i"])
                    push!(bus_convs_dc_ne, i)
                end
            end
            nw_ref[:bus_convs_dc_ne] = bus_convs_dc_ne
            # Bus converters for candidate DC buses
            bus_ne_convs_dc_ne = Dict([(bus["busdc_i"], []) for (i,bus) in nw_ref[:busdc_ne]])
            for (i,conv) in nw_ref[:convdc_ne]
                if haskey(bus_ne_convs_dc_ne, conv["busdc_i"])
                    push!(bus_ne_convs_dc_ne[conv["busdc_i"]], i)
                end
            end
            nw_ref[:bus_ne_convs_dc_ne] = bus_ne_convs_dc_ne
            nw_ref[:ref_buses_dc_ne] = Dict{String, Any}()
            nw_ref[:buspairsdc_ne] = buspair_parameters_dc_ne(nw_ref[:arcs_dcgrid_from_ne], nw_ref[:branchdc_ne], nw_ref[:busdc_ne], nw_ref[:busdc])
        else
            nw_ref[:convdc_ne] = Dict{String, Any}()
            nw_ref[:busdc_ne] = Dict{String, Any}()
            nw_ref[:branchdc_ne] = Dict{String, Any}()
            # DC grid arcs for DC grid branches
            nw_ref[:arcs_dcgrid_ne] = Dict{String, Any}()
            nw_ref[:arcs_conv_acdc_ne] = Dict{String, Any}()
            nw_ref[:bus_arcs_dcgrid_ne] = Dict{String, Any}()
            bus_convs_ac = Dict([(i, []) for (i,bus) in nw_ref[:bus]])
            for (i,conv) in nw_ref[:convdc_ne]
                push!(bus_convs_ac[conv["busac_i"]], i)
            end
            nw_ref[:bus_convs_ac_ne] = bus_convs_ac
            nw_ref[:bus_convs_dc_ne] = Dict{String, Any}()
            nw_ref[:ref_buses_dc_ne] = Dict{String, Any}()
            nw_ref[:buspairsdc_ne] = Dict{String, Any}()
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
