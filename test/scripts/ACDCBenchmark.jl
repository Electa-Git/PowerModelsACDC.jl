using PowerModelsACDC
using PowerModels
using Ipopt
#using CPLEX
using SCS
using Mosek
using MosekTools
using JuMP
files =
[
"./test/data/case5_2grids.m";
"./test/data/case3120sp_acdc.m";
# "./test/data/case5_lcc.m";
"./test/data/case5_b2bdc.m";
# "./test/data/case5_dc.m"; #Don't use normally
"./test/data/case5_dcgrid.m";
"./test/data/case5_dcgrid_b0.m";
"./test/data/case24_3zones_acdc.m";
"./test/data/case39_acdc.m";
"./test/data/case3120sp_acdc.m";
"./test/data/pglib_opf_case588_sdet_acdc.m"
]



ipopt = JuMP.with_optimizer(Ipopt.Optimizer, tol=1e-6, print_level=0)
mosek = JuMP.with_optimizer(Mosek.Optimizer)
scs = JuMP.with_optimizer(SCS.Optimizer)
#mosek = MosekSolver()
s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => true)

objective = Dict{String, Any}()

function exctract_info(dict)
    return Dict("obj" => dict["objective"], "solve_time" => dict["solve_time"], "result" => dict, "u_error" => 0, "pf_error" => 0, "pfdc_error" => 0, "u_error_rel" => 0, "pf_error_rel" => 0, "pfdc_error_rel" => 0  )
end

function calc_gap(dict)
    for (filename, formulations) in dict
        for (formulation, results) in formulations
            print(formulation)
            ac = formulations["AC NLP"]["obj"]
            results["gap"] = (ac - results["obj"])/ac
        end
    end
end

function calc_errors(dict)
    for (filename, formulations) in dict
        for (formulation, results) in formulations
            print(formulation)
            for (bus_id, bus) in formulations["AC NLP"]["result"]["solution"]["bus"]
                results["u_error"] = results["u_error"] + (bus["vm"] - results["result"]["solution"]["bus"][bus_id]["vm"])^2
            end
            results["u_error"] = results["u_error"] / length(formulations["AC NLP"]["result"]["solution"]["bus"])
            for (branch_id, branch) in formulations["AC NLP"]["result"]["solution"]["branch"]
                results["pf_error"] = results["pf_error"] + (branch["pf"] - results["result"]["solution"]["branch"][branch_id]["pf"])^2
            end
            results["pf_error"] = results["pf_error"] / length(formulations["AC NLP"]["result"]["solution"]["branch"])
            for (branch_id, branch) in formulations["AC NLP"]["result"]["solution"]["branchdc"]
                results["pfdc_error"] = results["pfdc_error"] + (branch["pf"] - results["result"]["solution"]["branchdc"][branch_id]["pf"])^2
            end
            results["pfdc_error"] = results["pfdc_error"] / length(formulations["AC NLP"]["result"]["solution"]["branchdc"])
        end
    end
end


function calc_errors_rel(dict)
    for (filename, formulations) in dict
        for (formulation, results) in formulations
            print(formulation)
            for (bus_id, bus) in formulations["AC NLP"]["result"]["solution"]["bus"]
                results["u_error_rel"] = results["u_error_rel"] + abs(bus["vm"] - results["result"]["solution"]["bus"][bus_id]["vm"])/abs(bus["vm"]+1e-5)
            end
            results["u_error_rel"] = results["u_error_rel"] / length(formulations["AC NLP"]["result"]["solution"]["bus"])
            for (branch_id, branch) in formulations["AC NLP"]["result"]["solution"]["branch"]
                results["pf_error_rel"] = results["pf_error_rel"] + abs(branch["pf"] - results["result"]["solution"]["branch"][branch_id]["pf"])/abs(branch["pf"]+1e-5)
            end
            results["pf_error_rel"] = results["pf_error_rel"] / length(formulations["AC NLP"]["result"]["solution"]["branch"])
            for (branch_id, branch) in formulations["AC NLP"]["result"]["solution"]["branchdc"]
                results["pfdc_error_rel"] = results["pfdc_error_rel"] + abs(branch["pf"] - results["result"]["solution"]["branchdc"][branch_id]["pf"])/abs(branch["pf"]+1e-5)
            end
            results["pfdc_error_rel"] = results["pfdc_error_rel"] / length(formulations["AC NLP"]["result"]["solution"]["branchdc"])
        end
    end
