using PowerModelsACDC
using PowerModels
using Ipopt
#using CPLEX
using SCS
#using Mosek

files =
[
"./test/data/case5_2grids.m";
"./test/data/case5_acdc.m";
"./test/data/case5_lcc.m";
"./test/data/case5_b2bdc.m";
#"./test/data/case5_dc.m"; #Don't use normally
"./test/data/case5_dcgrid.m";
"./test/data/case5_dcgrid_b0.m";
"./test/data/case24_3zones_acdc.m";
"./test/data/case39_acdc.m";
"./test/data/case3120sp_acdc.m";
]



scs = SCSSolver(max_iters=100000);
ipopt = IpoptSolver(tol=1e-6, print_level=0)
#mosek = MosekSolver()
s = Dict("output" => Dict("branch_flows" => true))

objective = Dict{String, Any}()

function exctract_info(dict)
    return Dict("obj" => dict["objective"], "solve_time" => dict["solve_time"], "result" => dict )
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
    data = PowerModels.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    #fix_things!(data)

    case = Dict{String, Any}()

    resultAC = run_acdcopf(data, ACPPowerModel, ipopt; setting = s)
    case["AC NLP"] = exctract_info(resultAC)

    resultQC = run_acdcopf(data, QCWRPowerModel, ipopt; setting = s)
    case["QC SOC"] = exctract_info(resultQC)
    # #
    resultQCTri = run_acdcopf(data, QCWRTriPowerModel, ipopt; setting = s)
    case["QCTri SOC"] = exctract_info(resultQCTri)
    # #
    resultSOCBIM = run_acdcopf(data, SOCWRPowerModel, ipopt; setting = s)
    case["BIM SOC"] = exctract_info(resultSOCBIM)
    # #
    resultSOCBFM = run_acdcopf(data, SOCBFPowerModel, ipopt; setting = s)
    case["BFM SOC"] = exctract_info(resultSOCBFM)
    # #
    #resultSDP = run_acdcopf(data, SDPWRMPowerModel, scs; setting = s)
    #case["BIM SDP"] = exctract_info(resultSDP)
    case["BIM SDP"] = exctract_info(resultSOCBFM)
    # # #
    resultDC = run_acdcopf(data, DCPPowerModel, ipopt; setting = s)
    case["DC LP"] = exctract_info(resultDC)
    #
    objective[file] = case
end

calc_gap(objective)


function print_table_opt_gap(dict)
    s = ""
    c = " & "
    s = s*"case"*c*"AC NLP"*c* "QC SOC" *c*c* "QCTri SOC" *c*c* "BIM SOC" *c*c* "BFM SOC" *c*c* "BIM SDP" *c*c* "DC LP"*c*raw"\ "[1]*raw"\ "* " \n"
    for (filename, ff) in dict
        s = s*filename
        l = 6
        l2 = 8
        p = 100
        s = s *c*string(Base.signif(ff["AC NLP"]["obj"], l))
        s = s *c*string(Base.signif(ff["BIM SDP"]["obj"], l))
        s = s *c*string(Base.signif(p*ff["BIM SDP"]["gap"], l))
        s = s *c*string(Base.signif(ff["QC SOC"]["obj"], l))
        s = s *c*string(Base.signif(p*ff["QC SOC"]["gap"], l))
        # s = s *c*string(ff["QCTri SOC"]["obj"])[1:l2]
        # s = s *c*string(p*ff["QCTri SOC"]["gap"])[1:l]
        s = s *c*string(Base.signif(ff["BIM SOC"]["obj"], l))
        s = s *c*string(Base.signif(p*ff["BIM SOC"]["gap"], l))
        s = s *c*string(Base.signif(ff["BFM SOC"]["obj"], l))
        s = s *c*string(Base.signif(p*ff["BFM SOC"]["gap"], l))
        s = s *c*string(Base.signif(ff["DC LP"]["obj"], l))
        s = s *c*string(Base.signif(p*ff["DC LP"]["gap"], l))

        s = s*raw"\ "[1]*raw"\ "*" \n"
    end
    return s
end
clearconsole()
stt = print_table_opt_gap(objective)
print(stt)
