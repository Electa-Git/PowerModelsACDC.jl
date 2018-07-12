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
    PowerModels.check_polynomial_cost_models(pm)
    return @objective(pm.model, Min,
        sum(
            sum(   gen["cost"][1]*sum(PowerModels.var(pm, n, cnd, :pg, i) for cnd in PowerModels.conductor_ids(pm, n))^2 +
                   gen["cost"][2]*sum(PowerModels.var(pm, n, cnd, :pg, i) for cnd in PowerModels.conductor_ids(pm, n))+
                   gen["cost"][3] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in PowerModels.nws(pm))
    )


    # PowerModels.check_polynomial_cost_models(pm)
    #
    # return @objective(pm.model, Min,
    #     sum(
    #         sum(gen["cost"][1]*sum(PowerModels.var(pm, n, cnd, :pg, i)^2 + gen["cost"][2]*PowerModels.var(pm, n, cnd, :pg, i) + gen["cost"][3] for (i,gen) in pm.ref[:nw][n][:gen])
    #         for cnd in PowerModels.conductor_ids(pm, n))
    #             for n in nws)
    # )
end

""
function objective_min_polynomial_fuel_cost(pm::GenericPowerModel{T}) where {T <: PowerModels.AbstractConicPowerFormulation}
    PowerModels.check_polynomial_cost_models(pm)
    pg_sqr = Dict()
    # dc_p_sqr = Dict()
    for (n, nw_ref) in PowerModels.nws(pm)
        for cnd in PowerModels.conductor_ids(pm, n)
            pg_sqr = PowerModels.var(pm, n, cnd)[:pg_sqr] = @variable(pm.model,
                [i in PowerModels.ids(pm, n, :gen)], basename="$(n)_$(cnd)_pg_sqr",
                lowerbound = PowerModels.ref(pm, n, :gen, i, "pmin", cnd)^2,
                upperbound = PowerModels.ref(pm, n, :gen, i, "pmax", cnd)^2
            )
            for (i, gen) in nw_ref[:gen]
                @constraint(pm.model, norm([2*var(pm, n, cnd, :pg, i), pg_sqr[i]-1]) <= pg_sqr[i]+1)
            end

            # dc_p_sqr = var(pm, n, cnd)[:p_dc_sqr] = @variable(pm.model,
            #     [i in ids(pm, n, :dcline)], basename="$(n)_$(h)_dc_p_sqr",
            #     lowerbound = ref(pm, n, :dcline, i, "pminf", cnd)^2,
            #     upperbound = ref(pm, n, :dcline, i, "pmaxf", cnd)^2
            # )
            #
            # for (i, dcline) in nw_ref[:dcline]
            #     @constraint(pm.model, norm([2*var(pm, n, cnd, :p_dc)[from_idx[n][i]], dc_p_sqr[i]-1]) <= dc_p_sqr[i]+1)
            # end
        end
    end

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
            [i in PowerModels.ids(pm, n, :gen)], basename="$(n)_pg_cost"
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
