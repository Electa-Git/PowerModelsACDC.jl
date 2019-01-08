var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#PowerModelACDC.jl-Documentation-1",
    "page": "Home",
    "title": "PowerModelACDC.jl Documentation",
    "category": "section",
    "text": "CurrentModule = PowerModelsACDC"
},

{
    "location": "index.html#Overview-1",
    "page": "Home",
    "title": "Overview",
    "category": "section",
    "text": "PowerModelsACDC.jl is a Julia/JuMP package extending PowerModels.jl, which focuses on Steady-State Power Network Optimization. PowerModels.jl provides utilities for parsing and modifying network data and is designed to enable computational evaluation of emerging power network formulations and algorithms in a common platform.PowerModelsACDC.jl adds new problem types:Power flow with both ac and dc lines, from point-to-point connections to meshed grids, with converters connecting ac and dc grid lines\nThe equivalent optimal power flow problem typePowerModelsACDC.jl extends the formulation hierarchy developed for AC grids, with equivalent DC grid and converter station formulations:ACPPowerModel\nDCPPowerModel\nSOCWRPowerModel\nSDPWRMPowerModel\nQCWRPowerModel\nQCWRTriPowerModelDeveloped by:Hakan Ergun, Jay Dave KU Leuven / EnergyVille\nFrederik Geth, CSIRO"
},

{
    "location": "index.html#Installation-of-PowerModelACDC-1",
    "page": "Home",
    "title": "Installation of PowerModelACDC",
    "category": "section",
    "text": "The latest stable release of PowerModelACDC can be installed using the Julia package manager withPkg.clone(\"https://github.com/hakanergun/PowerModelsACDC.jl.git\")The package is compatible with PowerModels v0.9.2, InfrastrucureModels v0.0.13 and julia v0.7.note: Note\nThis is a research-grade optimization package. Eventually, we hope to make this a stable julia package."
},

{
    "location": "index.html#Special-Thanks-To-1",
    "page": "Home",
    "title": "Special Thanks To",
    "category": "section",
    "text": "Jef Beerten (KU Leuven/EnergyVille) for his insights in AC/DC power flow modelling. Carleton Coffrin (Los Alamos National Laboratory) for his countless design tips.  "
},

{
    "location": "quickguide.html#",
    "page": "Getting Started",
    "title": "Getting Started",
    "category": "page",
    "text": ""
},

{
    "location": "quickguide.html#Quick-Start-Guide-1",
    "page": "Getting Started",
    "title": "Quick Start Guide",
    "category": "section",
    "text": "Once PowerModelsACDC is installed, Ipopt is installed, and an ACDC network data file (e.g. \"case5_acdc.m\" in the folder \"./test/data\") has been acquired, an ACDC Optimal Power Flow can be executed with:using PowerModelsACDC\nusing Ipopt\n\nresult = run_acdcopf(\"case5_acdc.m\", ACPPowerModel, IpoptSolver())\nresult[\"solution\"][\"busdc\"][\"1\"]\nresult[\"solution\"][\"convdc\"][\"1\"]You can also find a test script in the folder \"./test/scripts\"."
},

{
    "location": "quickguide.html#Modifying-settings-1",
    "page": "Getting Started",
    "title": "Modifying settings",
    "category": "section",
    "text": "The flow AC and DC branch results are not written to the result by default. To inspect the flow results, pass a settings Dictresult = run_acdcopf(\"case5_acdc.m\", ACPPowerModel, IpoptSolver(), setting = Dict(\"output\" => Dict(\"branch_flows\" => true)))\nresult[\"solution\"][\"branchdc\"][\"1\"]\nresult[\"solution\"][\"branch\"][\"2\"]"
},

{
    "location": "quickguide.html#Remark-1",
    "page": "Getting Started",
    "title": "Remark",
    "category": "section",
    "text": "Note that run_ac_opf still works and runs a classic AC OPF on only the AC part of the described grid.result = run_ac_opf(\"case5_acdc.m\", IpoptSolver())"
},

