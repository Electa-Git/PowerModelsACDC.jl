function get_solution_acdc(pm::GenericPowerModel, sol::Dict{String,Any})
    PowerModels.add_bus_voltage_setpoint(sol, pm)
    PowerModels.add_generator_power_setpoint(sol, pm)
    PowerModels.add_branch_flow_setpoint(sol, pm)
    PowerModels.add_dcline_flow_setpoint(sol, pm)
    add_dc_bus_voltage_setpoint(sol, pm)
    add_dcconverter_setpoint(sol, pm)
    add_dcgrid_flow_setpoint(sol,pm)
    return sol
end


function add_dcconverter_setpoint(sol, pm::GenericPowerModel)
    mva_base = pm.data["baseMVA"]
    PowerModels.add_setpoint(sol, pm, "convdc", "pgrid", :pconv_grid_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "qgrid", :qconv_grid_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "pconv", :pconv_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "qconv", :qconv_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "pdc", :pconv_dc)
    PowerModels.add_setpoint(sol, pm, "convdc", "iconv", :iconv_ac)
    add_converter_voltage_setpoint(sol, pm)
end

function add_dcgrid_flow_setpoint(sol, pm::GenericPowerModel)
    # check the branch flows were requested
    PowerModels.add_setpoint(sol, pm, "branchdc", "pf", :p_dcgrid; extract_var = (var,idx,item) -> var[(idx, item["fbusdc"], item["tbusdc"])])
    PowerModels.add_setpoint(sol, pm, "branchdc", "pt", :p_dcgrid; extract_var = (var,idx,item) -> var[(idx, item["tbusdc"], item["fbusdc"])])
end

function add_dc_bus_voltage_setpoint(sol, pm::GenericPowerModel)
    PowerModels.add_setpoint(sol, pm, "busdc", "vm", :vdcm)
end

function add_converter_voltage_setpoint(sol, pm::GenericPowerModel)
    PowerModels.add_setpoint(sol, pm, "convdc", "vmconv", :vmc_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "vaconv", :vac_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "vmfilt", :vmf_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "vafilt", :vaf_ac)
end
