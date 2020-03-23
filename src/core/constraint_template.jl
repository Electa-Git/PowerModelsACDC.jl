constraint_voltage_dc(pm::AbstractPowerModel) = constraint_voltage_dc(pm, pm.cnw) # TODO check this
# no data, so no further templating is needed, constraint goes directly to the formulations
function constraint_kcl_shunt(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :kcl_p)
        PowerModels.con(pm, nw)[:kcl_p] = Dict{Int,ConstraintRef}()
    end
    if !haskey(PowerModels.con(pm, nw), :kcl_q)
        PowerModels.con(pm, nw)[:kcl_q] = Dict{Int,ConstraintRef}()
    end

    bus = ref(pm, nw, :bus, i)
    bus_arcs = ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = ref(pm, nw, :bus_gens, i)
    bus_convs_ac = ref(pm, nw, :bus_convs_ac, i)
    bus_loads = ref(pm, nw, :bus_loads, i)
    bus_shunts = ref(pm, nw, :bus_shunts, i)

    pd = Dict(k => ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_kcl_shunt(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, pd, qd, gs, bs)
end

function constraint_kcl_shunt_dcgrid(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :kcl_dcgrid)
        PowerModels.con(pm, nw)[:kcl_dcgrid] = Dict{Int,ConstraintRef}()
    end

    bus_arcs_dcgrid = ref(pm, nw, :bus_arcs_dcgrid, i)
    bus_convs_dc = ref(pm, nw, :bus_convs_dc, i)
    pd = ref(pm, nw, :busdc, i)["Pdc"]
    constraint_kcl_shunt_dcgrid(pm, nw, i, bus_arcs_dcgrid, bus_convs_dc, pd)
end
#
function constraint_ohms_dc_branch(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :dc_branch)
        PowerModels.con(pm, nw)[:dc_branch] = Dict{Int,ConstraintRef}()
    end
    branch = ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    p = ref(pm, nw, :dcpol)

    constraint_ohms_dc_branch(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p)
end
#
function constraint_converter_losses(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_loss)
        PowerModels.con(pm, nw)[:conv_loss] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_loss_aux] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_loss_plmax] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    a = conv["LossA"]
    b = conv["LossB"]
    c = conv["LossCinv"]
    plmax = conv["LossA"] + conv["LossB"] * conv["Pacrated"] + conv["LossCinv"] * (conv["Pacrated"])^2
    constraint_converter_losses(pm, nw, i, a, b, c, plmax)
end

function constraint_converter_current(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_i)
        PowerModels.con(pm, nw)[:conv_i] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_i_sqrt] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    Vmax = conv["Vmmax"]
    Imax = conv["Imax"]
    constraint_converter_current(pm, nw, i, Vmax, Imax)
end

function constraint_active_conv_setpoint(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_pac)
        PowerModels.con(pm, nw)[:conv_pac] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    constraint_active_conv_setpoint(pm, nw, conv["index"], conv["P_g"])
end

function constraint_reactive_conv_setpoint(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_qac)
        PowerModels.con(pm, nw)[:conv_qac] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    constraint_reactive_conv_setpoint(pm, nw, conv["index"], conv["Q_g"])
end
""
function constraint_dc_voltage_magnitude_setpoint(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :v_dc)
        PowerModels.con(pm, nw)[:v_dc] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    constraint_dc_voltage_magnitude_setpoint(pm, nw, conv["busdc_i"], conv["Vdcset"])
end

#
function constraint_conv_reactor(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_pr_p_fr)
        PowerModels.con(pm, nw)[:conv_pr_p] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_pr_p_to] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_pr_q] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    constraint_conv_reactor(pm, nw, i, conv["rc"], conv["xc"], Bool(conv["reactor"]))
end

#
function constraint_conv_filter(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_kcl_p)
        PowerModels.con(pm, nw)[:conv_kcl_p] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_kcl_q] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    constraint_conv_filter(pm, nw, i, conv["bf"], Bool(conv["filter"]) )
end

#
function constraint_conv_transformer(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_tf_p_fr)
        PowerModels.con(pm, nw)[:conv_tf_p_fr] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_tf_q_fr] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_tf_p_to] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_tf_q_to] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    constraint_conv_transformer(pm, nw, i, conv["rtf"], conv["xtf"], conv["busac_i"], conv["tm"], Bool(conv["transformer"]))
end

#
function constraint_conv_firing_angle(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_cosphi)
        PowerModels.con(pm, nw)[:conv_cosphi] = Dict{Int,ConstraintRef}()
        PowerModels.con(pm, nw)[:conv_sinphi] = Dict{Int,ConstraintRef}()
    end
    if !haskey(PowerModels.con(pm, nw), :conv_socphi)
        PowerModels.con(pm, nw)[:conv_socphi] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    S = conv["Pacrated"]
    P1 = cos(0) * S
    Q1 = sin(0) * S
    P2 = cos(pi) * S
    Q2 = sin(pi) * S
    constraint_conv_firing_angle(pm, nw, i, S, P1, Q1, P2, Q2)
end

function constraint_dc_branch_current(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    vpu = 1;
    branch = ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)

    ccm_max = (PowerModels.comp_start_value(ref(pm, nw, :branchdc, i), "rateA", 0.0) / vpu)^2

    p = ref(pm, nw, :dcpol)
    constraint_dc_branch_current(pm, nw, f_bus, f_idx, ccm_max, p)
end

function constraint_dc_droop_control(pm::AbstractPowerModel, i::Int; nw::Int=pm.cnw)
    if !haskey(PowerModels.con(pm, nw), :conv_dc_droop)
        PowerModels.con(pm, nw)[:conv_dc_droop] = Dict{Int,ConstraintRef}()
    end
    conv = ref(pm, nw, :convdc, i)
    bus = ref(pm, nw, :busdc, conv["busdc_i"])

    constraint_dc_droop_control(pm, nw, i, conv["busdc_i"], conv["Vdcset"], conv["Pdcset"], conv["droop"])
end