{
    "location": "result-data.html#",
    "page": "Results",
    "title": "Results",
    "category": "page",
    "text": ""
},

{
    "location": "result-data.html#PowerModels-Result-Data-Format-1",
    "page": "Results",
    "title": "PowerModels Result Data Format",
    "category": "section",
    "text": ""
},

{
    "location": "result-data.html#The-Result-Data-Dictionary-1",
    "page": "Results",
    "title": "The Result Data Dictionary",
    "category": "section",
    "text": "PowerModels utilizes a dictionary to organize the results of a run command. The dictionary uses strings as key values so it can be serialized to JSON for algorithmic data exchange. The data dictionary organization is  consistent with  PowerModels."
},

{
    "location": "formulations.html#",
    "page": "Network Formulations",
    "title": "Network Formulations",
    "category": "page",
    "text": ""
},

{
    "location": "formulations.html#Type-Hierarchy-1",
    "page": "Network Formulations",
    "title": "Type Hierarchy",
    "category": "section",
    "text": "The original type hierarchy of PowerModels is used.For details on GenericPowerModel, see PowerModels.jl documentation."
},

{
    "location": "formulations.html#Formulations-overview-1",
    "page": "Network Formulations",
    "title": "Formulations overview",
    "category": "section",
    "text": "Extending PowerModels,  formulations for balanced  OPF in DC grids have been implemented and mapped to the following AC grid formulations:ACPPowerModel\nDCPPowerModel\nSOCWRPowerModel\nSDPWRMPowerModel\nQCWRPowerModel\nQCWRTriPowerModelNote that from the perspective of OPF convex relaxation for DC grids, applying the same assumptions as the AC equivalent, the same formulation (and variable space) is obtained for - SOCWRPowerModel,  SDPWRMPowerModel,  QCWRPowerModel and  QCWRTriPowerModel. These are referred to as formulations in the AC WR(M) variable space."
},

{
    "location": "formulations.html#Formulation-details-1",
    "page": "Network Formulations",
    "title": "Formulation details",
    "category": "section",
    "text": "The formulations are categorized as Bus Injection Model (BIM) or Branch Flow Model (BFM).Applied to DC grids, the BIM uses series conductance notation, and adds separate equations for the to and from line flow.\nConversely, BFM uses series resistance parameters, and adds only a single equation per line, representing P_lij + P_lji = P_l^loss.Note that in a DC grid, under the static power flow assumption, power is purely active, impedance reduces to resistance, and voltages and currents are defined by magnitude and direction.Parameters used:g^series=frac1r^series\n, dc line series impedance\np in 12\nfor single (1) or bipole (2) DC lines\nU_i^max\nmaximum AC node voltage\na\nconstant power converter loss\nb\nconverter loss proportional to current magnitude\nc\nconverter loss proportional to square of current magnitudeNote that generally, a geq 0 b geq 0 c geq 0 as physical losses are positive."
},

{
    "location": "formulations.html#ACPPowerModel-(BIM)-1",
    "page": "Network Formulations",
    "title": "ACPPowerModel (BIM)",
    "category": "section",
    "text": ""
},

{
    "location": "formulations.html#DC-lines-1",
    "page": "Network Formulations",
    "title": "DC lines",
    "category": "section",
    "text": "Active power flow from side: P^dc_ij = p cdot g^series_ij cdot U^dc_i cdot (U^dc_i - U^dc_j).\nActive power flow to side: P^dc_ji = p cdot g^series_ij cdot U^dc_j cdot (U^dc_j - U^dc_i)."
},

