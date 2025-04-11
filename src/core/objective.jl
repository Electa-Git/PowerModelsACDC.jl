# " Minimum fuel cost objective using lienar and quadratic terms or piecewise linear functions, as defined in Matpower" 
# function objective_min_fuel_cost(pm::_PM.AbstractPowerModel)
#     model = _PM.check_cost_models(pm)
#     if model == 1
#         return objective_min_pwl_fuel_cost(pm)
#     elseif model == 2
#         return objective_min_polynomial_fuel_cost(pm)
#     else
#         error("Only cost models of types 1 and 2 are supported at this time, given cost model type of $(model)")
#     end

# end

# function objective_min_polynomial_fuel_cost(pm::_PM.AbstractPowerModel)
#     order = _PM.calc_max_cost_index(pm.data)-1

#     if order == 1
#         return _objective_min_polynomial_fuel_cost_linear(pm)
#     elseif order == 2
#         return _objective_min_polynomial_fuel_cost_quadratic(pm)
#     else
#         error("cost model order of $(order) is not supported")
#     end
# end
# function _objective_min_polynomial_fuel_cost_linear(pm::_PM.AbstractPowerModel)
#     from_idx = Dict()
#     for (n, nw_ref) in nws(pm)
#         from_idx[n] = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
#     end

#     return JuMP.@objective(pm.model, Min,
#         sum(
#             sum(   gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))+
#                    gen["cost"][2] for (i,gen) in nw_ref[:gen])
#         for (n, nw_ref) in nws(pm))
#     )
# end
# function _objective_min_polynomial_fuel_cost_quadratic(pm::_PM.AbstractPowerModel)
#     from_idx = Dict()
#     for (n, nw_ref) in nws(pm)
#         from_idx[n] = Dict(arc[1] => arc for arc in nw_ref[:arcs_from_dc])
#     end

#     return JuMP.@objective(pm.model, Min,
#         sum(
#             sum(   gen["cost"][1]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))^2 +
#                    gen["cost"][2]*sum( var(pm, n, c, :pg, i) for c in conductor__PM.ids(pm, n))+
#                    gen["cost"][3] for (i,gen) in nw_ref[:gen])
#         for (n, nw_ref) in nws(pm))
#     )
# end
# function objective_min_polynomial_fuel_cost(pm::_PM.AbstractConicModel)
#     _PM.check_polynomial_cost_models(pm)
#     pg_sqr = Dict()
#     for (n, nw_ref) in _PM.nws(pm)
#         for cnd in _PM.conductor__PM.ids(pm, n)
#             pg_sqr = _PM.var(pm, n, cnd)[:pg_sqr] = JuMP.@variable(pm.model,
#                 [i in _PM.ids(pm, n, :gen)], base_name="$(n)_$(cnd)_pg_sqr",
#                 lower_bound = _PM.ref(pm, n, :gen, i, "pmin", cnd)^2,
#                 upper_bound = _PM.ref(pm, n, :gen, i, "pmax", cnd)^2
#             )
#             for (i, gen) in nw_ref[:gen]
#                 JuMP.@constraint(pm.model, [pg_sqr[i], var(pm, n, cnd, :pg, i)/sqrt(2), var(pm, n, cnd, :pg, i)/sqrt(2)] in JuMP.SecondOrderCone())
#             end

#         end
#     end
#     return JuMP.@objective(pm.model, Min,
#         sum(
#             sum( gen["cost"][1]*sum(_PM.var(pm, n, cnd, :pg_sqr, i) for cnd in _PM.conductor__PM.ids(pm, n)) +
#                  gen["cost"][2]*sum(_PM.var(pm, n, cnd, :pg, i) for cnd in _PM.conductor__PM.ids(pm, n)) +
#                  gen["cost"][3] for (i,gen) in nw_ref[:gen])
#         for (n, nw_ref) in _PM.nws(pm))
#     )
# end
# function objective_min_pwl_fuel_cost(pm::_PM.AbstractPowerModel)

#     for (n, nw_ref) in _PM.nws(pm)
#         pg_cost = _PM.var(pm, n)[:pg_cost] = JuMP.@variable(pm.model,
#             [i in _PM.ids(pm, n, :gen)], base_name="$(n)_pg_cost"
#         )

#         # pwl cost
#         gen_lines = _PM.get_lines(nw_ref[:gen])
#         for (i, gen) in nw_ref[:gen]
#             for line in gen_lines[i]
#                 JuMP.@constraint(pm.model, pg_cost[i] >= line["slope"]*sum(_PM.var(pm, n, cnd, :pg, i) for cnd in _PM.conductor__PM.ids(pm, n)) + line["intercept"])
#             end
#         end


#     end

#     return JuMP.@objective(pm.model, Min,
#         sum(
#             sum( _PM.var(pm, n,:pg_cost, i) for (i,gen) in nw_ref[:gen])
#         for (n, nw_ref) in _PM.nws(pm))
#         )
# end

