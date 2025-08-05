#### VARIABLES
"DC generator power"

function variable_dcgenerator_power(pm::_PM.AbstractPowerModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    pgdc = _PM.var(pm, nw)[:pgdc] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :gendc)], base_name="$(nw)_pgdc",
        start = 0;
    )
    if bounded
        for (g, gen) in _PM.ref(pm, nw, :gendc)
            JuMP.set_lower_bound(pgdc[g],  gen["pmin"])
            JuMP.set_upper_bound(pgdc[g],  gen["pmax"])
        end
    end
    report && _PM.sol_component_value(pm, nw, :gendc, :pgdc, _PM.ids(pm, nw, :gendc), pgdc)
end

#### CONSTRAINT TEMPLATES AND CONSTRAINTS

function contstraint_dcgenerator_volteage_and_power(pm::_PM.AbstractPowerModel, i::Int; nw::Int = _PM.nw_id_default)
    
    gen =_PM.ref(pm, nw, :gendc, i)

    gen_bus = gen["gen_bus"]
    k_droop = gen["droop_const"]
    control_type = gen["control_type"]
    v_set = gen["vgdc"]
    p_set = gen["pgdcset"]

    return contstraint_dcgenerator_volteage_and_power(pm, nw, i, gen_bus, k_droop, control_type, v_set, p_set)
end


function contstraint_dcgenerator_volteage_and_power(pm::_PM.AbstractPowerModel, nw::Int, i::Int, gen_bus::Int, k_droop, control_type::Int, v_set, p_set)
    pgdc = _PM.var(pm, nw)[:pgdc][i]
    vdcg = _PM.var(pm, nw)[:vdcm][gen_bus]

    if control_type == 1 # constant power
        JuMP.@constraint(pm.model, pgdc == p_set)
    elseif control_type == 2 # constant voltage
        JuMP.@constraint(pm.model, vdcg == v_set)
    elseif control_type == 3 # droop control
        JuMP.@constraint(pm.model, pgdc == 1/k_droop * (vdcg - v_set))
    else
        error("Unknown control type for DC generator: $control_type")
    end
end