{
    "location": "formulations.html#ACDC-converters-1",
    "page": "Network Formulations",
    "title": "ACDC converters",
    "category": "section",
    "text": "Power balance: P^conv ac_ij + P^conv dc_ji = a + b cdot I^conv ac + c cdot (I^conv ac)^2.\nCurrent variable model: (P^convac_ij)^2 + (Q^convac_ij)^2 = U_i^2 cdot  (I^conv ac)^2.\nLCC converters, active /reactive power:P^conv ac = cosvarphi_c cdot S^convacratedQ^conv ac = sinvarphi_c cdot S^convacrated"
},

{
    "location": "formulations.html#DCPPowerModel-(NF)-1",
    "page": "Network Formulations",
    "title": "DCPPowerModel (NF)",
    "category": "section",
    "text": "Due to the absence of voltage angles in DC grids, the DC power flow model reduces to network flow (NF) under the \'DC\' assumptions"
},

{
    "location": "formulations.html#DC-lines-2",
    "page": "Network Formulations",
    "title": "DC lines",
    "category": "section",
    "text": "Network flow model: P^dc_ij + P^dc_ji = 0"
},

{
    "location": "formulations.html#ACDC-converters-2",
    "page": "Network Formulations",
    "title": "ACDC converters",
    "category": "section",
    "text": "Under the same assumptions as MATPOWER (U_i approx 1), P^conv ac_ij approx I^conv ac allowing the converter model to be formulated as:Network flow model: P^conv ac_ij + P^conv dc_ji = a + b P^conv ac_ij\nLCC converters, n.a."
},

{
    "location": "formulations.html#AC-WR(M)-variable-space.-(BFM)-1",
    "page": "Network Formulations",
    "title": "AC WR(M) variable space.  (BFM)",
    "category": "section",
    "text": "For the SDP formulation, the norm syntax is used to represent the SOC expressions below."
},

{
    "location": "formulations.html#DC-lines-3",
    "page": "Network Formulations",
    "title": "DC lines",
    "category": "section",
    "text": "The variable u^dc_ii represents (U^dc_i)^2 and i^dc_ij represents (I^dc_ij)^2.Active power flow from side: P^dc_ij + P^dc_ji = p cdot r^series cdot i^dc_ij.\nConvex relaxation of power definition: (P^dc_ij)^2 leq u^dc_ii cdot i^dc_ij.\nLifted KVL: u^dc_jj = u^dc_ii -2 p cdot r^series P^dc_ij + (r^series)^2 i^dc_ij"
},

{
    "location": "formulations.html#ACDC-converters-3",
    "page": "Network Formulations",
    "title": "ACDC converters",
    "category": "section",
    "text": "Two separate current variables, I^conv ac and i^conv ac sq are defined, the nonconvex relation i^conv ac sq = (I^conv ac)^2 is convexified, using U_i leq U_i^max:Power balance: P^conv ac_ij + P^conv dc_ji = a + bcdot I^conv ac + ccdot i^conv ac sq.\nSquared current: (P^conv ac_ij)^2 + (Q^conv ac_ij)^2 leq  u_ii cdot  i^conv ac sq\nLinear current: (P^conv ac_ij)^2 + (Q^conv ac_ij)^2 leq  (U_i^max)^2 cdot  (I^conv ac)^2\nLinking both current variables: (I^conv ac)^2 leq i^conv ac sq\nLCC converters:Q^convac geq Q^1_c + (P^convac - P^1_c)frac(Q^2_c  - Q^1_c)(P^2_c  - P^1_c)P^1_c =  cos  varphi_c^textmin cdot S^convacratedP^2_c =   cos varphi_c^textmax cdot S^convacratedQ^1_c =   sin  varphi_c^textmin cdot S^convacratedQ^2_c =   sin varphi_c^textmax cdot S^convacrated"
},

{
    "location": "formulations.html#AC-WR(M)-variable-space.-(BIM)-1",
    "page": "Network Formulations",
    "title": "AC WR(M) variable space.  (BIM)",
    "category": "section",
    "text": "For the SDP formulation, the norm syntax is used to represent the SOCs."
},