# ##################### TNEP Objective   ###################
# " Objective consisting of generation cost + investment costs of HVDC lines and converters"
# function objective_min_cost(pm::_PM.AbstractPowerModel)
#         gen_cost = Dict()
#         for (n, nw_ref) in _PM.nws(pm)
#             for (i,gen) in nw_ref[:gen]
#                 pg = _PM.var(pm, n, :pg, i)

#                 if length(gen["cost"]) == 1
#                     gen_cost[(n,i)] = gen["cost"][1]
#                 elseif length(gen["cost"]) == 2
#                     gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
#                 elseif length(gen["cost"]) == 3
#                     gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
#                 else
#                     gen_cost[(n,i)] = 0.0
#                 end
#             end
#         end

#         return JuMP.@objective(pm.model, Min,
#             sum(
#                 sum(conv["cost"]*_PM.var(pm, n, :conv_ne, i) for (i,conv) in nw_ref[:convdc_ne])
#                 +
#                 sum(branch["cost"]*_PM.var(pm, n, :branchdc_ne, i) for (i,branch) in nw_ref[:branchdc_ne])
#                 +
#                 sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
#                 for (n, nw_ref) in _PM.nws(pm)
#                     )
#         )
# end

# " Objective consisting of generation cost + investment costs of HVDC lines and converters + investment costs of AC lines"
# function objective_min_cost_acdc(pm::_PM.AbstractPowerModel)
#         gen_cost = Dict()
#         for (n, nw_ref) in _PM.nws(pm)
#             for (i,gen) in nw_ref[:gen]
#                 pg = _PM.var(pm, n, :pg, i)

#                 if length(gen["cost"]) == 1
#                     gen_cost[(n,i)] = gen["cost"][1]
#                 elseif length(gen["cost"]) == 2
#                     gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
#                 elseif length(gen["cost"]) == 3
#                     gen_cost[(n,i)] = gen["cost"][2]*pg + gen["cost"][3]
#                 else
#                     gen_cost[(n,i)] = 0.0
#                 end
#             end
#         end

#         return JuMP.@objective(pm.model, Min,
#             sum(
#                 sum(conv["cost"]*_PM.var(pm, n, :conv_ne, i) for (i,conv) in nw_ref[:convdc_ne])
#                 +
#                 sum(branch["construction_cost"]*_PM.var(pm, n, :branch_ne, i) for (i,branch) in nw_ref[:ne_branch])
#                 +
#                 sum(branch["cost"]*_PM.var(pm, n, :branchdc_ne, i) for (i,branch) in nw_ref[:branchdc_ne])
#                 +
#                 sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] )
#                 for (n, nw_ref) in _PM.nws(pm)
#                     )
#         )
# end


