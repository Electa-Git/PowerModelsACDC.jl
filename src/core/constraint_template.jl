function constraint_kcl_shunt(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :kcl_p)
        pm.con[:nw][n][:kcl_p] = Dict{Int,ConstraintRef}()
    end
    if !haskey(pm.con[:nw][n], :kcl_q)
        pm.con[:nw][n][:kcl_q] = Dict{Int,ConstraintRef}()
    end

    bus = ref(pm, n, :bus, i)
    bus_arcs = ref(pm, n, :bus_arcs, i)
    bus_arcs_dc = ref(pm, n, :bus_arcs_dc, i)
    bus_gens = ref(pm, n, :bus_gens, i)
    bus_convs_ac = ref(pm, n, :bus_convs_ac, i)

    constraint_kcl_shunt(pm, n, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus["pd"], bus["qd"], bus["gs"], bus["bs"])
end
constraint_kcl_shunt(pm::GenericPowerModel, i::Int) = constraint_kcl_shunt(pm, pm.cnw, i::Int)
