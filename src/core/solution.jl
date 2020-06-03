# Not used from v0.3.0 on (PowerModels v0.15.3) - Kept for sentimental reasons
function get_solution_acdc(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})
    _PM.add_setpoint_bus_voltage!(sol, pm)
    _PM.add_setpoint_generator_power!(sol, pm)
    _PM.add_setpoint_branch_flow!(sol, pm)
    _PM.add_setpoint_dcline_flow!(sol, pm)
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


function add_dcconverter_setpoint(sol, pm::_PM.AbstractPowerModel)
    _PM.add_setpoint!(sol, pm, "convdc", "pgrid", :pconv_tf_fr)
    _PM.add_setpoint!(sol, pm, "convdc", "qgrid", :qconv_tf_fr)
    _PM.add_setpoint!(sol, pm, "convdc", "pconv", :pconv_ac)
    _PM.add_setpoint!(sol, pm, "convdc", "qconv", :qconv_ac)
    _PM.add_setpoint!(sol, pm, "convdc", "pdc", :pconv_dc)
    _PM.add_setpoint!(sol, pm, "convdc", "iconv", :iconv_ac)
    _PM.add_setpoint!(sol, pm, "convdc", "ptf_fr", :pconv_tf_fr)
    _PM.add_setpoint!(sol, pm, "convdc", "ptf_to", :pconv_tf_to)
    add_dcconverter_voltage_setpoint(sol, pm)
end

function add_dcgrid_flow_setpoint(sol, pm::_PM.AbstractPowerModel)
    # check the branch flows were requested
    _PM.add_setpoint!(sol, pm, "branchdc", "pf", :p_dcgrid,  status_name="status",  var_key = (idx,item) -> (idx, item["fbusdc"], item["tbusdc"]))
    _PM.add_setpoint!(sol, pm, "branchdc", "pt", :p_dcgrid;  status_name="status",  var_key = (idx,item) -> (idx, item["tbusdc"], item["fbusdc"]))
end

function add_dcbranch_losses(sol, pm::_PM.AbstractPowerModel)
    for (i, branchdc) in sol["branchdc"]
        pf = branchdc["pf"]
        pt = branchdc["pt"]
        sol["branchdc"]["$i"]["ploss"] = pf + pt
    end
end

function add_dcconverter_losses(sol, pm::_PM.AbstractPowerModel)
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


function add_dc_bus_voltage_setpoint(sol, pm::_PM.AbstractPowerModel)
    _PM.add_setpoint!(sol, pm, "busdc", "vm", :vdcm, status_name="Vdc", inactive_status_value = 4)
end

function add_dcconverter_voltage_setpoint(sol, pm::_PM.AbstractPowerModel)
    _PM.add_setpoint!(sol, pm, "convdc", "vmconv", :vmc, status_name="islcc", inactive_status_value = 0)
    _PM.add_setpoint!(sol, pm, "convdc", "vaconv", :vac, status_name="islcc", inactive_status_value = 0)
    _PM.add_setpoint!(sol, pm, "convdc", "vmfilt", :vmf, status_name="islcc", inactive_status_value = 0)
    _PM.add_setpoint!(sol, pm, "convdc", "vafilt", :vaf, status_name="islcc", inactive_status_value = 0)
end

function add_dcconverter_firing_angle(sol, pm::_PM.AbstractPowerModel)
    _PM.add_setpoint!(sol, pm, "convdc", "phi", :phiconv, status_name="islcc", inactive_status_value = 0)
end


function get_solution_acdc_ne(pm::_PM.AbstractPowerModel, sol::Dict{String,Any})
    _PM.add_setpoint_bus_voltage!(sol, pm)
    _PM.add_setpoint_generator_power!(sol, pm)
    _PM.add_setpoint_branch_flow!(sol, pm)
    _PM.add_setpoint_dcline_flow!(sol, pm)
    if haskey(pm.data, "convdc")
        PowerModelsACDC.add_dc_bus_voltage_setpoint(sol, pm)
        PowerModelsACDC.add_dcconverter_setpoint(sol, pm)
        PowerModelsACDC.add_dcgrid_flow_setpoint(sol,pm)
        PowerModelsACDC.add_dcbranch_losses(sol, pm)
        PowerModelsACDC.add_dcconverter_losses(sol, pm)
        PowerModelsACDC.add_dcconverter_voltage_setpoint(sol, pm)
        PowerModelsACDC.add_dcconverter_firing_angle(sol, pm)
    elseif haskey(pm.data, "nw")
        if haskey(pm.data["nw"]["1"], "convdc")
            PowerModelsACDC.add_dc_bus_voltage_setpoint(sol, pm)
            PowerModelsACDC.add_dcconverter_setpoint(sol, pm)
            PowerModelsACDC.add_dcgrid_flow_setpoint(sol,pm)
            PowerModelsACDC.add_dcbranch_losses(sol, pm)
            PowerModelsACDC.add_dcconverter_losses(sol, pm)
            PowerModelsACDC.add_dcconverter_voltage_setpoint(sol, pm)
            PowerModelsACDC.add_dcconverter_firing_angle(sol, pm)
        end
    end
    if haskey(pm.data, "convdc_ne")
        add_dc_bus_voltage_setpoint_ne(sol, pm)
        add_dcconverter_setpoint_ne(sol, pm)
        add_dcgrid_flow_setpoint_ne(sol,pm)
        add_dcbranch_losses_ne(sol, pm)
        add_dcconverter_losses_ne(sol, pm)
    elseif haskey(pm.data, "nw")
        if haskey(pm.data["nw"]["1"], "convdc_ne")
            add_dc_bus_voltage_setpoint_ne(sol, pm)
            add_dcconverter_setpoint_ne(sol, pm)
            add_dcgrid_flow_setpoint_ne(sol,pm)
            add_dcbranch_losses_ne(sol, pm)
            add_dcconverter_losses_ne(sol, pm)
        end
    end
    return sol
