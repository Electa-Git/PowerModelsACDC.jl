export run_acdcpf

""
function run_acdcpf(file::String, model_type::Type, solver; kwargs...)
    data = _PM.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_acdcpf(data::Dict{String,Any}, model_type, solver; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function run_acdcpf(data::Dict{String,Any}, model_type::Type, solver; kwargs...)
    return _PM.run_model(data, model_type, solver, post_acdcpf; ref_extensions = [add_ref_dcgrid!], kwargs...)
end

""
function post_acdcpf(pm::_PM.AbstractPowerModel)
    _PM.variable_voltage(pm, bounded = false)
    _PM.variable_generation(pm, bounded = false)
    _PM.variable_branch_flow(pm, bounded = false)

    # dirty, should be improved in the future TODO
    if typeof(pm) <: _PM.SOCBFPowerModel
        _PM.variable_branch_current(pm, bounded = false)
    end

    variable_active_dcbranch_flow(pm, bounded = false)
    variable_dcbranch_current(pm, bounded = false)
    variable_dc_converter(pm, bounded = false)
    variable_dcgrid_voltage_magnitude(pm, bounded = false)

    _PM.constraint_model_voltage(pm)
    constraint_voltage_dc(pm)


    for (i,bus) in _PM.ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm, i)
        _PM.constraint_voltage_magnitude_setpoint(pm, i)
    end

    for (i, bus) in _PM.ref(pm, :bus)# _PM.ids(pm, :bus)
        constraint_kcl_shunt(pm, i)
        # PV Bus Constraints
        if length(_PM.ref(pm, :bus_gens, i)) > 0 && !(i in _PM.ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2
            _PM.constraint_voltage_magnitude_setpoint(pm, i)
            for j in _PM.ref(pm, :bus_gens, i)
                _PM.constraint_active_gen_setpoint(pm, j)
            end
        end
    end

    for i in _PM.ids(pm, :branch)
        # dirty, should be improved in the future TODO
        if typeof(pm) <: _PM.SOCBFPowerModel
            _PM.constraint_flow_losses(pm, i)
            _PM.constraint_voltage_magnitude_difference(pm, i)
            _PM.constraint_branch_current(pm, i)
        else
            _PM.constraint_ohms_yt_from(pm, i)
            _PM.constraint_ohms_yt_to(pm, i)
        end
    end
    for i in _PM.ids(pm, :busdc)
        constraint_kcl_shunt_dcgrid(pm, i)
    end
    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end
    for (c, conv) in _PM.ref(pm, :convdc)
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