{
    "location": "formulations.html#DC-lines-4",
    "page": "Network Formulations",
    "title": "DC lines",
    "category": "section",
    "text": "The variable u^dc_ii represents (U^dc_i)^2 and u^dc_ij represents U^dc_icdot U^dc_j.Active power flow from side: P^dc_ij = p cdot g^series cdot (u^dc_ii - u^dc_ij).\nActive power flow to side: P^dc_ji = p cdot g^series cdot (u^dc_jj - u^dc_ij).\nConvex relaxation of voltage products: (u^dc_ij)^2 leq u^dc_ii cdot u^dc_jj."
},

{
    "location": "formulations.html#ACDC-converters-4",
    "page": "Network Formulations",
    "title": "ACDC converters",
    "category": "section",
    "text": "An ACDC converter model in BIM is not derived."
},

{
    "location": "specifications.html#",
    "page": "Problem Specifications",
    "title": "Problem Specifications",
    "category": "page",
    "text": ""
},

{
    "location": "specifications.html#Problem-Specifications-1",
    "page": "Problem Specifications",
    "title": "Problem Specifications",
    "category": "section",
    "text": ""
},

{
    "location": "specifications.html#ACDCOPF-1",
    "page": "Problem Specifications",
    "title": "ACDCOPF",
    "category": "section",
    "text": "OPF with support for AC and DC grids at the same time, including AC/DC converters."
},

{
    "location": "specifications.html#Variables-1",
    "page": "Problem Specifications",
    "title": "Variables",
    "category": "section",
    "text": "variable_voltage(pm)\nvariable_generation(pm)\nvariable_branch_flow(pm)"
},

{
    "location": "specifications.html#Objective-1",
    "page": "Problem Specifications",
    "title": "Objective",
    "category": "section",
    "text": "objective_min_fuel_cost(pm)"
},

{
    "location": "specifications.html#Constraints-1",
    "page": "Problem Specifications",
    "title": "Constraints",
    "category": "section",
    "text": "\nvariable_active_dcbranch_flow(pm)\nvariable_dcbranch_current(pm)\nvariable_dc_converter(pm)\nvariable_dcgrid_voltage_magnitude(pm)\n\nconstraint_voltage(pm)\nconstraint_voltage_dc(pm)\n\nfor i in ids(pm, :ref_buses)\n    constraint_theta_ref(pm, i)\nend\n\nfor i in ids(pm, :bus)\n    constraint_kcl_shunt(pm, i)\nend\n\nfor i in ids(pm, :branch)\n    # dirty, should be improved in the future TODO\n    if typeof(pm) <: PowerModels.SOCDFPowerModel\n        constraint_flow_losses(pm, i)\n        constraint_voltage_magnitude_difference(pm, i)\n        constraint_branch_current(pm, i)\n    else\n        constraint_ohms_yt_from(pm, i)\n        constraint_ohms_yt_to(pm, i)\n    end\n\n    constraint_voltage_angle_difference(pm, i)\n\n    constraint_thermal_limit_from(pm, i)\n    constraint_thermal_limit_to(pm, i)\nend\nfor i in ids(pm, :busdc)\n    constraint_kcl_shunt_dcgrid(pm, i)\nend\nfor i in ids(pm, :branchdc)\n    constraint_ohms_dc_branch(pm, i)\nend\nfor i in ids(pm, :convdc)\n    constraint_converter_losses(pm, i)\n    constraint_converter_current(pm, i)\n    constraint_conv_transformer(pm, i)\n    constraint_conv_reactor(pm, i)\n    constraint_conv_filter(pm, i)\n    if pm.ref[:nw][pm.cnw][:convdc][i][\"islcc\"] == 1\n        constraint_conv_firing_angle(pm, i)\n    end\nend"
},

{
    "location": "objective.html#",
    "page": "Objective",
    "title": "Objective",
    "category": "page",
    "text": ""
},

