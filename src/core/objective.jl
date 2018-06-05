""
function objective_min_fuel_cost(pm::GenericPowerModel, nws=[pm.cnw])
    model = PowerModels.check_cost_models(pm)

    if model == 1
        return objective_min_pwl_fuel_cost(pm, nws)
    elseif model == 2
        return objective_min_polynomial_fuel_cost(pm, nws)
    else
        error("Only cost models of types 1 and 2 are supported at this time, given cost model type of $(model)")
    end

end

""
function objective_min_polynomial_fuel_cost(pm::GenericPowerModel, nws=[pm.cnw])
    PowerModels.check_polynomial_cost_models(pm)

    pg = Dict(n => pm.var[:nw][n][:pg] for n in nws)
#    dc_p = Dict(n => pm.var[:nw][n][:pconv_tf_fr] for n in nws)

    # from_idx = Dict()
    # for n in nws
    #     ref = pm.ref[:nw][n]
    #     from_idx[n] = Dict(arc[1] => arc for arc in ref[:arcs_conv_acdc])
    # end
    # return @objective(pm.model, Min,
    #     sum(
    #         sum(gen["cost"][1]*pg[n][i]^2 + gen["cost"][2]*pg[n][i] + gen["cost"][3] for (i,gen) in pm.ref[:nw][n][:gen]) +
    #         sum(dcline["cost"][1]*dc_p[n][i]^2 + dcline["cost"][2]*dc_p[n][i] + dcline["cost"][3] for (i,dcline) in pm.ref[:nw][n][:dcline])
    #     for n in nws)
    # )
    return @objective(pm.model, Min,
        sum(
            sum(gen["cost"][1]*pg[n][i]^2 + gen["cost"][2]*pg[n][i] + gen["cost"][3] for (i,gen) in pm.ref[:nw][n][:gen])
        for n in nws)
    )
end

""
function objective_min_polynomial_fuel_cost(pm::GenericPowerModel{T}, nws=[pm.cnw]) where {T <: PowerModels.AbstractConicPowerFormulation}
    PowerModels.check_polynomial_cost_models(pm)

    pg = Dict(n => pm.var[:nw][n][:pg] for n in nws)
#    dc_p = Dict(n => pm.var[:nw][n][:pconv_tf_fr] for n in nws)

    # from_idx = Dict()
    # for n in nws
    #     ref = pm.ref[:nw][n]
    #     from_idx[n] = Dict(arc[1] => arc for arc in ref[:arcs_conv_acdc])
    # end

    pg_sqr = Dict()
    #dc_p_sqr = Dict()
    for n in nws
        pg_sqr[n] = pm.var[:nw][n][:pg_sqr] = @variable(pm.model,
            [i in keys(pm.ref[:nw][n][:gen])], basename="$(n)_pg_sqr",
            lowerbound = pm.ref[:nw][n][:gen][i]["pmin"]^2,
            upperbound = pm.ref[:nw][n][:gen][i]["pmax"]^2
        )
        for (i, gen) in pm.ref[:nw][n][:gen]
            @constraint(pm.model, norm([2*pg[n][i], pg_sqr[n][i]-1]) <= pg_sqr[n][i]+1)
        end

        # dc_p_sqr[n] = pm.var[:nw][n][:dc_p_sqr] = @variable(pm.model,
        #     [i in keys(pm.ref[:nw][n][:dcline])], basename="$(n)_dc_p_sqr",
        #     lowerbound = pm.ref[:nw][n][:dcline][i]["pminf"]^2,
        #     upperbound = pm.ref[:nw][n][:dcline][i]["pmaxf"]^2
        # )
        #
        # for (i, dcline) in pm.ref[:nw][n][:dcline]
        #     @constraint(pm.model, norm([2*dc_p[n][from_idx[n][i]], dc_p_sqr[n][i]-1]) <= dc_p_sqr[n][i]+1)
        # end
    end

    # return @objective(pm.model, Min,
    #     sum(
    #         sum( gen["cost"][1]*pg_sqr[n][i] + gen["cost"][2]*pg[n][i] + gen["cost"][3] for (i,gen) in pm.ref[:nw][n][:gen]) +
    #         sum(dcline["cost"][1]*dc_p_sqr[n][i]^2 + dcline["cost"][2]*dc_p[n][from_idx[n][i]] + dcline["cost"][3] for (i,dcline) in pm.ref[:nw][n][:dcline])
    #     for n in nws)
    # )
    return @objective(pm.model, Min,
        sum(
            sum( gen["cost"][1]*pg_sqr[n][i] + gen["cost"][2]*pg[n][i] + gen["cost"][3] for (i,gen) in pm.ref[:nw][n][:gen])
        for n in nws)
    )
end

""
function objective_min_pwl_fuel_cost(pm::GenericPowerModel, nws=[pm.cnw])
    PowerModels.check_polynomial_cost_models(pm, nws)

    pg = Dict(n => pm.var[:nw][n][:pg] for n in nws)
    #dc_p = Dict(n => pm.var[:nw][n][:pconv_tf_fr] for n in nws)

    pg_cost = Dict()
    #dc_p_cost = Dict()
    for n in nws
        pg_cost[n] = pm.var[:nw][n][:pg_cost] = @variable(pm.model,
            [i in keys(pm.ref[:nw][n][:gen])], basename="$(n)_pg_cost"
        )

        # pwl cost
        gen_lines = PowerModels.get_lines(pm.ref[:nw][n][:gen])
        for (i, gen) in pm.ref[:nw][n][:gen]
            for line in gen_lines[i]
                @constraint(pm.model, pg_cost[n][i] >= line["slope"]*pg[n][i] + line["intercept"])
            end
        end

        dc_p_cost[n] = pm.var[:nw][n][:dc_p_cost] = @variable(pm.model,
            [i in keys(pm.ref[:nw][n][:dcline])], basename="$(n)_dc_p_cost",
        )

        # pwl cost
        # dcline_lines = PowerModels.get_lines(pm.ref[:nw][n][:dcline])
        # for (i, dcline) in pm.ref[:nw][n][:dcline]
        #     for line in dcline_lines[i]
        #         @constraint(pm.model, dc_p_cost[n][i] >= line["slope"]*dc_p[n][i] + line["intercept"])
        #     end
        # end

        #for (i, dcline) in pm.ref[:nw][n][:dcline]
        #    @constraint(pm.model, norm([2*dc_p[n][from_idx[n][i]], dc_p_sqr[n][i]-1]) <= dc_p_sqr[n][i]+1)
        #end
    end

    #from_idx = Dict()
    #for n in nws
    #    ref = pm.ref[:nw][n]
    #    from_idx[n] = Dict(arc[1] => arc for arc in ref[:arcs_from_dc])
    #end

    # return @objective(pm.model, Min,
    #     sum(
    #         sum( pg_cost[n][i] for (i,gen) in pm.ref[:nw][n][:gen]) +
    #         sum( dc_p_cost[n][i] for (i,dcline) in pm.ref[:nw][n][:dcline])
    #     for n in nws)
    # )

    return @objective(pm.model, Min,
        sum(
            sum( pg_cost[n][i] for (i,gen) in pm.ref[:nw][n][:gen])
        for n in nws)
    )
end