end

function add_dc_bus_voltage_setpoint_ne(sol, pm::_PM.AbstractPowerModel)
    _PM.add_setpoint!(sol, pm, "busdc_ne", "vm", :vdcm_ne; status_name = "Cdc", inactive_status_value = 5)
end

function add_dcconverter_setpoint_ne(sol, pm::_PM.AbstractPowerModel)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "pgrid", :pconv_tf_fr_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "qgrid", :qconv_tf_fr_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "pconv", :pconv_ac_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "qconv", :qconv_ac_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "pdc", :pconv_dc_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "iconv", :iconv_ac_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "ireactor", :irc_sq_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "iconv_sq", :iconv_ac_sq_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "ppr_fr", :pconv_pr_fr_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "ptf_to", :pconv_tf_to_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "isbuilt", :conv_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "itr", :itf_sq_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "ipr", :irc_sq_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "pfilt_to", :pconv_tf_to_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "pfilt_fr", :pconv_pr_fr_ne)

    add_dcconverter_voltage_setpoint_ne(sol, pm)
    add_dcconverter_firing_angle_ne(sol, pm)
end

function add_dcconverter_voltage_setpoint_ne(sol, pm::_PM.AbstractPowerModel)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "vmconv", :vmc_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "vaconv", :vac_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "vmfilt", :vmf_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "vafilt", :vaf_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "wf", :wf_ac_ne)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "w_du", :w_du)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "wc", :wc_ac_ne)
end

function add_dcgrid_flow_setpoint_ne(sol, pm::_PM.AbstractPowerModel)
    # check the branch flows were requested
    _PM.add_setpoint!(sol, pm, "branchdc_ne", "pf", :p_dcgrid_ne; status_name="status",  var_key = (idx,item) -> (idx, item["fbusdc"], item["tbusdc"]))
    _PM.add_setpoint!(sol, pm, "branchdc_ne", "pt", :p_dcgrid_ne; status_name="status",  var_key = (idx,item) -> (idx, item["tbusdc"], item["fbusdc"]))
    _PM.add_setpoint!(sol, pm, "branchdc_ne", "isbuilt", :branch_ne)
    _PM.add_setpoint!(sol, pm, "branchdc_ne", "wdc_to", :wdc_du_to; status_name="status")
end

function add_dcbranch_losses_ne(sol, pm::_PM.AbstractPowerModel)
    for (i, branchdc) in sol["branchdc_ne"]
        pf = branchdc["pf"]
        pt = branchdc["pt"]
        sol["branchdc_ne"]["$i"]["ploss"] = pf + pt
    end
end

function add_dcconverter_losses_ne(sol, pm::_PM.AbstractPowerModel)
    for (i, convdc) in sol["convdc_ne"]
        pdc = convdc["pdc"]
        pgrid = convdc["pgrid"]
        ptf_to = convdc["ptf_to"]
        pconv = convdc["pconv"]
        sol["convdc_ne"]["$i"]["ploss_tot"] = pdc - pgrid
        sol["convdc_ne"]["$i"]["ploss_tf"] = pgrid + ptf_to
        sol["convdc_ne"]["$i"]["ploss_re"] = - ptf_to + pconv # ptf_to + ppr_fr = 0
        sol["convdc_ne"]["$i"]["ploss_conv"] =  pconv + pdc
    end
end

function add_dcconverter_firing_angle_ne(sol, pm::_PM.AbstractPowerModel)
    _PM.add_setpoint!(sol, pm, "convdc_ne", "phi", :phiconv_ne)
end