end


#
function fix_things!(data)
    # fix number of poles
    # data["dcpol"] = 1
    #tap = 1
    for (i,conv) in data["convdc"]
        # remove transformer and phase reactor from relaxation
        # conv["reactor"] = 0
        #conv["transformer"] = 0
        #conv["filter"] = 0
        #conv["tm"] = 1
        #conv["LossA"] = 0
        #conv["LossB"] = 0
        #conv["LossC"] = 0
    end
end

for file in files
    data = _PM.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    #fix_things!(data)

    case = Dict{String, Any}()
    er_dict = Dict{String, Any}()

    resultAC = run_acdcopf(data, ACPPowerModel, ipopt; setting = s)
    case["AC NLP"] = exctract_info(resultAC)

    resultQC = run_acdcopf(data, QCWRPowerModel, ipopt; setting = s)
    case["QC SOC"] = exctract_info(resultQC)
    # #
    # resultQCTri = run_acdcopf(data, QCWRTriPowerModel, ipopt; setting = s)
    # case["QCTri SOC"] = exctract_info(resultQCTri)
    # #
    resultSOCBIM = run_acdcopf(data, SOCWRPowerModel, ipopt; setting = s)
    case["BIM SOC"] = exctract_info(resultSOCBIM)
    # #
    resultSOCBFM = run_acdcopf_bf(data, SOCBFPowerModel, ipopt; setting = s)
    case["BFM SOC"] = exctract_info(resultSOCBFM)
    # #
    case["BIM SDP"] = exctract_info(resultAC)
    # resultSDP = run_acdcopf(data, SDPWRMPowerModel, mosek; setting = s)
    # case["BIM SDP"] = exctract_info(resultSDP)
    # # #
    resultDC = run_acdcopf(data, DCPPowerModel, ipopt; setting = s)
    case["DC LP"] = exctract_info(resultDC)
    #
    resultLPAC = run_acdcopf(data, LPACCPowerModel, ipopt; setting = s)
    case["LPAC"] = exctract_info(resultLPAC)


    objective[file] = case
end

calc_gap(objective)
calc_errors(objective)
calc_errors_rel(objective)


function print_table_opt_gap(dict)
    s = ""
    c = " & "
    s = s*"case"*c*"AC NLP"*c* "BIM SDP" *c*c*  "QC SOC" *c*c* "BIM SOC" *c*c* "BFM SOC" *c*c*"DC LP" *c*c*"LPAC"*c*raw"\ "[1]*raw"\ "* " \n"
    for (filename, ff) in dict
        s = s*filename
        l = 2
        l2 = 8
        p = 100

        s = s *c*string(round(ff["AC NLP"]["obj"], digits = l))
        s = s *c*string(round(ff["BIM SDP"]["obj"], digits = l))
        s = s *c*string(round(p*ff["BIM SDP"]["gap"], digits = l))
        s = s *c*string(round(ff["QC SOC"]["obj"], digits = l))
        s = s *c*string(round(p*ff["QC SOC"]["gap"], digits = l))
        # s = s *c*string(roundff["QCTri SOC"]["obj"])[1:l2]
        # s = s *c*string(roundp*ff["QCTri SOC"]["gap"])[1:l]
        s = s *c*string(round(ff["BIM SOC"]["obj"], digits = l))
        s = s *c*string(round(p*ff["BIM SOC"]["gap"], digits = l))
        s = s *c*string(round(ff["BFM SOC"]["obj"], digits = l))
        s = s *c*string(round(p*ff["BFM SOC"]["gap"], digits = l))
        s = s *c*string(round(ff["DC LP"]["obj"], digits = l))
        s = s *c*string(round(p*ff["DC LP"]["gap"], digits = l))
        s = s *c*string(round(ff["LPAC"]["obj"], digits = l))
        s = s *c*string(round(p*ff["LPAC"]["gap"], digits = l))
        s = s*raw"\ "[1]*raw"\ "*" \n"
    end
    return s
