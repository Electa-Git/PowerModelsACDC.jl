export run_acdcopf

""
function run_acdcopf(file::String, model_constructor, solver; kwargs...)
    data = PowerModels.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_acdcopf(data, model_constructor, solver; kwargs...)
end

""
function run_acdcopf(data::Dict{String,Any}, model_constructor, solver; kwargs...)
    pm = PowerModels.build_generic_model(data, model_constructor, post_acdcopf; kwargs...)
    return PowerModels.solve_generic_model(pm, solver; solution_builder = get_solution_acdc)
end

""
function post_acdcopf(pm::GenericPowerModel)
    add_ref_dcgrid!(pm)
    PowerModels.variable_voltage(pm)
    PowerModels.variable_generation(pm)
    PowerModels.variable_branch_flow(pm)

    # dirty, should be improved in the future TODO
    if typeof(pm) <: PowerModels.SOCDFPowerModel
        PowerModels.variable_branch_current(pm)
    end

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dc_converter(pm)
    variable_dcgrid_voltage_magnitude(pm)

    objective_min_fuel_cost(pm)

    PowerModels.constraint_voltage(pm)
    constraint_voltage_dc(pm)

    for i in PowerModels.ids(pm, :ref_buses)
        PowerModels.constraint_theta_ref(pm, i)
    end

    for i in PowerModels.ids(pm, :bus)
        constraint_kcl_shunt(pm, i)
    end

    for i in PowerModels.ids(pm, :branch)
        # dirty, should be improved in the future TODO
        if typeof(pm) <: PowerModels.SOCDFPowerModel
            PowerModels.constraint_flow_losses(pm, i)
            PowerModels.constraint_voltage_magnitude_difference(pm, i)
            PowerModels.constraint_branch_current(pm, i)
        else
            PowerModels.constraint_ohms_yt_from(pm, i)
            PowerModels.constraint_ohms_yt_to(pm, i)
        end

        PowerModels.constraint_voltage_angle_difference(pm, i)

        PowerModels.constraint_thermal_limit_from(pm, i)
        PowerModels.constraint_thermal_limit_to(pm, i)
    end
    for i in PowerModels.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid(pm, i)
    end
    for i in PowerModels.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for i in PowerModels.ids(pm, :convdc)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
    end
end