function objective_min_operational_cost(pm::_PM.AbstractPowerModel)
    if haskey(pm.setting, "objective_components")
        components = pm.setting["objective_components"]
    else
        components = ["gen"]
    end   

    gen_cost = calc_gen_cost(pm; components = components)
    load_cost_red, load_cost_curt = calc_load_operational_cost(pm; components = components)

    return JuMP.@objective(pm.model, Min,
        sum( sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( load_cost_curt[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( load_cost_red[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in _PM.nws(pm))
    )
end

function objective_min_operational_capex_cost(pm::_PM.AbstractPowerModel)
    if haskey(pm.setting, "objective_components")
        components = pm.setting["objective_components"]
    else
        components = ["gen", "dc_converter", "dc_branch", "ac_branch"]
    end   

    gen_cost = calc_gen_cost(pm; components = components)
    load_cost_red, load_cost_curt = calc_load_operational_cost(pm; components = components)
    ac_branch_cost, dc_branch_cost, dc_converter_cost = calculate_capex_cost(pm; components = components)

    return JuMP.@objective(pm.model, Min,
        sum( sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( load_cost_curt[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( load_cost_red[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( ac_branch_cost[(n,i)] for (i,branch) in nw_ref[:ne_branch]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( dc_branch_cost[(n,i)] for (i,branch) in nw_ref[:branchdc_ne]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( dc_converter_cost[(n,i)] for (i,conv) in nw_ref[:convdc_ne]) for (n, nw_ref) in _PM.nws(pm))
    )
end

function calc_gen_cost(pm::_PM.AbstractPowerModel; report::Bool=true, components = ["gen"])
    gen_cost = Dict()
    if any(components .== "gen")
        for (n, nw_ref) in _PM.nws(pm)
            for (i,gen) in nw_ref[:gen]
                pg = _PM.var(pm, n, :pg, i)

                if length(gen["cost"]) == 1
                    gen_cost[(n,i)] = gen["cost"][1]
                elseif length(gen["cost"]) == 2
                    gen_cost[(n,i)] = gen["cost"][1]*pg + gen["cost"][2]
                elseif length(gen["cost"]) == 3
                    gen_cost[(n,i)] = gen["cost"][1]*pg^2 + gen["cost"][2]*pg + gen["cost"][3]
                else
                    gen_cost[(n,i)] = 0.0
                end
            end
        end
    else
        for (n, nw_ref) in _PM.nws(pm)
            for (i,gen) in nw_ref[:gen]
                gen_cost[(n,i)] = 0.0
            end
        end
    end
    return gen_cost
end

function calc_load_operational_cost(pm::_PM.AbstractPowerModel; components = [])
    load_cost_red = Dict()
    load_cost_curt = Dict()
    if any(components .== "demand")
        for (n, nw_ref) in _PM.nws(pm)
            for (i,load) in nw_ref[:load]
                p_red = _PM.var(pm, n, :pred, i)
                p_curt = _PM.var(pm, n, :pcurt, i)
                load_cost_red[(n,i)] = load["cost_red"]  * p_red
                load_cost_curt[(n,i)] = load["cost_curt"] * p_curt
            end
        end
    else
        for (n, nw_ref) in _PM.nws(pm)
            for (i,load) in nw_ref[:load]
                load_cost_red[(n,i)] = 0.0
                load_cost_curt[(n,i)] = 0.0
            end
        end
    end

    return load_cost_red, load_cost_curt
end


function objective_min_rd_cost(pm::_PM.AbstractPowerModel; report::Bool=true)
    if haskey(pm.setting, "objective_components")
        components = pm.setting["objective_components"]
    else
        components = []
    end 

    gen_cost = Dict()
    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            dpg_up = _PM.var(pm, n, :dpg_up, i)
            dpg_down = _PM.var(pm, n, :dpg_down, i)
            gen_cost[(n,i)] = gen["rdcost_up"][1] * dpg_up +  gen["rdcost_down"][1] * dpg_down
        end
    end

    load_cost_red, load_cost_curt = calc_load_operational_cost(pm; components = components)

    return JuMP.@objective(pm.model, Min,
        sum( sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen] ) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( load_cost_curt[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( load_cost_red[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in _PM.nws(pm))
    )
end


function objective_min_rd_cost_inertia(pm::_PM.AbstractPowerModel; report::Bool=true)
    if haskey(pm.setting, "objective_components")
        components = pm.setting["objective_components"]
    else
        components = []
    end 
    gen_cost = Dict()

    for (n, nw_ref) in _PM.nws(pm)
        for (i,gen) in nw_ref[:gen]
            alpha_g =  _PM.var(pm, n, :alpha_g, i)
            gen_cost[(n,i)] = (alpha_g - gen["dispatch_status"]) * gen["start_up_cost"] * gen["pmax"] #+  (1 - alpha_g) * gen["rdcost_down"][1] * dpg_down
        end
    end

    load_cost_red, load_cost_curt = calc_load_operational_cost(pm; components = components)

    return JuMP.@objective(pm.model, Min,
        sum( sum( gen_cost[(n,i)] for (i,gen) in nw_ref[:gen]) for (n, nw_ref) in _PM.nws(pm)) 
        + sum( sum( load_cost_curt[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in _PM.nws(pm))
        + sum( sum( load_cost_red[(n,i)] for (i,load) in nw_ref[:load]) for (n, nw_ref) in _PM.nws(pm))
    )
end

function calculate_capex_cost(pm::_PM.AbstractPowerModel; components = [])
    ac_branch_cost = Dict()
    dc_branch_cost = Dict()
    dc_converter_cost = Dict()
    if any(components .== "ac_branch")
        for (n, nw_ref) in _PM.nws(pm)
            for (i,branch) in nw_ref[:ne_branch]
                ac_branch_cost[(n,i)] = branch["construction_cost"] * _PM.var(pm, n, :branch_ne, i)
            end
        end
    else
        for (n, nw_ref) in _PM.nws(pm)
            for (i,branch) in nw_ref[:ne_branch]
                ac_branch_cost[(n,i)] = 0.0
            end
        end
    end
    if any(components .== "dc_branch")
        for (n, nw_ref) in _PM.nws(pm)
            for (i,branch) in nw_ref[:branchdc_ne]
                dc_branch_cost[(n,i)] = branch["cost"] * _PM.var(pm, n, :branchdc_ne, i)
            end
        end
    else
        for (n, nw_ref) in _PM.nws(pm)
            for (i,branch) in nw_ref[:branchdc_ne]
                dc_branch_cost[(n,i)] = 0.0
            end
        end
    end
    if any(components .== "dc_converter")
        for (n, nw_ref) in _PM.nws(pm)
            for (i,conv) in nw_ref[:convdc_ne]
                dc_converter_cost[(n,i)] = conv["cost"] * _PM.var(pm, n, :conv_ne, i)
            end
        end
    else
        for (n, nw_ref) in _PM.nws(pm)
            for (i,conv) in nw_ref[:convdc_ne]
                dc_converter_cost[(n,i)] = 0.0
            end
        end
    end
    return ac_branch_cost, dc_branch_cost, dc_converter_cost
end