end
clearconsole()
stt = print_table_opt_gap(objective)
print(stt)
function print_table_errors(dict)
    s = ""
    c = " & "
    s = s*"case"*c*"BIM SDP"*c*c*c* "QC SOC"*c*c*c* "BIM SOC"*c*c*c* "BFM SOC"*c*c*c*raw"\ "[1]*raw"\ "* " \n"
    for (filename, ff) in dict
        s = s*filename
        l = 6
        l2 = 8
        p = 100
        s = s *c*string(round(ff["BIM SDP"]["u_error"], digits = l))
        s = s *c*string(round(p*ff["BIM SDP"]["pf_error"], digits = l))
        s = s *c*string(round(p*ff["BIM SDP"]["pfdc_error"], digits = l))
        s = s *c*string(round(ff["QC SOC"]["u_error"], digits = l))
        s = s *c*string(round(p*ff["QC SOC"]["pf_error"], digits = l))
        s = s *c*string(round(p*ff["QC SOC"]["pfdc_error"], digits = l))
        s = s *c*string(round(ff["BIM SOC"]["u_error"], digits = l))
        s = s *c*string(round(p*ff["BIM SOC"]["pf_error"], digits = l))
        s = s *c*string(round(p*ff["BIM SOC"]["pfdc_error"], digits = l))
        s = s *c*string(round(ff["BFM SOC"]["u_error"], digits = l))
        s = s *c*string(round(p*ff["BFM SOC"]["pf_error"], digits = l))
        s = s *c*string(round(p*ff["BFM SOC"]["pfdc_error"], digits = l))

        s = s*raw"\ "[1]*raw"\ "*" \n"
    end
    return s
end
stt = print_table_errors(objective)
print(stt)

function print_table_errors_rel(dict)
    s = ""
    c = " & "
    s = s*"case"*c*"BIM SDP"*c*c*c* "QC SOC"*c*c*c* "BIM SOC"*c*c*c* "BFM SOC"*c*c*c*raw"\ "[1]*raw"\ "* " \n"
    for (filename, ff) in dict
        s = s*filename
        l = 6
        l2 = 8
        p = 100
        s = s *c*string(round(p*ff["BIM SDP"]["u_error_rel"], digits = l))
        s = s *c*string(round(p*ff["BIM SDP"]["pf_error_rel"], digits = l))
        s = s *c*string(round(p*ff["BIM SDP"]["pfdc_error_rel"], digits = l))
        s = s *c*string(round(p*ff["QC SOC"]["u_error_rel"], digits = l))
        s = s *c*string(round(p*ff["QC SOC"]["pf_error_rel"], digits = l))
        s = s *c*string(round(p*ff["QC SOC"]["pfdc_error_rel"], digits = l))
        s = s *c*string(round(p*ff["BIM SOC"]["u_error_rel"], digits = l))
        s = s *c*string(round(p*ff["BIM SOC"]["pf_error_rel"], digits = l))
        s = s *c*string(round(p*ff["BIM SOC"]["pfdc_error_rel"], digits = l))
        s = s *c*string(round(p*ff["BFM SOC"]["u_error_rel"], digits = l))
        s = s *c*string(round(p*ff["BFM SOC"]["pf_error_rel"], digits = l))
        s = s *c*string(round(p*ff["BFM SOC"]["pfdc_error_rel"], digits = l))
        # s = s *c*string(round(p*ff["DC LP"]["u_error_rel"], digits = l))
        # s = s *c*string(round(p*ff["DC LP"]["pf_error_rel"], digits = l))
        # s = s *c*string(round(p*ff["DC LP"]["pfdc_error_rel"], digits = l))

        s = s*raw"\ "[1]*raw"\ "*" \n"
    end
    return s
end
stt = print_table_errors_rel(objective)
print(stt)
function print_table_comp_time(dict)
    s = ""
    c = " & "
    s = s*"case"*c*"BIM NLP"*c*"BIM SDP"*c* "QC SOC"*c*c*c* "BIM SOC"*c*c*c* "BFM SOC"*c*c*c*raw"\ "[1]*raw"\ "* " \n"
    for (filename, ff) in dict
        s = s*filename
        l = 6
        l2 = 8
        p = 100
        s = s *c*string(round(ff["AC NLP"]["solve_time"], digits = l))
        s = s *c*string(round(ff["BIM SDP"]["solve_time"], digits = l))
        s = s *c*string(round(ff["QC SOC"]["solve_time"], digits = l))
        s = s *c*string(round(ff["BIM SOC"]["solve_time"], digits = l))
        s = s *c*string(round(ff["BFM SOC"]["solve_time"], digits = l))
        s = s *c*string(round(ff["DC LP"]["solve_time"], digits = l))

        s = s*raw"\ "[1]*raw"\ "*" \n"
    end
    return s
end
stt = print_table_comp_time(objective)
print(stt)
