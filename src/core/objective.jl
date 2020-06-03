""
function objective_min_fuel_cost(pm::_PM.AbstractPowerModel)
    model = _PM.check_cost_models(pm)
    if model == 1
        return objective_min_pwl_fuel_cost(pm)
    elseif model == 2
        return objective_min_polynomial_fuel_cost(pm)
    else
        error("Only cost models of types 1 and 2 are supported at this time, given cost model type of $(model)")
    end

end

""
function objective_min_polynomial_fuel_cost(pm::_PM.AbstractPowerModel)
    order = _PM.calc_max_cost_index(pm.data)-1

    if order == 1
        return _objective_min_polynomial_fuel_cost_linear(pm)
    elseif order == 2
        return _objective_min_polynomial_fuel_cost_quadratic(pm)
    else
        error("cost model order of $(order) is not supported")
    end
end

function _objective_min_polynomial_fuel_cost_linear(pm::_PM.AbstractPowerModel)
    from_idx = Dict()
    for (n, nw_ref) in nws(pm)
        from_idx[n] = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
    end

    return JuMP.@objective(pm.model, Min,
        sum(
            sum(   gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))+
                   gen["cost"][2] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in nws(pm))
    )
end
""
function _objective_min_polynomial_fuel_cost_quadratic(pm::_PM.AbstractPowerModel)
    from_idx = Dict()
    for (n, nw_ref) in nws(pm)
        from_idx[n] = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
    end

    return JuMP.@objective(pm.model, Min,
        sum(
            sum(   gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))^2 +
                   gen["cost"][2]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))+
                   gen["cost"][3] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in nws(pm))
    )
end
""
function objective_min_polynomial_fuel_cost(pm::_PM.AbstractConicModel)
    _PM.check_polynomial_cost_models(pm)
    pg_sqr = Dict()
    for (n, nw_ref) in _PM.nws(pm)
        for cnd in _PM.conductor__PM.ids(pm, n)
            pg_sqr = _PM.var(pm, n, cnd)[:pg_sqr] = JuMP.@variable(pm.model,
                [i in _PM.ids(pm, n, :gen)], base_name="$(n)_$(cnd)_pg_sqr",
                lower_bound = _PM.ref(pm, n, :gen, i, "pmin", cnd)^2,
                upper_bound = _PM.ref(pm, n, :gen, i, "pmax", cnd)^2
            )
            for (i, gen) in nw_ref[:gen]
                JuMP.@constraint(pm.model, [pg_sqr[i], var(pm, n, cnd, :pg, i)/sqrt(2), var(pm, n, cnd, :pg, i)/sqrt(2)] in JuMP.SecondOrderCone())
            end

        end
    end
    print("pipi")
    return JuMP.@objective(pm.model, Min,
        sum(
            sum( gen["cost"][1]*sum(_PM.var(pm, n, cnd, :pg_sqr, i) for cnd in _PM.conductor__PM.ids(pm, n)) +
                 gen["cost"][2]*sum(_PM.var(pm, n, cnd, :pg, i) for cnd in _PM.conductor__PM.ids(pm, n)) +
                 gen["cost"][3] for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in _PM.nws(pm))
    )
end
""
function objective_min_pwl_fuel_cost(pm::_PM.AbstractPowerModel)

    for (n, nw_ref) in _PM.nws(pm)
        pg_cost = _PM.var(pm, n)[:pg_cost] = JuMP.@variable(pm.model,
            [i in _PM.ids(pm, n, :gen)], base_name="$(n)_pg_cost"
        )

        # pwl cost
        gen_lines = _PM.get_lines(nw_ref[:gen])
        for (i, gen) in nw_ref[:gen]
            for line in gen_lines[i]
                JuMP.@constraint(pm.model, pg_cost[i] >= line["slope"]*sum(_PM.var(pm, n, cnd, :pg, i) for cnd in _PM.conductor__PM.ids(pm, n)) + line["intercept"])
            end
        end


    end

    return JuMP.@objective(pm.model, Min,
        sum(
            sum( _PM.var(pm, n,:pg_cost, i) for (i,gen) in nw_ref[:gen])
        for (n, nw_ref) in _PM.nws(pm))
        )
end

##################### TNEP Objective   ###################
function objective_min_cost(pm::_PM.AbstractPowerModel)
        gen_cost = Dict()
        for (n, nw_ref) in _PM.nws(pm)
            for (i,gen) in nw_ref[:gen]
                pg = _PM.var(pm, n, :pg, i)

                if length(gen["cost"]) == 1
                    gen_cost[(n,i)] = gen["cost"][1]
                elseif length(gen["cost"]) == 2
                    gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
                elseif length(gen["cost"]) == 3
                    gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
                else
                    gen_cost[(n,i)] = 0.0
                end
            end
        end

        return JuMP.@objective(pm.model, Min,
            sum(
                sum(conv["cost"]*_PM.var(pm, n, :conv_ne, i) for (i,conv) in nw_ref[:convdc_ne])
                +
                sum(branch["cost"]*_PM.var(pm, n, :branch_ne, i) for (i,branch) in nw_ref[:branchdc_ne])
                +
                sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
                for (n, nw_ref) in _PM.nws(pm)
                    )
        )
end
