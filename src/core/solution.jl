function get_solution_acdc(pm::GenericPowerModel, sol::Dict{String,Any})
    PowerModels.add_bus_voltage_setpoint(sol, pm)
    PowerModels.add_generator_power_setpoint(sol, pm)
    PowerModels.add_branch_flow_setpoint(sol, pm)
    PowerModels.add_dcline_flow_setpoint(sol, pm)
    add_dcconverter_setpoint(sol, pm)
    return sol
end


function add_dcconverter_setpoint(sol, pm::GenericPowerModel)
    mva_base = pm.data["baseMVA"]
    PowerModels.add_setpoint(sol, pm, "convdc", "pac", :pconv_ac)
    PowerModels.add_setpoint(sol, pm, "convdc", "qac", :qconv_ac)
end
