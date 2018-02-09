function add_ref_dcgrid!(pm::GenericPowerModel, n::Int)
    # DC grid arcs for DC grid branches
    pm.ref[:nw][n][:arcs_dcgrid_from] = [(i,branch["fbusdc"],branch["tbusdc"]) for (i,branch) in pm.ref[:nw][n][:branchdc]]
    pm.ref[:nw][n][:arcs_dcgrid_to]   = [(i,branch["tbusdc"],branch["fbusdc"]) for (i,branch) in pm.ref[:nw][n][:branchdc]]
    pm.ref[:nw][n][:arcs_dcgrid] = [pm.ref[:nw][n][:arcs_dcgrid_from]; pm.ref[:nw][n][:arcs_dcgrid_to]]


    # bus_convs fro AC side power injection of DC converters
    bus_convs_ac = Dict([(i, []) for (i,bus) in pm.ref[:nw][n][:bus]])
    for (i,conv) in pm.ref[:nw][n][:convdc]
        push!(bus_convs_ac[conv["busac_i"]], i)
    end
    pm.ref[:nw][n][:bus_convs_ac] = bus_convs_ac


    # bus_convs fro AC side power injection of DC converters
    bus_convs_dc = Dict([(i, []) for (i,bus) in pm.ref[:nw][n][:bus]])
    for (i,conv) in pm.ref[:nw][n][:convdc]
        push!(bus_convs_ac[conv["busdc_i"]], i)
    end
    pm.ref[:nw][n][:bus_convs_dc] = bus_convs_dc
end
add_ref_dcgrid!(pm::GenericPowerModel) = add_ref_dcgrid!(pm::GenericPowerModel, pm.cnw)