{
    "location": "objective.html#Objective-1",
    "page": "Objective",
    "title": "Objective",
    "category": "section",
    "text": "CurrentModule = PowerModelsACDCPowerModels.objective_min_fuel_cost"
},

{
    "location": "variables.html#",
    "page": "Variables",
    "title": "Variables",
    "category": "page",
    "text": ""
},

{
    "location": "variables.html#Variables-1",
    "page": "Variables",
    "title": "Variables",
    "category": "section",
    "text": ""
},

{
    "location": "variables.html#Functions-1",
    "page": "Variables",
    "title": "Functions",
    "category": "section",
    "text": "We provide the following methods to provide a compositional approach for defining common variables used in power flow models. These methods should always be defined over \"GenericPowerModel\", from the base PowerModels.jl.Modules = [PowerModelsACDC]\nPages   = [\"core/variable.jl\"]\nOrder   = [:type, :function]\nPrivate  = true"
},

{
    "location": "constraints.html#",
    "page": "Constraints",
    "title": "Constraints",
    "category": "page",
    "text": ""
},

{
    "location": "constraints.html#Constraints-1",
    "page": "Constraints",
    "title": "Constraints",
    "category": "section",
    "text": "All the OPF constraints for the AC grids have been re-used from PowerModels.jl, and are therefore not repeated here.CurrentModule = PowerModelsACDC"
},

{
    "location": "constraints.html#Unit-Constraints-1",
    "page": "Constraints",
    "title": "Unit Constraints",
    "category": "section",
    "text": "constraint_active_load_gen_aggregation"
},

{
    "location": "constraints.html#DC-Bus-Constraints-1",
    "page": "Constraints",
    "title": "DC Bus Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_dc_voltage_magnitude_setpoint",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_dc_voltage_magnitude_setpoint",
    "category": "function",
    "text": "vdc[i] == vdcm\n\n\n\nvdc[i] == vdcm\n\n\n\nwdc[i] == vdcm^2\n\n\n\n\n\n"
},

{
    "location": "constraints.html#Setpoint-Constraints-1",
    "page": "Constraints",
    "title": "Setpoint Constraints",
    "category": "section",
    "text": "constraint_dc_voltage_magnitude_setpoint"
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_kcl_shunt_dcgrid",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_kcl_shunt_dcgrid",
    "category": "function",
    "text": "sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == pd\n\n\n\n"
},

{
    "location": "constraints.html#KCL-Constraints-1",
    "page": "Constraints",
    "title": "KCL Constraints",
    "category": "section",
    "text": "constraint_kcl_shunt_dcgrid"
},

{
    "location": "constraints.html#AC-Bus-Constraints-1",
    "page": "Constraints",
    "title": "AC Bus Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_kcl_shunt",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_kcl_shunt",
    "category": "function",
    "text": "sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*v^2\nsum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*v^2\n\n\n\nsum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*1^2\nsum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*1^2\n\n\n\nsum(p[a] for a in bus_arcs) + sum(pconv_grid_ac[c] for c in bus_convs_ac) == sum(pg[g] for g in bus_gens)  - pd - gs*w\nsum(q[a] for a in bus_arcs) + sum(qconv_grid_ac[c] for c in bus_convs_ac) == sum(qg[g] for g in bus_gens)  - qd + bs*w\n\n\n\n"
},

{
    "location": "constraints.html#KCL-Constraints-2",
    "page": "Constraints",
    "title": "KCL Constraints",
    "category": "section",
    "text": "constraint_kcl_shunt"
},

{
    "location": "constraints.html#DC-Branch-Constraints-1",
    "page": "Constraints",
    "title": "DC Branch Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_ohms_dc_branch",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_ohms_dc_branch",
    "category": "function",
    "text": "Creates Ohms constraints for DC branches\n\np[f_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])\n\n\n\nCreates Ohms constraints for DC branches\n\np[f_idx] + p[t_idx] == 0)\n\n\n\nCreates Ohms constraints for DC branches\n\np[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])\n\n\n\nCreates Ohms constraints for DC branches\n\np[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])\n\n\n\n"
},

