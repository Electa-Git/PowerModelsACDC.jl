""
function objective_min_fuel_cost(pm::GenericPowerModel)
    model = PowerModels.check_cost_models(pm)
    if model == 1
        return objective_min_pwl_fuel_cost(pm)
    elseif model == 2
        return objective_min_polynomial_fuel_cost(pm)
    else
        error("Only cost models of types 1 and 2 are supported at this time, given cost model type of $(model)")
    end

end

""
function objective_min_polynomial_fuel_cost(pm::GenericPowerModel)
    order = PowerModels.calc_max_cost_index(pm.data)-1

    if order == 1
        return _objective_min_polynomial_fuel_cost_linear(pm)
    elseif order == 2
        return _objective_min_polynomial_fuel_cost_quadratic(pm)
    else
        error("cost model order of $(order) is not supported")
    end
end

function _objective_min_polynomial_fuel_cost_linear(pm::GenericPowerModel)
    from_idx = Dict()
    for (n, nw_ref) in nws(pm)
        from_idx[n] = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
    end

    return @objective(pm.model, Min,
        sum(
            sum(   gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor_ids(pm, n))+
                   gen["cost"][2] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in nws(pm))
    )
end
""
function _objective_min_polynomial_fuel_cost_quadratic(pm::GenericPowerModel)
    from_idx = Dict()
    for (n, nw_ref) in nws(pm)
        from_idx[n] = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
    end

    return @objective(pm.model, Min,
        sum(
            sum(   gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor_ids(pm, n))^2 +
                   gen["cost"][2]*sum( var(pm, n, c, :pg, i) for c in conductor_ids(pm, n))+
                   gen["cost"][3] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in nws(pm))
    )
end
""
function objective_min_polynomial_fuel_cost(pm::GenericPowerModel{T}) where {T <: PowerModels.AbstractConicPowerFormulation}
    PowerModels.check_polynomial_cost_models(pm)
    pg_sqr = Dict()
    for (n, nw_ref) in PowerModels.nws(pm)
        for cnd in PowerModels.conductor_ids(pm, n)
            pg_sqr = PowerModels.var(pm, n, cnd)[:pg_sqr] = @variable(pm.model,
                [i in PowerModels.ids(pm, n, :gen)], base_name="$(n)_$(cnd)_pg_sqr",
                lower_bound = PowerModels.ref(pm, n, :gen, i, "pmin", cnd)^2,
                upper_bound = PowerModels.ref(pm, n, :gen, i, "pmax", cnd)^2
            )
            for (i, gen) in nw_ref[:gen]
                # @constraint(pm.model, norm([2*var(pm, n, cnd, :pg, i), pg_sqr[i]-1]) <= pg_sqr[i]+1)
                @constraint(pm.model, [pg_sqr[i], var(pm, n, cnd, :pg, i)/sqrt(2), var(pm, n, cnd, :pg, i)/sqrt(2)] in JuMP.SecondOrderCone())
            end

        end
    end
    print("pipi")
    return @objective(pm.model, Min,
        sum(
            sum( gen["cost"][1]*sum(PowerModels.var(pm, n, cnd, :pg_sqr, i) for cnd in PowerModels.conductor_ids(pm, n)) +
                 gen["cost"][2]*sum(PowerModels.var(pm, n, cnd, :pg, i) for cnd in PowerModels.conductor_ids(pm, n)) +
                 gen["cost"][3] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in PowerModels.nws(pm))
    )
end
""
function objective_min_pwl_fuel_cost(pm::GenericPowerModel)

    for (n, nw_ref) in PowerModels.nws(pm)
        pg_cost = PowerModels.var(pm, n)[:pg_cost] = @variable(pm.model,
            [i in PowerModels.ids(pm, n, :gen)], base_name="$(n)_pg_cost"
        )

        # pwl cost
        gen_lines = PowerModels.get_lines(nw_ref[:gen])
        for (i, gen) in nw_ref[:gen]
            for line in gen_lines[i]
                @constraint(pm.model, pg_cost[i] >= line["slope"]*sum(PowerModels.var(pm, n, cnd, :pg, i) for cnd in PowerModels.conductor_ids(pm, n)) + line["intercept"])
            end
        end


    end

    return @objective(pm.model, Min,
        sum(
            sum( PowerModels.var(pm, n,:pg_cost, i) for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in PowerModels.nws(pm))
        )
end
