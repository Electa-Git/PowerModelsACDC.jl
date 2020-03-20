export run_acdcpf

""
function run_acdcpf(file::String, model_type::Type, solver; kwargs...)
    data = PowerModels.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_acdcpf(data::Dict{String,Any}, model_type, solver; kwargs...)
end

""
function run_acdcpf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    pm = PowerModels.build_model(data, model_type, post_acdcpf; kwargs...)
    #display(pm)
    return PowerModels.optimize_model!(pm, solver; solution_builder = get_solution_acdc)
end

""
function post_acdcpf(pm::AbstractPowerModel)
    add_ref_dcgrid!(pm)
    PowerModels.variable_voltage(pm, bounded = false)
    PowerModels.variable_generation(pm, bounded = false)
    PowerModels.variable_branch_flow(pm, bounded = false)

    # dirty, should be improved in the future TODO
    if typeof(pm) <: PowerModels.SOCBFPowerModel
        PowerModels.variable_branch_current(pm, bounded = false)
    end

    variable_active_dcbranch_flow(pm, bounded = false)
    variable_dcbranch_current(pm, bounded = false)
    variable_dc_converter(pm, bounded = false)
    variable_dcgrid_voltage_magnitude(pm, bounded = false)

    PowerModels.constraint_model_voltage(pm)
    constraint_voltage_dc(pm)


    for (i,bus) in ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        PowerModels.constraint_theta_ref(pm, i)
        PowerModels.constraint_voltage_magnitude_setpoint(pm, i)
    end

    for (i, bus) in ref(pm, :bus)# PowerModels.ids(pm, :bus)
        constraint_kcl_shunt(pm, i)
        # PV Bus Constraints
        if length(ref(pm, :bus_gens, i)) > 0 && !(i in ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            PowerModels.constraint_voltage_magnitude_setpoint(pm, i)
            for j in ref(pm, :bus_gens, i)
                PowerModels.constraint_active_gen_setpoint(pm, j)
            end
        end
    end

    for i in PowerModels.ids(pm, :branch)
        # dirty, should be improved in the future TODO
        if typeof(pm) <: PowerModels.SOCBFPowerModel
            PowerModels.constraint_flow_losses(pm, i)
            PowerModels.constraint_voltage_magnitude_difference(pm, i)
            PowerModels.constraint_branch_current(pm, i)
        else
            PowerModels.constraint_ohms_yt_from(pm, i)
            PowerModels.constraint_ohms_yt_to(pm, i)
        end
    end
    for i in PowerModels.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid(pm, i)
    end
    for i in PowerModels.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for (c, conv) in PowerModels.ref(pm, :convdc)
        #constraint_converter_filter_transformer_reactor(pm, c)
        constraint_conv_transformer(pm, c)
        constraint_conv_reactor(pm, c)
        constraint_conv_filter(pm, c)
        if conv["type_dc"] == 2
            constraint_dc_voltage_magnitude_setpoint(pm, c)
            constraint_reactive_conv_setpoint(pm, c)
        else
            if conv["type_ac"] == 2
                constraint_active_conv_setpoint(pm, c)
            else
                constraint_active_conv_setpoint(pm, c)
                constraint_reactive_conv_setpoint(pm, c)
            end
        end
        constraint_converter_losses(pm, c)
        constraint_converter_current(pm, c)
    end
end