{
    "location": "constraints.html#Ohm\'s-Law-Constraints-1",
    "page": "Constraints",
    "title": "Ohm\'s Law Constraints",
    "category": "section",
    "text": "constraint_ohms_dc_branch\n"
},

{
    "location": "constraints.html#ACDC-Converter-Constraints-1",
    "page": "Constraints",
    "title": "ACDC Converter Constraints",
    "category": "section",
    "text": ""
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_converter_losses",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_converter_losses",
    "category": "function",
    "text": "Creates lossy converter model between AC and DC grid\n\npconv_ac[i] + pconv_dc[i] == a + bI + cI^2\n\n\n\nCreates lossy converter model between AC and DC grid, assuming U_i is approximatley 1 numerically\n\npconv_ac[i] + pconv_dc[i] == a + b*pconv_ac\n\n\n\nCreates lossy converter model between AC and DC side\n\npconv_ac[i] + pconv_dc[i] == a + b*I + c*Isq\n\n\n\n"
},

{
    "location": "constraints.html#Ohm\'s-Law-Constraints-2",
    "page": "Constraints",
    "title": "Ohm\'s Law Constraints",
    "category": "section",
    "text": "constraint_converter_losses"
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_converter_current",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_converter_current",
    "category": "function",
    "text": "Links converter power & current\n\npconv_ac[i]^2 + pconv_dc[i]^2 == vmc[i]^2 * iconv_ac[i]^2\n\n\n\nConverter current constraint (not applicable)\n\n\n\n\n\nLinks converter power & current\n\npconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]\npconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2\n\n\n\nLinks converter power & current\n\npconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]\npconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2\n\n\n\nLinks converter power & current\n\npconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]\npconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2\n\n\n\n"
},

{
    "location": "constraints.html#Current-1",
    "page": "Constraints",
    "title": "Current",
    "category": "section",
    "text": "constraint_converter_current"
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_active_conv_setpoint",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_active_conv_setpoint",
    "category": "function",
    "text": "pconv[i] == pconv\n\n\n\n"
},

