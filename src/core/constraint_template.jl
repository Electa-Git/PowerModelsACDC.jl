
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
    bus_loads = ref(pm, n, :bus_loads, i)
    bus_shunts = ref(pm, n, :bus_shunts, i)

    pd = Dict(k => v["pd"] for (k,v) in ref(pm, n, :load))
    qd = Dict(k => v["qd"] for (k,v) in ref(pm, n, :load))

    gs = Dict(k => v["gs"] for (k,v) in ref(pm, n, :shunt))
    bs = Dict(k => v["bs"] for (k,v) in ref(pm, n, :shunt))

    constraint_kcl_shunt(pm, n, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
end
constraint_kcl_shunt(pm::GenericPowerModel, i::Int) = constraint_kcl_shunt(pm, pm.cnw, i::Int)

function constraint_kcl_shunt_dcgrid(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :kcl_dcgrid)
        pm.con[:nw][n][:kcl_dcgrid] = Dict{Int,ConstraintRef}()
    end

    bus_arcs_dcgrid = ref(pm, n, :bus_arcs_dcgrid, i)
    bus_convs_dc = ref(pm, n, :bus_convs_dc, i)
    pd = ref(pm, n, :busdc, i)["Pdc"]
    constraint_kcl_shunt_dcgrid(pm, n, i, bus_arcs_dcgrid, bus_convs_dc, pd)
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

    p = ref(pm, n, :dcpol)

    constraint_ohms_dc_branch(pm, n, f_bus, t_bus, f_idx, t_idx, branch["r"], p)
end
constraint_ohms_dc_branch(pm::GenericPowerModel, i::Int) = constraint_ohms_dc_branch(pm, pm.cnw, i)

function constraint_converter_losses(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_loss)
        pm.con[:nw][n][:conv_loss] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    a = conv["LossA"]
    b = conv["LossB"]
    c = conv["LossCinv"]
    constraint_converter_losses(pm, n, i, a, b, c)
end
constraint_converter_losses(pm::GenericPowerModel, i::Int) = constraint_converter_losses(pm, pm.cnw, i::Int)


function constraint_converter_current(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_i)
        pm.con[:nw][n][:conv_i] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_i_sqrt] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    Vmax = conv["Vmmax"]
    Imax = conv["Imax"]
    constraint_converter_current(pm, n, i, Vmax, Imax)
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

function constraint_conv_reactor(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_pr_p_fr)
        pm.con[:nw][n][:conv_pr_p] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_pr_p_to] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_pr_q] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    constraint_conv_reactor(pm, n, i, conv["rc"], conv["xc"], Bool(conv["reactor"]))
end
constraint_conv_reactor(pm::GenericPowerModel, i::Int) = constraint_conv_reactor(pm, pm.cnw, i::Int)

function constraint_conv_filter(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_kcl_p)
        pm.con[:nw][n][:conv_kcl_p] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_kcl_q] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    constraint_conv_filter(pm, n, i, conv["bf"], Bool(conv["filter"]) )
end
constraint_conv_filter(pm::GenericPowerModel, i::Int) = constraint_conv_filter(pm, pm.cnw, i::Int)

function constraint_conv_transformer(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_tf_p_fr)
        pm.con[:nw][n][:conv_tf_p_fr] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_tf_q_fr] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_tf_p_to] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_tf_q_to] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    constraint_conv_transformer(pm, n, i, conv["rtf"], conv["xtf"], conv["busac_i"], conv["tm"], Bool(conv["transformer"]))
end
constraint_conv_transformer(pm::GenericPowerModel, i::Int) = constraint_conv_transformer(pm, pm.cnw, i::Int)

function constraint_conv_firing_angle(pm::GenericPowerModel, n::Int, i::Int)
    if !haskey(pm.con[:nw][n], :conv_cosphi)
        pm.con[:nw][n][:conv_cosphi] = Dict{Int,ConstraintRef}()
        pm.con[:nw][n][:conv_sinphi] = Dict{Int,ConstraintRef}()
    end
    if !haskey(pm.con[:nw][n], :conv_socphi)
        pm.con[:nw][n][:conv_socphi] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, n, :convdc, i)
    S = conv["Pacrated"]
    P1 = cos(0) * S
    Q1 = sin(0) * S
    P2 = cos(pi) * S
    Q2 = sin(pi) * S
    constraint_conv_firing_angle(pm, n, i, S, P1, Q1, P2, Q2)
end
constraint_conv_firing_angle(pm::GenericPowerModel, i::Int) = constraint_conv_firing_angle(pm, pm.cnw, i::Int)
