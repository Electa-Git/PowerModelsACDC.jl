export run_acdcpf

""
function run_acdcpf(file::String, model_constructor, solver; kwargs...)
    data = PowerModels.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_acdcpf(data::Dict{String,Any}, model_constructor, solver; kwargs...)
end

""
function run_acdcpf(data::Dict{String,Any}, model_constructor, solver; kwargs...)
    pm = PowerModels.build_generic_model(data, model_constructor, post_acdcpf; kwargs...)
    #display(pm)
    return PowerModels.solve_generic_model(pm, solver; solution_builder = get_solution_acdc)
end

""
function post_acdcpf(pm::GenericPowerModel)
    add_ref_dcgrid!(pm)
    PowerModels.variable_voltage(pm, bounded = false)
    PowerModels.variable_generation(pm, bounded = false)
    PowerModels.variable_branch_flow(pm, bounded = false)
    #PowerModels.variable_dcline_flow(pm, bounded = false)
    variable_active_dcbranch_flow(pm, bounded = false)
    variable_dc_converter(pm, bounded = false)
    variable_dcgrid_voltage_magnitude(pm, bounded = false)

    PowerModels.constraint_voltage(pm)
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
            # for c in ref(pm, :bus_convs_ac, i)
            #     constraint_active_conv_setpoint(pm, c)
            # end
        end
    end

    for i in PowerModels.ids(pm, :branch)
        PowerModels.constraint_ohms_yt_from(pm, i)
        PowerModels.constraint_ohms_yt_to(pm, i)
    end
    for i in PowerModels.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid(pm, i)
    end
    for i in PowerModels.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for (c, conv) in PowerModels.ref(pm, :convdc)
        constraint_converter_filter_transformer_reactor(pm, c)
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

    # for (i,dcline) in PowerModels.ref(pm, :dcline)
    #     #constraint_dcline(pm, i) not needed, active power flow fully defined by dc line setpoints
    #     PowerModels.constraint_active_dcline_setpoint(pm, i)
    #
    #     f_bus = ref(pm, :bus)[dcline["f_bus"]]
    #     if f_bus["bus_type"] == 1
    #         PowerModels.constraint_voltage_magnitude_setpoint(pm, f_bus["index"])
    #     end
    #
    #     t_bus = ref(pm, :bus)[dcline["t_bus"]]
    #     if t_bus["bus_type"] == 1
    #         PowerModels.constraint_voltage_magnitude_setpoint(pm, t_bus["index"])
    #     end
    # end
end


#
# for (i,bus_dc) in ref(pm, :ref_buses_dc) # TODO Change naming, it's actually a converter
#     constraint_dc_voltage_magnitude_setpoint(pm, i)
# end
