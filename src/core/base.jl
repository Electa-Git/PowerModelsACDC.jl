function add_ref_dcgrid!(pm::GenericPowerModel, n::Int)
    # DC grid arcs for DC grid branches
    pm.ref[:nw][n][:arcs_dcgrid_from] = [(i,branch["fbusdc"],branch["tbusdc"]) for (i,branch) in pm.ref[:nw][n][:branchdc]]
    pm.ref[:nw][n][:arcs_dcgrid_to]   = [(i,branch["tbusdc"],branch["fbusdc"]) for (i,branch) in pm.ref[:nw][n][:branchdc]]
    pm.ref[:nw][n][:arcs_dcgrid] = [pm.ref[:nw][n][:arcs_dcgrid_from]; pm.ref[:nw][n][:arcs_dcgrid_to]]

    #bus arcs of the DC grid
    bus_arcs_dcgrid = Dict([(i, []) for (i,bus) in pm.ref[:nw][n][:busdc]])
    for (l,i,j) in pm.ref[:nw][n][:arcs_dcgrid]
        push!(bus_arcs_dcgrid[i], (l,i,j))
    end
    pm.ref[:nw][n][:bus_arcs_dcgrid] = bus_arcs_dcgrid


    # bus_convs for AC side power injection of DC converters
    bus_convs_ac = Dict([(i, []) for (i,bus) in pm.ref[:nw][n][:bus]])
    for (i,conv) in pm.ref[:nw][n][:convdc]
        push!(bus_convs_ac[conv["busac_i"]], i)
    end
    pm.ref[:nw][n][:bus_convs_ac] = bus_convs_ac


    # bus_convs for AC side power injection of DC converters
    bus_convs_dc = Dict([(i, []) for (i,bus) in pm.ref[:nw][n][:busdc]])
    for (i,conv) in pm.ref[:nw][n][:convdc]
        push!(bus_convs_dc[conv["busdc_i"]], i)
    end
    pm.ref[:nw][n][:bus_convs_dc] = bus_convs_dc

    # Add DC reference buses
    ref_buses_dc = Dict()
    for (k,v) in pm.ref[:nw][n][:convdc]
        if v["type_dc"] == 2
            ref_buses_dc[k] = v
        end
    end

    if length(ref_buses_dc) == 0
        for (k,v) in pm.ref[:nw][n][:convdc]
            if v["type_ac"] == 2
                ref_buses_dc[k] = v
            end
        end
        warn("no reference DC bus found, setting bus as reference based on generator AC bus type)")
    end

    if length(ref_buses_dc) > 1
        warn("multiple reference buses found, $(keys(ref_buses_dc)), this can cause infeasibility if they are in the same connected component")
    end

    pm.ref[:nw][n][:ref_buses_dc] = ref_buses_dc
end
add_ref_dcgrid!(pm::GenericPowerModel) = add_ref_dcgrid!(pm::GenericPowerModel, pm.cnw)