{
    "location": "constraints.html#Setpoint-Constraints-(PF-only)-1",
    "page": "Constraints",
    "title": "Setpoint Constraints (PF only)",
    "category": "section",
    "text": "constraint_active_conv_setpoint"
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_conv_transformer",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_conv_transformer",
    "category": "function",
    "text": "Converter transformer constraints\n\np_tf_fr ==  g/(tm^2)*vm_fr^2 + -g/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -b/(tm)*vm_fr*vm_to*sin(va_fr-va_to)\nq_tf_fr == -b/(tm^2)*vm_fr^2 +  b/(tm)*vm_fr*vm_to * cos(va_fr-va_to) + -g/(tm)*vm_fr*vm_to*sin(va_fr-va_to)\np_tf_to ==  g*vm_to^2 + -g/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -b/(tm)*vm_to*vm_fr    *sin(va_to - va_fr)\nq_tf_to == -b*vm_to^2 +  b/(tm)*vm_to*vm_fr  *    cos(va_to - va_fr)     + -g/(tm)*vm_to*vm_fr    *sin(va_to - va_fr)\n\n\n\nConverter transformer constraints\n\np_tf_fr == -btf*(v^2)/tm*(va-vaf)\np_tf_to == -btf*(v^2)/tm*(vaf-va)\n\n\n\nConverter transformer constraints\n\np_tf_fr + ptf_to ==  rtf*itf\nq_tf_fr + qtf_to ==  xtf*itf\np_tf_fr^2 + qtf_fr^2 <= w/tm^2 * itf\nwf == w/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf\n\n\n\nConverter transformer constraints\n\np_tf_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)\nq_tf_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)\np_tf_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))\nq_tf_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))\n\n\n\n"
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_conv_reactor",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_conv_reactor",
    "category": "function",
    "text": "Converter reactor constraints\n\n-pconv_ac == gc*vmc^2 + -gc*vmc*vmf*cos(vac-vaf) + -bc*vmc*vmf*sin(vac-vaf)\n-qconv_ac ==-bc*vmc^2 +  bc*vmc*vmf*cos(vac-vaf) + -gc*vmc*vmf*sin(vac-vaf)\np_pr_fr ==  gc *vmf^2 + -gc *vmf*vmc*cos(vaf - vac) + -bc *vmf*vmc*sin(vaf - vac)\nq_pr_fr == -bc *vmf^2 +  bc *vmf*vmc*cos(vaf - vac) + -gc *vmf*vmc*sin(vaf - vac)\n\n\n\nConverter reactor constraints\n\np_pr_fr == -bc*(v^2)*(vaf-vac)\npconv_ac == -bc*(v^2)*(vac-vaf)\n\n\n\nConverter reactor constraints\n\np_pr_fr + ppr_to == rc*ipr\nq_pr_fr + qpr_to == xc*ipr\np_pr_fr^2 + qpr_fr^2 <= wf * ipr\nwc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr\n\n\n\nConverter reactor constraints\n\np_pr_fr ==  g/(tm^2)*w_fr + -g/(tm)*wr + -b/(tm)*wi)\nq_pr_fr == -b/(tm^2)*w_fr +  b/(tm)*wr + -g/(tm)*wi)\np_pr_to ==  g*w_to + -g/(tm)*wr     + -b/(tm)*(-wi))\nq_pr_to == -b*w_to +  b/(tm)*wr     + -g/(tm)*(-wi))\n\n\n\n"
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_conv_filter",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_conv_filter",
    "category": "function",
    "text": "Converter filter constraints\n\nppr_fr + ptf_to == 0\nqpr_fr + qtf_to +  (-bv) * filter *vmf^2 == 0\n\n\n\nConverter filter constraints (no active power losses)\n\np_pr_fr + p_tf_to == 0\n\n\n\nConverter filter constraints\n\np_pr_fr + p_tf_to == 0\nq_pr_fr + q_tf_to + -bv*filter*wf == 0\n\n\n\n"
},

{
    "location": "constraints.html#Converter-auxiliary-constraints-1",
    "page": "Constraints",
    "title": "Converter auxiliary constraints",
    "category": "section",
    "text": "constraint_conv_transformer\nconstraint_conv_reactor\nconstraint_conv_filter"
},

{
    "location": "constraints.html#PowerModelsACDC.constraint_conv_firing_angle",
    "page": "Constraints",
    "title": "PowerModelsACDC.constraint_conv_firing_angle",
    "category": "function",
    "text": "LCC firing angle constraints\n\npconv_ac == cos(phi) * Srated\nqconv_ac == sin(phi) * Srated\n\n\n\nConverter firing angle constraint (not applicable)\n\n\n\n\n\nLCC firing angle constraints\n\nqconv_ac >= Q1 + (pconv_ac-P1) * (Q2-Q1)/(P2-P1)\n\nP1 = cos(0) * Srated\nQ1 = sin(0) * Srated\nP2 = cos(pi) * Srated\nQ2 = sin(pi) * Srated\n\n\n\n"
},

{
    "location": "constraints.html#Converter-firing-angle-for-LCC-1",
    "page": "Constraints",
    "title": "Converter firing angle for LCC",
    "category": "section",
    "text": "constraint_conv_firing_angle"
},

{
    "location": "parser.html#",
    "page": "File IO",
    "title": "File IO",
    "category": "page",
    "text": ""
},

{
    "location": "parser.html#File-IO-1",
    "page": "File IO",
    "title": "File IO",
    "category": "section",
    "text": "CurrentModule = PowerModelsACDC"
},

