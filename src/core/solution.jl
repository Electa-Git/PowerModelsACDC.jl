function get_solution_acdc(pm::GenericPowerModel, sol::Dict{String,Any})
    PowerModels.add_bus_voltage_setpoint(sol, pm)
    PowerModels.add_generator_power_setpoint(sol, pm)
    PowerModels.add_branch_flow_setpoint(sol, pm)
    PowerModels.add_dcline_flow_setpoint(sol, pm)
    add_dc_bus_voltage_setpoint(sol, pm)
    add_dcconverter_setpoint(sol, pm)
    add_dcgrid_flow_setpoint(sol,pm)
    add_dcbranch_losses(sol, pm)
    add_dcconv_losses(sol, pm)
    return sol
end


function add_dcconverter_setpoint(sol, pm::GenericPowerModel)
    mva_base = pm.data["baseMVA"]
    PowerModels.add_setpoint(sol, pm, "convdc", "pgrid", :pconv_tf_fr)
    PowerModels.add_setpoint(sol, pm, "convdc", "qgrid", :qconv_tf_fr)
    PowerModels.add_setpoint(sol, pm, "convdc", "pconv", :pconv_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "qconv", :qconv_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "pdc", :pconv_dc)
    PowerModels.add_setpoint(sol, pm, "convdc", "iconv", :iconv_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "ptf_fr", :pconv_tf_fr)
    PowerModels.add_setpoint(sol, pm, "convdc", "ptf_to", :pconv_tf_to)
    add_converter_voltage_setpoint(sol, pm)
end

function add_dcgrid_flow_setpoint(sol, pm::GenericPowerModel)
    # check the branch flows were requested
    PowerModels.add_setpoint(sol, pm, "branchdc", "pf", :p_dcgrid; extract_var = (var,idx,item) -> var[(idx, item["fbusdc"], item["tbusdc"])])
    PowerModels.add_setpoint(sol, pm, "branchdc", "pt", :p_dcgrid; extract_var = (var,idx,item) -> var[(idx, item["tbusdc"], item["fbusdc"])])
end

function add_dcbranch_losses(sol, pm::GenericPowerModel)
    for (i, branchdc) in sol["branchdc"]
        pf = branchdc["pf"]
        pt = branchdc["pt"]
        sol["branchdc"]["$i"]["ploss"] = pf + pt
    end
end

function add_dcconv_losses(sol, pm::GenericPowerModel)
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


function add_dc_bus_voltage_setpoint(sol, pm::GenericPowerModel)
    PowerModels.add_setpoint(sol, pm, "busdc", "vm", :vdcm)
end

function add_converter_voltage_setpoint(sol, pm::GenericPowerModel)
    PowerModels.add_setpoint(sol, pm, "convdc", "vmconv", :vmc)
    PowerModels.add_setpoint(sol, pm, "convdc", "vaconv", :vac)
    PowerModels.add_setpoint(sol, pm, "convdc", "vmfilt", :vmf)
    PowerModels.add_setpoint(sol, pm, "convdc", "vafilt", :vaf)
end
