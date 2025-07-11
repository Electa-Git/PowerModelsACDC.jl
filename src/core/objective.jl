"Sum of generation, demand reduction and demand shedding costs"
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

"Sum of generation, demand reduction, demand shedding and AC/DC equipment investment costs"
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

function calc_load_operational_cost(pm::_PM.AbstractPowerModel; components = [], network_ids = "all")
    load_cost_red = Dict()
    load_cost_curt = Dict()
    if network_ids == "all"
        n_ids  = _PM.nw_ids(pm)
    else
        n_ids =  pm.ref[:it][:pm][:hour_ids]
    end
    if any(components .== "demand")
        println(n_ids)
        for n in n_ids
            for (i,load) in _PM.nws(pm)[n][:load]
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

"Sum of generation redisptach costs"
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

"Sum of generation redisptach and generaor start-up costs costs to ensure minimum inertia level"
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

"Sum of generator operational and start-up costs, FCR and FFR costs, demand reduction and demand shedding costs"
function objective_min_cost_fcuc(pm::_PM.AbstractPowerModel; report::Bool=true, droop = false)
    gen_cost = calc_gen_cost(pm)
    ffr_cost, fcr_cost = calc_reserve_cost(pm; droop = droop) #; components = ["fcr", "ffr"]) 
    load_cost_red, load_cost_curt = calc_load_operational_cost(pm; components = ["demand"], network_ids = "hours")

    return JuMP.@objective(pm.model, Min,
        sum( sum( gen_cost[(n,i)] for (i,gen) in _PM.nws(pm)[n][:gen]) for n in pm.ref[:it][:pm][:hour_ids]) 
        + sum( sum( load_cost_curt[(n,i)] for (i,load) in _PM.nws(pm)[n][:load]) for n in pm.ref[:it][:pm][:hour_ids])
        + sum( sum( load_cost_red[(n,i)] for (i,load) in _PM.nws(pm)[n][:load]) for n in pm.ref[:it][:pm][:hour_ids])
        + sum( sum( ffr_cost[(n,i)] for (i,conv) in _PM.nws(pm)[n][:convdc]) for n in pm.ref[:it][:pm][:hour_ids])
        + sum( sum( fcr_cost[(n,i)] for (i,gen) in nw_ref[:gen]) for (n, nw_ref) in _PM.nws(pm))
    )
end


function calc_reserve_cost(pm; droop = false)
    ffr_cost = Dict()
    fcr_cost = Dict()

    for (n, network) in pm.ref[:it][:pm][:nw]
        for (i,gen) in _PM.nws(pm)[n][:gen]
            if n == 1 || droop == false
                fcr_cost[(n,i)] = 0.0
            else
                pgd =  _PM.var(pm, n, :pg_droop_abs, i)
                fcr_cost[(n,i)] = (pgd * network[:frequency_parameters]["fcr_cost"])
            end
        end

        for (c, conv) in _PM.nws(pm)[n][:convdc]
            if n == 1
                ffr_cost[(n,c)] = 0.0
            else
                pconv =  _PM.var(pm, n, :pconv_in_abs, c)
                ffr_cost[(n,c)] = (pconv * network[:frequency_parameters]["ffr_cost"]) * 1/2  # as it is summed-up
            end
        end
    end
    return ffr_cost, fcr_cost
end