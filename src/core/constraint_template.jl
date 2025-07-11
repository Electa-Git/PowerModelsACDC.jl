function constraint_voltage_dc(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    constraint_voltage_dc(pm, nw)
end
# no data, so no further templating is needed, constraint goes directly to the formulations
function constraint_power_balance_ac(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_pst = _PM.ref(pm, nw, :bus_arcs_pst, i)
    bus_arcs_sssc = _PM.ref(pm, nw, :bus_arcs_sssc, i)
    bus_arcs_sw = _PM.ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)
    bus_storage = _PM.ref(pm, nw, :bus_storage, i)
    bus_convs_ac = _PM.ref(pm, nw, :bus_convs_ac, i)

    bus_pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_power_balance_ac(pm, nw, i, bus_arcs, bus_arcs_pst, bus_arcs_sssc, bus_convs_ac, bus_arcs_sw, bus_gens, bus_storage, bus_loads, bus_gs, bus_bs)
end


function constraint_current_balance_ac(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = _PM.ref(pm, nw, :bus, i)
    bus_arcs = _PM.ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = _PM.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = _PM.ref(pm, nw, :bus_gens, i)
    bus_convs_ac = _PM.ref(pm, nw, :bus_convs_ac, i)
    bus_loads = _PM.ref(pm, nw, :bus_loads, i)
    bus_shunts = _PM.ref(pm, nw, :bus_shunts, i)

    pd = Dict(k => _PM.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => _PM.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => _PM.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => _PM.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)

    constraint_current_balance_ac(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, bus_loads, bus_shunts, gs, bs)
end

function constraint_power_balance_dc(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus_arcs_dcgrid = _PM.ref(pm, nw, :bus_arcs_dcgrid, i)
    bus_convs_dc = _PM.ref(pm, nw, :bus_convs_dc, i)
    pd = _PM.ref(pm, nw, :busdc, i)["Pdc"]
    constraint_power_balance_dc(pm, nw, i, bus_arcs_dcgrid, bus_convs_dc, pd)
end

function constraint_current_balance_dc(pm::_PM.AbstractIVRModel, i::Int; nw::Int=_PM.nw_id_default)
    bus_arcs_dcgrid = _PM.ref(pm, nw, :bus_arcs_dcgrid, i)
    bus_convs_dc = _PM.ref(pm, nw, :bus_convs_dc, i)
    pd = _PM.ref(pm, nw, :busdc, i)["Pdc"]
    constraint_current_balance_dc(pm, nw, bus_arcs_dcgrid, bus_convs_dc, pd)
end

#
function constraint_ohms_dc_branch(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    p = _PM.ref(pm, nw, :dcpol)

    constraint_ohms_dc_branch(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p)
end
#
function constraint_converter_losses(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    a = conv["LossA"]
    b = conv["LossB"]
    c = conv["LossCinv"]
    plmax = conv["LossA"] + conv["LossB"] * conv["Pacrated"] + conv["LossCinv"] * (conv["Pacrated"])^2
    constraint_converter_losses(pm, nw, i, a, b, c, plmax)
end

function constraint_converter_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    Vmax = conv["Vmmax"]
    Imax = conv["Imax"]
    constraint_converter_current(pm, nw, i, Vmax, Imax)
end

function constraint_active_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default, slack = nothing)
    conv = _PM.ref(pm, nw, :convdc, i)
    constraint_active_conv_setpoint(pm, nw, conv["index"], conv["P_g"], slack)
end

function constraint_reactive_conv_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    constraint_reactive_conv_setpoint(pm, nw, conv["index"], conv["Q_g"])
end
""
function constraint_dc_voltage_magnitude_setpoint(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    constraint_dc_voltage_magnitude_setpoint(pm, nw, conv["busdc_i"], conv["Vdcset"])
end

#
function constraint_conv_reactor(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    constraint_conv_reactor(pm, nw, i, conv["rc"], conv["xc"], Bool(conv["reactor"]))
end

#
function constraint_conv_filter(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    constraint_conv_filter(pm, nw, i, conv["bf"], Bool(conv["filter"]) )
end

#
function constraint_conv_transformer(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    constraint_conv_transformer(pm, nw, i, conv["rtf"], conv["xtf"], conv["busac_i"], conv["tm"], Bool(conv["transformer"]))
end

#
function constraint_conv_firing_angle(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    S = conv["Pacrated"]
    P1 = cos(0) * S
    Q1 = sin(0) * S
    P2 = cos(pi) * S
    Q2 = sin(pi) * S
    constraint_conv_firing_angle(pm, nw, i, S, P1, Q1, P2, Q2)
end

function constraint_dc_branch_current(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    vpu = 1;
    branch = _PM.ref(pm, nw, :branchdc, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)

    ccm_max = (_PM.comp_start_value(_PM.ref(pm, nw, :branchdc, i), "rateA", 0.0) / vpu)^2

    p = _PM.ref(pm, nw, :dcpol)
    constraint_dc_branch_current(pm, nw, f_bus, f_idx, ccm_max, p)
end

function constraint_dc_droop_control(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    bus = _PM.ref(pm, nw, :busdc, conv["busdc_i"])
    type = conv["type_dc"]

    if type == 3
        constraint_dc_droop_control(pm, nw, i, conv["busdc_i"], conv["Vdcset"], conv["Pdcset"], conv["droop"]; dc_power = true)
    elseif type == 4
        constraint_dc_droop_control(pm, nw, i, conv["busdc_i"], conv["Vdcset"], conv["Pacset"], conv["droop"]; dc_power = false)
    else
        Memento.warn(_PM._LOGGER, "Invalid setting for DC converter control type, droop constraint will be ignored")
    end
end

function constraint_ac_voltage_droop_control(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = _PM.ref(pm, nw, :convdc, i)
    bus = _PM.ref(pm, nw, :bus, conv["busac_i"])
    v_ref = conv["Vtar"]
    constraint_ac_voltage_droop_control(pm, nw, i, bus["index"], v_ref, conv["Q_g"], conv["kq_droop"])
end

############## TNEP Constraints #####################
function constraint_voltage_dc_ne(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default)
    constraint_voltage_dc_ne(pm, nw)
end
# no data, so no further templating is needed, constraint goes directly to the formulations
function constraint_power_balance_acdc_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus = PowerModels.ref(pm, nw, :bus, i)
    bus_arcs = PowerModels.ref(pm, nw, :bus_arcs, i)
    bus_arcs_ne = PowerModels.ref(pm, nw, :ne_bus_arcs, i)
    bus_arcs_dc = PowerModels.ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = PowerModels.ref(pm, nw, :bus_gens, i)
    bus_convs_ac = PowerModels.ref(pm, nw, :bus_convs_ac, i)
    bus_convs_ac_ne = PowerModels.ref(pm, nw, :bus_convs_ac_ne, i)
    bus_loads = PowerModels.ref(pm, nw, :bus_loads, i)
    bus_shunts = PowerModels.ref(pm, nw, :bus_shunts, i)
    bus_arcs_pst = _PM.ref(pm, nw, :bus_arcs_pst, i)
    bus_storage = _PM.ref(pm, nw, :bus_storage, i)
    bus_arcs_sssc = _PM.ref(pm, nw, :bus_arcs_sssc, i)


    pd = Dict(k => PowerModels.ref(pm, nw, :load, k, "pd") for k in bus_loads)
    qd = Dict(k => PowerModels.ref(pm, nw, :load, k, "qd") for k in bus_loads)

    gs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bs = Dict(k => PowerModels.ref(pm, nw, :shunt, k, "bs") for k in bus_shunts)
    constraint_power_balance_acdc_ne(pm, nw, i, bus_arcs, bus_arcs_ne, bus_arcs_dc, bus_arcs_pst, bus_arcs_sssc, bus_gens, bus_convs_ac, bus_convs_ac_ne, bus_loads, bus_storage, bus_shunts, gs, bs)
end

function constraint_converter_limit_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bigM = 1.2
    conv = PowerModels.ref(pm, nw, :convdc_ne, i)
    pmax = conv["Pacrated"]
    pmin = -conv["Pacrated"]
    qmax = conv["Qacrated"]
    qmin = -conv["Qacrated"]
    pmaxdc = conv["Pacrated"] * bigM
    pmindc = -conv["Pacrated"] * bigM
    imax = conv["Imax"]

    constraint_converter_limit_on_off(pm, nw, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
end

function constraint_power_balance_dc_dcne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus_arcs_dcgrid = PowerModels.ref(pm, nw, :bus_arcs_dcgrid, i)
    if haskey(PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne), i)
        bus_arcs_dcgrid_ne = PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, i)
    else
        bus_arcs_dcgrid_ne = []
    end
    bus_convs_dc = PowerModels.ref(pm, nw, :bus_convs_dc, i)
    bus_convs_dc_ne = PowerModels.ref(pm, nw, :bus_convs_dc_ne, i)
    pd = PowerModels.ref(pm, nw, :busdc, i)["Pdc"]
    constraint_power_balance_dc_dcne(pm, nw, i, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd)
end

function constraint_power_balance_dcne_dcne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    bus_i = PowerModels.ref(pm, nw, :busdc_ne, i)["busdc_i"]
    if haskey(PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne), bus_i)
        bus_arcs_dcgrid_ne = PowerModels.ref(pm, nw, :bus_arcs_dcgrid_ne, bus_i)
    else
        bus_arcs_dcgrid_ne = []
    end
    bus_ne_convs_dc_ne = PowerModels.ref(pm, nw, :bus_ne_convs_dc_ne, bus_i)
    pd_ne = PowerModels.ref(pm, nw, :busdc_ne, i)["Pdc"]
    constraint_power_balance_dcne_dcne(pm, nw, i, bus_arcs_dcgrid_ne, bus_ne_convs_dc_ne, pd_ne)
end

function constraint_ohms_dc_branch_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = PowerModels.ref(pm, nw, :branchdc_ne, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    p = PowerModels.ref(pm, nw, :dcpol)

    constraint_ohms_dc_branch_ne(pm, nw, f_bus, t_bus, f_idx, t_idx, branch["r"], p)
end

function constraint_branch_limit_on_off(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    branch = PowerModels.ref(pm, nw, :branchdc_ne, i)
    f_bus = branch["fbusdc"]
    t_bus = branch["tbusdc"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    pmax = branch["rateA"]
    pmin = -branch["rateA"]
    vpu = 0.8; #as taken in the variable creation
    imax = (branch["rateA"]/0.8)^2
    imin = 0
    constraint_branch_limit_on_off(pm, nw, i, f_idx, t_idx, pmax, pmin, imax, imin)
end

#
function constraint_converter_losses_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = PowerModels.ref(pm, nw, :convdc_ne, i)
    a = conv["LossA"]
    b = conv["LossB"]
    c = conv["LossCinv"]
    plmax = conv["LossA"] + conv["LossB"] * conv["Imax"] + conv["LossCinv"] * (conv["Imax"])^2

    constraint_converter_losses_ne(pm, nw, i, a, b, c, plmax)
end
#
 function constraint_converter_current_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
     conv = PowerModels.ref(pm, nw, :convdc_ne, i)
     Vmax = conv["Vmmax"]
     Imax = conv["Imax"]
     constraint_converter_current_ne(pm, nw, i, Vmax, Imax)
 end

function constraint_conv_reactor_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = PowerModels.ref(pm, nw, :convdc_ne, i)
    constraint_conv_reactor_ne(pm, nw, i, conv["rc"], conv["xc"], Bool(conv["reactor"]))
end

#
function constraint_conv_filter_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = PowerModels.ref(pm, nw, :convdc_ne, i)
    constraint_conv_filter_ne(pm, nw, i, conv["bf"], Bool(conv["filter"]) )
end

#
function constraint_conv_transformer_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    conv = PowerModels.ref(pm, nw, :convdc_ne, i)
    constraint_conv_transformer_ne(pm, nw, i, conv["rtf"], conv["xtf"], conv["busac_i"], conv["tm"], Bool(conv["transformer"]))
end
#
function constraint_conv_firing_angle_ne(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
     conv = PowerModels.ref(pm, n, :convdc_ne, i)
     S = conv["Pacrated"]
     P1 = cos(0) * S
     Q1 = sin(0) * S
     P2 = cos(pi) * S
     Q2 = sin(pi) * S
     constraint_conv_firing_angle_ne(pm, n, i, S, P1, Q1, P2, Q2)
end


function constraint_converter_limits(pm::_PM.AbstractIVRModel, i::Int; nw::Int=_PM.nw_id_default)
    bigM = 1.1;
    vpu = 1;
    conv = _PM.ref(pm, nw, :convdc, i)
    # pmax = conv["Pacrated"]
    # pmin = -conv["Pacrated"]
    # qmax = conv["Qacrated"]
    # qmin = -conv["Qacrated"]
    # pmaxdc = conv["Pacrated"] * bigM
    # pmindc = -conv["Pacrated"] * bigM
    imax = conv["Pacrated"]/vpu
    vmax = conv["Vmmax"]
    vmin = conv["Vmmin"]
    pdcmin = -conv["Pacrated"] * bigM # to account for losses
    pdcmax =  conv["Pacrated"] * bigM # to account for losses
    b_idx =   conv["busdc_i"]

    constraint_converter_limits(pm, nw, i, imax, vmax, vmin, b_idx, pdcmin, pdcmax)
end
