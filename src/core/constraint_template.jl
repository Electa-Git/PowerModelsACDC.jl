
constraint_voltage_dc(pm::GenericPowerModel) = constraint_voltage_dc(pm, pm.cnw)
# no data, so no further templating is needed, constraint goes directly to the formulations


function constraint_kcl_shunt(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :kcl_p)
        pm.con[:nw][n][:kcl_p] = Dict{Int,ConstraintRef}()
    end
    if !haskey(pm.con[:nw][n], :kcl_q)
        pm.con[:nw][n][:kcl_q] = Dict{Int,ConstraintRef}()
    end

    bus = ref(pm, n, :bus, i)
    bus_arcs = ref(pm, n, :bus_arcs, i)
    bus_arcs_dc = ref(pm, n, :bus_arcs_dc, i)
    bus_gens = ref(pm, n, :bus_gens, i)
    bus_convs_ac = ref(pm, n, :bus_convs_ac, i)

    constraint_kcl_shunt(pm, n, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus["pd"], bus["qd"], bus["gs"], bus["bs"])
end
constraint_kcl_shunt(pm::GenericPowerModel, i::Int) = constraint_kcl_shunt(pm, pm.cnw, i::Int)

function constraint_kcl_shunt_dcgrid(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :kcl_dcgrid)
        pm.con[:nw][n][:kcl_dcgrid] = Dict{Int,ConstraintRef}()
    end

    bus_arcs_dcgrid = ref(pm, n, :bus_arcs_dcgrid, i)
    bus_convs_dc = ref(pm, n, :bus_convs_dc, i)
    constraint_kcl_shunt_dcgrid(pm, n, i, bus_arcs_dcgrid, bus_convs_dc)
end
constraint_kcl_shunt_dcgrid(pm::GenericPowerModel, i::Int) = constraint_kcl_shunt_dcgrid(pm, pm.cnw, i::Int)

function constraint_ohms_dc_branch(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :dc_branch)
        pm.con[:nw][n][:dc_branch] = Dict{Int,ConstraintRef}()
    end
    branch = ref(pm, n, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g = 1 / branch["r"]
    p = ref(pm, n, :dcpol)

    constraint_ohms_dc_branch(pm, n, f_bus, t_bus, f_idx, t_idx, g, p)
end
constraint_ohms_dc_branch(pm::GenericPowerModel, i::Int) = constraint_ohms_dc_branch(pm, pm.cnw, i)

function constraint_converter_losses(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_loss)
        pm.con[:nw][n][:conv_loss] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    a = conv["LossA"]
    b = conv["LossB"]
    c = conv["LossCrec"]  #TODO check this (or is it dependent on PF direction)
    constraint_converter_losses(pm, n, i, a, b, c)
end
constraint_converter_losses(pm::GenericPowerModel, i::Int) = constraint_converter_losses(pm, pm.cnw, i::Int)


function constraint_converter_current(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_i)
        pm.con[:nw][n][:conv_i] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_i_sqrt] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    bus_ac = conv["busac_i"]
    bus = ref(pm, n, :bus, bus_ac)
    Vmax = bus["vmax"]
    constraint_converter_current(pm, n, i, bus_ac, Vmax)
end
constraint_converter_current(pm::GenericPowerModel, i::Int) = constraint_converter_current(pm, pm.cnw, i::Int)

""
function constraint_active_conv_setpoint(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_pac)
        pm.con[:nw][n][:conv_pac] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    constraint_active_conv_setpoint(pm, n, conv["index"], conv["P_g"])
end
constraint_active_conv_setpoint(pm::GenericPowerModel, i::Int) = constraint_active_conv_setpoint(pm, pm.cnw, i::Int)

""
function constraint_reactive_conv_setpoint(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_qac)
        pm.con[:nw][n][:conv_qac] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    constraint_reactive_conv_setpoint(pm, n, conv["index"], conv["Q_g"])
end
constraint_reactive_conv_setpoint(pm::GenericPowerModel, i::Int) = constraint_reactive_conv_setpoint(pm, pm.cnw, i::Int)

""
function constraint_dc_voltage_magnitude_setpoint(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :v_dc)
        pm.con[:nw][n][:v_dc] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    constraint_dc_voltage_magnitude_setpoint(pm, n, conv["busdc_i"], conv["Vdcset"])
end
constraint_dc_voltage_magnitude_setpoint(pm::GenericPowerModel, i::Int) = constraint_dc_voltage_magnitude_setpoint(pm, pm.cnw, i::Int)




function constraint_converter_filter_transformer_reactor(pm::GenericPowerModel, n::Int, i::Int)
    if haskey(pm.setting,"zthresh")
        zth = pm.setting["zthresh"]
    else
        zth = 0
    end

    if !haskey(pm.con[:nw][n], :conv_tf_p)
        pm.con[:nw][n][:conv_tf_p] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_tf_q] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_pr_p] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_pr_q] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_kcl_p] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_kcl_q] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    constraint_converter_filter_transformer_reactor(pm, n, i, conv["rtf"], conv["xtf"], conv["bf"], conv["rc"], conv["xc"], conv["busac_i"], Bool(conv["transformer"]), Bool(conv["filter"]), Bool(conv["reactor"]))
end
constraint_converter_filter_transformer_reactor(pm::GenericPowerModel, i::Int) = constraint_converter_filter_transformer_reactor(pm, pm.cnw, i::Int)
