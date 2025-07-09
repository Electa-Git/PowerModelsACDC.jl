function solve_uc(data::Dict{String,Any}, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(data, model_type, optimizer, build_uc; ref_extensions = [add_ref_dcgrid!, ref_add_flex_load!, ref_add_pst!, ref_add_sssc!], kwargs...)
end

""
function build_uc(pm::_PM.AbstractPowerModel)
    for (n, networks) in pm.ref[:it][:pm][:nw]
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)
        _PM.constraint_model_voltage(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dc_converter(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_generator_states(pm; nw = n, uc = true)
        variable_flexible_demand(pm; nw = n)
        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)
        variable_storage_on_off(pm; nw = n)
        constraint_voltage_dc(pm; nw = n)
    end

    for (n, networks) in pm.ref[:it][:pm][:nw]
        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i; nw = n)
        end
    
        for i in _PM.ids(pm, n, :bus)
            constraint_power_balance_ac(pm, i; nw = n)
        end
        
        for i in _PM.ids(pm, n, :branch)
            _PM.constraint_ohms_yt_from(pm, i; nw = n)
            _PM.constraint_ohms_yt_to(pm, i; nw = n)
            _PM.constraint_voltage_angle_difference(pm, i; nw = n)
            _PM.constraint_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_thermal_limit_to(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :busdc)
            constraint_power_balance_dc(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :branchdc)
            constraint_ohms_dc_branch(pm, i; nw = n)
        end
        for i in _PM.ids(pm, n, :convdc)
            constraint_converter_losses(pm, i; nw = n)
            constraint_converter_current(pm, i; nw = n)
            constraint_conv_transformer(pm, i; nw = n)
            constraint_conv_reactor(pm, i; nw = n)
            constraint_conv_filter(pm, i; nw = n)
        end
    
        for i in _PM.ids(pm, n, :flex_load)
            constraint_total_flexible_demand(pm, i; nw = n)
        end
    
        for i in _PM.ids(pm, n, :gen)
            constraint_generator_on_off(pm, i; nw = n, use_status = false)
            contstraint_unit_commitment(pm, i; nw = n)
            if haskey(pm.setting, "uc_reserves") && pm.setting["uc_reserves"] == true
                constraint_unit_commitment_reserves(pm, i; nw = n)
            end
        end
    
        for i in _PM.ids(pm, n, :pst)
            constraint_ohms_y_from_pst(pm, i; nw = n)
            constraint_ohms_y_to_pst(pm, i; nw = n)
            constraint_limits_pst(pm, i; nw = n)
        end


        for i in _PM.ids(pm, n, :sssc)
            constraint_ohms_y_from_sssc(pm, i; nw = n)
            constraint_ohms_y_to_sssc(pm, i; nw = n)
            constraint_limits_sssc(pm, i; nw = n)
        end

        if haskey(pm.setting, "fix_cross_border_flows") && pm.setting["fix_cross_border_flows"] == true
            if !haskey(pm.setting, "borders")
                borders = [i for i in _PM.ids(pm, n,:borders)]
            else
                borders = [i for i in pm.setting["borders"]]
            end
            for i in borders
                constraint_fixed_xb_flows(pm, i; nw = n)
            end
        end

        if haskey(_PM.ref(pm, n), :storage)
            storage_constraints(pm, n; uc = true)
        end
    end

    objective_min_cost_uc(pm)
end

"Sum of generator operational and start-up costs, demand reduction and demand shedding costs"
function objective_min_cost_uc(pm::_PM.AbstractPowerModel; report::Bool=true, droop = false)
    gen_cost = Dict()

    for n in pm.ref[:it][:pm][:hour_ids]
        for (i,gen) in _PM.nws(pm)[n][:gen]
            beta_g =  _PM.var(pm, n, :beta_g, i)
            alpha_g =  _PM.var(pm, n, :alpha_g, i)
            pg =  _PM.var(pm, n, :pg, i)
            gen_cost[(n,i)] = (beta_g * gen["start_up_cost"] * gen["pmax"]) + (gen["cost"][1]*pg + (gen["cost"][2] * alpha_g))
        end
    end

    load_cost_red, load_cost_curt = calc_load_operational_cost_uc(pm)

    return JuMP.@objective(pm.model, Min,
        sum( sum( gen_cost[(n,i)] for (i,gen) in _PM.nws(pm)[n][:gen]) for n in pm.ref[:it][:pm][:hour_ids]) 
        + sum( sum( load_cost_curt[(n,i)] for (i,load) in _PM.nws(pm)[n][:load]) for n in pm.ref[:it][:pm][:hour_ids])
        + sum( sum( load_cost_red[(n,i)] for (i,load) in _PM.nws(pm)[n][:load]) for n in pm.ref[:it][:pm][:hour_ids])
    )
end