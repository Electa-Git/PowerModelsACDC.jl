# Constraint template to fix interconnector flows to keep net position of a zone.
function constraint_fixed_xb_flows(pm::_PM.AbstractPowerModel, i::Int; nw::Int=_PM.nw_id_default)
    xb_line_dict = _PM.ref(pm, nw, :borders, i, "xb_lines")
    xb_conv_dict = _PM.ref(pm, nw, :borders, i, "xb_convs")
    slack = _PM.ref(pm, nw, :borders, i, "slack")
    arcs_xb_lines = []
    xb_convs = []
    for (k, line) in xb_line_dict
        if haskey(line, "br_status") && line["br_status"] == 1
            if line["direction"] == "from"
                push!(arcs_xb_lines, (line["index"],  line["f_bus"], line["t_bus"] ))
            else
                push!(arcs_xb_lines, (line["index"],  line["t_bus"], line["f_bus"] ))
            end
        end
    end

    for (c, conv) in xb_conv_dict
        if haskey(conv, "index") && conv["status"] == 1
            push!(xb_convs, conv["index"])
        end
    end
    
    flow = _PM.ref(pm, nw, :borders, i, "flow")

    constraint_fixed_xb_flows(pm, nw, arcs_xb_lines, xb_convs, flow, slack)
end


#### DCP Formulation #####
function constraint_fixed_xb_flows(pm::_PM.AbstractDCPModel, n::Int, xb_lines, xb_convs, flow, slack)
    p    = _PM.var(pm, n, :p)
    pconv = _PM.var(pm, n,  :pconv_tf_fr)

    # converter behaves like a load: 
    # pconv > 0 is an export
    # pconv < 0 is an import

    # flow > 0 means export
    # flow < 0 means import
    
    if flow > 0  # in case of import
        JuMP.@constraint(pm.model, sum(p[a] for a in xb_lines) - sum(pconv[c] for c in xb_convs) <= (1 + slack) * flow)
        JuMP.@constraint(pm.model,  (1 - slack) * flow <= sum(p[a] for a in xb_lines) - sum(pconv[c] for c in xb_convs))
    else
        JuMP.@constraint(pm.model, sum(p[a] for a in xb_lines) - sum(pconv[c] for c in xb_convs) >= (1 + slack) * flow)
        JuMP.@constraint(pm.model,  (1 - slack) * flow >= sum(p[a] for a in xb_lines) - sum(pconv[c] for c in xb_convs))
    end
end