{
    "location": "parser.html#Specific-Data-Formats-1",
    "page": "File IO",
    "title": "Specific Data Formats",
    "category": "section",
    "text": "The .m matpower files have been extended with the fields as described in the MatACDC manual, available in https://www.esat.kuleuven.be/electa/teaching/matacdc#documentation."
},

{
    "location": "parser.html#DC-Bus-1",
    "page": "File IO",
    "title": "DC Bus",
    "category": "section",
    "text": "busdc_i   - DC bus number\ngrid      - DC grid to which the DC bus is connected (in case multiple DC grids)\nPdc       - Power withdrawn from the DC grid (MW) (only for PF)\nVdc       - DC voltage (p.u.)\nbasekVdc  - Base DC voltage (kV)\nVdcmax    - maximum DC voltage (p.u.)\nVdcmin    - minimum DC voltage (p.u.)\nCdc       - DC bus capacitor size (p.u.), (not used in (optimal) power flow)"
},

{
    "location": "parser.html#DC-Branch-1",
    "page": "File IO",
    "title": "DC Branch",
    "category": "section",
    "text": "fbusdc  - from bus number DC\ntbusdc  - to bus number DC\nr       - resistance (p.u.)\nl       - inductance (p.u./s) (not used in (optimal) power flow)\nc       - total line charging capacity (p.u. * s) (not used in power flow)\nrateA   - MVA rating A\nrateB   - MVA rating B (long termrating, not used)\nrateC   - MVA rating C (long termrating, not used)\nstatus  - initial branch status, (1 - in service, 0 - out of service) (not yet implemented)"
},

{
    "location": "parser.html#AC-DC-converter-1",
    "page": "File IO",
    "title": "AC DC converter",
    "category": "section",
    "text": "busdc_i     - converter bus number (DC bus numbering)\nbusac_i     - converter bus number (AC bus numbering)  \ntype_dc     - DC bus type (1 = constant power, 2 = DC slack, 3 = DC droop) (only power flow)  \ntype_ac     - AC bus type (1 = PQ, 2 = PV), should be consistent with AC bus  (only power flow)  \nP_g         - active power injected in the AC grid (MW)\nQ_g         - reactive power injected in the AC grid (MVAr)    \nVtar        - target voltage of converter connected AC bus (p.u.)\nislcc       - binary indicating LCC converter (islcc = 1 -> LCC)\nrtf         - transformer resistance (p.u.) (not yet implemented)\nxtf         - transformer reactance (p.u.) (not yet implemented)\ntransformer - binary indicating converter transformer    \nbf          - filter susceptance (p.u.) (not yet implemented)\nfilter      - binary indicating converter filter\nrc          - phase reactor resistance (p.u.) (not yet implemented)   \nxc          - phase reactor reactance (p.u.) (not yet implemented)\nreactor     - binary indicating converter reactor\nbasekVac    - converter AC base voltage (kV)    \nVmmax       - maximum converter voltage magnitude (p.u.)   \nVmmin       - minimumconverter voltagemagnitude (p.u.)   \nImax        - maximum converter current (p.u.)   \nstatus      - converter status (1 = on, 0 = off) (not yet implemented)\nLossA       - constant loss coefficient (MW)\nLossB       - linear loss coefficient (kV)\nLossCrec    - rectifier quadratic loss coefficient (Ω­)\nLossCinv    - inverter quadratic loss coefficient (Ω­) (not yet implemented)\ndroop       - DC voltage droop (MW/p.u) (not yet implemented)      \nPdcset      - voltage droop power set-point (MW)  (not yet implemented)\nVdcset      - voltage droop voltage set-point (p.u.) (not yet implemented)\ndVdcset     - voltage droop deadband (p.u.) (optional) (not yet implemented)\nPacmax      - Maximum AC active power (MW)\nPacmin      - Minimum AC active power (MW)\nQacmax      - Maximum AC reactive power (Mvar)\nQacmin      - Minimum AC reactive power (Mvar)"
},

]}
