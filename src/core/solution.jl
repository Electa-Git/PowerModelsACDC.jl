function get_solution_acdc(pm::AbstractPowerModel, sol::Dict{String,Any})
    PowerModels.add_setpoint_bus_voltage!(sol, pm)
    PowerModels.add_setpoint_generator_power!(sol, pm)
    PowerModels.add_setpoint_branch_flow!(sol, pm)
    PowerModels.add_setpoint_dcline_flow!(sol, pm)
    if haskey(pm.data, "convdc")
        add_dc_bus_voltage_setpoint(sol, pm)
        add_dcconverter_setpoint(sol, pm)
        add_dcgrid_flow_setpoint(sol,pm)
        add_dcbranch_losses(sol, pm)
        add_dcconverter_losses(sol, pm)
        add_dcconverter_voltage_setpoint(sol, pm)
        add_dcconverter_firing_angle(sol, pm)
    end
    return sol
end


function add_dcconverter_setpoint(sol, pm::AbstractPowerModel)
    PowerModels.add_setpoint!(sol, pm, "convdc", "pgrid", :pconv_tf_fr)
    PowerModels.add_setpoint!(sol, pm, "convdc", "qgrid", :qconv_tf_fr)
    PowerModels.add_setpoint!(sol, pm, "convdc", "pconv", :pconv_ac)
    PowerModels.add_setpoint!(sol, pm, "convdc", "qconv", :qconv_ac)
    PowerModels.add_setpoint!(sol, pm, "convdc", "pdc", :pconv_dc)
    PowerModels.add_setpoint!(sol, pm, "convdc", "iconv", :iconv_ac)
    PowerModels.add_setpoint!(sol, pm, "convdc", "ptf_fr", :pconv_tf_fr)
    PowerModels.add_setpoint!(sol, pm, "convdc", "ptf_to", :pconv_tf_to)
    add_dcconverter_voltage_setpoint(sol, pm)
end

function add_dcgrid_flow_setpoint(sol, pm::AbstractPowerModel)
    # check the branch flows were requested
    PowerModels.add_setpoint!(sol, pm, "branchdc", "pf", :p_dcgrid,  status_name="status",  var_key = (idx,item) -> (idx, item["fbusdc"], item["tbusdc"]))
    PowerModels.add_setpoint!(sol, pm, "branchdc", "pt", :p_dcgrid;  status_name="status",  var_key = (idx,item) -> (idx, item["tbusdc"], item["fbusdc"]))
end

function add_dcbranch_losses(sol, pm::AbstractPowerModel)
    for (i, branchdc) in sol["branchdc"]
        pf = branchdc["pf"]
        pt = branchdc["pt"]
        sol["branchdc"]["$i"]["ploss"] = pf + pt
    end
end

function add_dcconverter_losses(sol, pm::AbstractPowerModel)
    for (i, convdc) in sol["convdc"]
        pf = convdc["pdc"]
        pt = convdc["pgrid"]
        ptf_fr = convdc["ptf_fr"]
        ptf_to = convdc["ptf_to"]
        sol["convdc"]["$i"]["ploss_tot"] = pf + pt
        sol["convdc"]["$i"]["ploss_tf"] = ptf_fr + ptf_to
        sol["convdc"]["$i"]["ploss_conv"] = sol["convdc"]["$i"]["ploss_tot"] - sol["convdc"]["$i"]["ploss_tf"] # TODO update later with filter etc..
    end
end


function add_dc_bus_voltage_setpoint(sol, pm::AbstractPowerModel)
    PowerModels.add_setpoint!(sol, pm, "busdc", "vm", :vdcm, status_name="Vdc", inactive_status_value = 4)
end

function add_dcconverter_voltage_setpoint(sol, pm::AbstractPowerModel)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vmconv", :vmc, status_name="islcc", inactive_status_value = 0)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vaconv", :vac, status_name="islcc", inactive_status_value = 0)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vmfilt", :vmf, status_name="islcc", inactive_status_value = 0)
    PowerModels.add_setpoint!(sol, pm, "convdc", "vafilt", :vaf, status_name="islcc", inactive_status_value = 0)
end

function add_dcconverter_firing_angle(sol, pm::AbstractPowerModel)
    PowerModels.add_setpoint!(sol, pm, "convdc", "phi", :phiconv, status_name="islcc", inactive_status_value = 0)
end
