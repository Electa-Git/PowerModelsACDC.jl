#PFC variables
function variable_pfc(pm::_PM.AbstractIVRModel; kwargs...)
    variable_duty_cycle(pm; kwargs...)
    variable_c_voltage(pm; kwargs...) 
    variable_pfc_current(pm; kwargs...)
end

"variable: duty_cycle[i] for PFCs"
function variable_duty_cycle(pm::_PM.AbstractIVRModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    duty_cycle = _PM.var(pm, nw)[:duty_cycle] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :pfc)], base_name="$(nw)_duty_cycle",
        start = 0.5
    )
    if bounded
        for (i, pfc) in _PM.ref(pm, nw, :pfc)
            JuMP.set_lower_bound(duty_cycle[i], pfc["duty_cycle_min"])
            JuMP.set_upper_bound(duty_cycle[i], pfc["duty_cycle_max"])
        end
    end
    report && _PM.sol_component_value(pm, nw, :pfc, :duty_cycle, _PM.ids(pm, nw, :pfc), duty_cycle)
end


"variable: voltage[i] for PFCs"
function variable_c_voltage(pm::_PM.AbstractIVRModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    c_voltage = _PM.var(pm, nw)[:c_voltage] = JuMP.@variable(pm.model,
        [i in _PM.ids(pm, nw, :pfc)], base_name="$(nw)_c_voltage",
        start = 0
    )
    if bounded
        for (i, pfc) in _PM.ref(pm, nw, :pfc)
            JuMP.set_lower_bound(c_voltage[i], pfc["c_voltage_min"])
            JuMP.set_upper_bound(c_voltage[i], pfc["c_voltage_max"])
        end
    end
    report && _PM.sol_component_value(pm, nw, :pfc, :c_voltage, _PM.ids(pm, nw, :pfc), c_voltage)
end

"variable: pfc_current[i] for PFCs"
function variable_pfc_current(pm::_PM.AbstractIVRModel; nw::Int=_PM.nw_id_default, bounded::Bool=true, report::Bool=true)
    ipfc_dc = _PM.var(pm, nw)[:ipfc_dc] = JuMP.@variable(pm.model,
        [(l,i,j) in _PM.ref(pm, nw, :arcs_pfc)], base_name="$(nw)_ipfc_dc"
    )

    report && _PM.sol_component_value_edge(pm, nw, :pfc, :pfc_current_12_fr, :pfc_current_12_to, _PM.ref(pm, nw, :arcs_from_12_pfc), _PM.ref(pm, nw, :arcs_to_12_pfc), ipfc_dc)
    report && _PM.sol_component_value_edge(pm, nw, :pfc, :pfc_current_13_fr, :pfc_current_13_to, _PM.ref(pm, nw, :arcs_from_13_pfc), _PM.ref(pm, nw, :arcs_to_13_pfc), ipfc_dc)
end

"Constraint template for PFCs"
function constraint_duty_cycle_pfc(pm::_PM.AbstractIVRModel, i::Int; nw::Int=_PM.nw_id_default)
    pfc = _PM.ref(pm, nw, :pfc, i)
    arcs_pfc = _PM.ref(pm, nw, :arcs_pfc)
    pfc_terminal_1 = pfc["terminal1_bus"]
    pfc_terminal_2 = pfc["terminal2_bus"]
    pfc_terminal_3 = pfc["terminal3_bus"]

    constraint_duty_cycle_pfc(pm, nw, i, arcs_pfc, pfc_terminal_1, pfc_terminal_2, pfc_terminal_3)    
end

function constraint_voltage_terminal_2_pfc(pm::_PM.AbstractIVRModel, i::Int; nw::Int=_PM.nw_id_default)
    pfc = _PM.ref(pm, nw, :pfc, i) 
    arcs_pfc = _PM.ref(pm, nw, :arcs_pfc)

    pfc_terminal_1 = pfc["terminal1_bus"]
    pfc_terminal_2 = pfc["terminal2_bus"]
    pfc_terminal_3 = pfc["terminal3_bus"]
    idx_terminal_1 = (i,pfc_terminal_1)
    idx_terminal_2 = (i,pfc_terminal_2)
    idx_terminal_3 = (i,pfc_terminal_3)

    constraint_voltage_terminal_2_pfc(pm, nw, i, pfc_terminal_1, pfc_terminal_2, pfc_terminal_3, arcs_pfc)
end

function constraint_voltage_terminal_3_pfc(pm::_PM.AbstractIVRModel, i::Int; nw::Int=_PM.nw_id_default)
    pfc = _PM.ref(pm, nw, :pfc, i) 
    arcs_pfc = _PM.ref(pm, nw, :arcs_pfc)

    pfc_terminal_1 = pfc["terminal1_bus"]
    pfc_terminal_2 = pfc["terminal2_bus"]
    pfc_terminal_3 = pfc["terminal3_bus"]
    idx_terminal_1 = (i,pfc_terminal_1)
    idx_terminal_3 = (i,pfc_terminal_3)

    constraint_voltage_terminal_3_pfc(pm, nw, i, pfc_terminal_1, pfc_terminal_2, pfc_terminal_3, arcs_pfc)
end

function constraint_pfc_current_balance(pm::_PM.AbstractIVRModel, i::Int; nw::Int=_PM.nw_id_default)
    pfc = _PM.ref(pm, nw, :pfc, i) 
    arcs_pfc = _PM.ref(pm, nw, :arcs_pfc)
    pfc_terminal_1 = pfc["terminal1_bus"]
    pfc_terminal_2 = pfc["terminal2_bus"]
    pfc_terminal_3 = pfc["terminal3_bus"]

    constraint_pfc_current_balance(pm, nw, i, arcs_pfc, pfc_terminal_1, pfc_terminal_2, pfc_terminal_3)
end

# Associated constraints
function constraint_duty_cycle_pfc(pm, nw, i, arcs_pfc, pfc_terminal_1, pfc_terminal_2, pfc_terminal_3)
    duty_cycle = _PM.var(pm, nw, :duty_cycle, i)
    c_voltage = _PM.var(pm, nw, :c_voltage, i)
    ipfc_dc = _PM.var(pm, nw, :ipfc_dc, arcs_pfc)
    I2 = _PM.var(pm, nw, :ipfc_dc, (i,pfc_terminal_2,pfc_terminal_1))
    I3 = _PM.var(pm, nw, :ipfc_dc, (i,pfc_terminal_3,pfc_terminal_1))
     
    JuMP.@constraint(pm.model, c_voltage*((1-duty_cycle)*I3 - duty_cycle*I2) == 0)
end

function constraint_voltage_terminal_2_pfc(pm, nw, i, pfc_terminal_1, pfc_terminal_2, pfc_terminal_3, arcs_pfc)
    duty_cycle = _PM.var(pm, nw, :duty_cycle, i)
    ipfc_dc = _PM.var(pm, nw, :ipfc_dc, arcs_pfc)
    c_voltage = _PM.var(pm, nw, :c_voltage, i)
    busdc_terminal_1 = _PM.var(pm, nw, :vdcm, pfc_terminal_1)
    busdc_terminal_2 = _PM.var(pm, nw, :vdcm, pfc_terminal_2)

    JuMP.@constraint(pm.model, busdc_terminal_1 - busdc_terminal_2 - duty_cycle*c_voltage == 0)
end

function constraint_voltage_terminal_3_pfc(pm, nw, i, pfc_terminal_1, pfc_terminal_2, pfc_terminal_3, arcs_pfc)
    duty_cycle = _PM.var(pm, nw, :duty_cycle, i)
    ipfc_dc = _PM.var(pm, nw, :ipfc_dc, arcs_pfc)
    c_voltage = _PM.var(pm, nw, :c_voltage, i)
    busdc_terminal_1 = _PM.var(pm, nw, :vdcm, pfc_terminal_1)
    busdc_terminal_3 = _PM.var(pm, nw, :vdcm, pfc_terminal_3)

    JuMP.@constraint(pm.model, busdc_terminal_1 - busdc_terminal_3 + (1 - duty_cycle)*c_voltage == 0)
end

function constraint_pfc_current_balance(pm, nw, i, arcs_pfc, pfc_terminal_1, pfc_terminal_2, pfc_terminal_3)
    ipfc_dc = _PM.var(pm, nw, :ipfc_dc, arcs_pfc)
    I12 = _PM.var(pm, nw, :ipfc_dc, (i,pfc_terminal_1,pfc_terminal_2))
    I13 = _PM.var(pm, nw, :ipfc_dc, (i,pfc_terminal_1,pfc_terminal_3))
    I21 = _PM.var(pm, nw, :ipfc_dc, (i,pfc_terminal_2,pfc_terminal_1))
    I31 = _PM.var(pm, nw, :ipfc_dc, (i,pfc_terminal_3,pfc_terminal_1))

    JuMP.@constraint(pm.model, I12 + I21 == 0)
    JuMP.@constraint(pm.model, I13 + I31 == 0)
end