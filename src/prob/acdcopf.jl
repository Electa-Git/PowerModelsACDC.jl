export run_acdcopf

""
function run_acdcopf(data, model_constructor, solver; kwargs...)
    pm = PowerModels.build_generic_model(data, model_constructor, post_acdcopf; kwargs...)
    return PowerModels.solve_generic_model(pm, solver; solution_builder = get_solution_acdc)
end

""
function post_acdcopf(pm::GenericPowerModel)
    add_ref_dcgrid!(pm)
    PowerModels.variable_voltage(pm)
    PowerModels.variable_generation(pm)
    PowerModels.variable_branch_flow(pm)
    PowerModels.variable_dcline_flow(pm)
    variable_active_dcbranch_flow(pm)
    variable_dc_converter(pm)
    variable_dcgrid_voltage_magnitude(pm)
    display(pm.var)
    #variable_transformation(pm)

    PowerModels.objective_min_fuel_cost(pm)

    PowerModels.constraint_voltage(pm)
    for i in PowerModels.ids(pm, :ref_buses)
        PowerModels.constraint_theta_ref(pm, i)
    end

    for i in PowerModels.ids(pm, :bus)
        constraint_kcl_shunt(pm, i)  # this one needs to be redefined condidering converter injections
    end

    # for i in PowerModels.ids(pm, :dcbus)
    #     constraint_dcgrid_kcl_shunt(pm, i)
    # end

    for i in PowerModels.ids(pm, :branch)
        branch = PowerModels.ref(pm, :branch, i)
        PowerModels.constraint_ohms_yt_from(pm, i)
        PowerModels.constraint_ohms_yt_to(pm, i)
        PowerModels.constraint_voltage_angle_difference(pm, i)

        PowerModels.constraint_thermal_limit_from(pm, i)
        PowerModels.constraint_thermal_limit_to(pm, i)
    end
    for i in PowerModels.ids(pm, :dcline)
        PowerModels.constraint_dcline(pm, i)
    end
end
