export run_acdcopf_bf

""
function run_acdcopf_bf(file::String, model_constructor::Type{GenericPowerModel{T}}, solver; kwargs...) where T <: PowerModels.AbstractBFForm
    data = PowerModels.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_acdcopf_bf(data, model_constructor, solver; kwargs...)
end

""
function run_acdcopf_bf(data::Dict{String,Any}, model_constructor::Type{GenericPowerModel{T}}, solver; kwargs...) where T <: PowerModels.AbstractBFForm
    pm = PowerModels.build_model(data, model_constructor, post_acdcopf_bf; kwargs...)
    return PowerModels.optimize_model!(pm, solver; solution_builder = get_solution_acdc)
end

function post_acdcopf_bf(pm::GenericPowerModel)
    add_ref_dcgrid!(pm)
    PowerModels.variable_voltage(pm)
    PowerModels.variable_generation(pm)
    PowerModels.variable_branch_flow(pm)
    PowerModels.variable_branch_current(pm)

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dc_converter(pm)
    variable_dcgrid_voltage_magnitude(pm)

    PowerModels.objective_min_fuel_cost(pm)

    PowerModels.constraint_model_current(pm)
    constraint_voltage_dc(pm)

    for i in PowerModels.ids(pm, :ref_buses)
        PowerModels.constraint_theta_ref(pm, i)
    end

    for i in PowerModels.ids(pm, :bus)
        constraint_kcl_shunt(pm, i)
    end

    for i in PowerModels.ids(pm, :branch)

        PowerModels.constraint_flow_losses(pm, i)
        PowerModels.constraint_voltage_magnitude_difference(pm, i)


        PowerModels.constraint_voltage_angle_difference(pm, i)
        PowerModels.constraint_thermal_limit_from(pm, i)
        PowerModels.constraint_thermal_limit_to(pm, i)
    end
    for i in PowerModels.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid(pm, i)
    end
    for i in PowerModels.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
        constraint_dc_branch_current(pm, i)
    end
    for i in PowerModels.ids(pm, :convdc)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)
        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
        if pm.ref[:nw][pm.cnw][:convdc][i]["islcc"] == 1
            constraint_conv_firing_angle(pm, i)
        end
    end
end
