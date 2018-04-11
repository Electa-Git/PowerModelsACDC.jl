using PowerModelsACDC
using PowerModels
using Ipopt
#using CPLEX
using SCS
using Mosek

files =
[
"./test/data/case5_2grids.m";
"./test/data/case5_acdc.m";
"./test/data/case5_dcgrid.m";
"./test/data/case24_3zones_acdc.m";
"./test/data/case39_acdc.m";
"./test/data/case3120sp_acdc.m";
]



scs = SCSSolver(max_iters=100000);
ipopt = IpoptSolver(tol=1e-6, print_level=0)
mosek = MosekSolver()
s = Dict("output" => Dict("branch_flows" => true))

objective = Dict{String, Any}()

function exctract_info(dict)
    return Dict("obj" => dict["objective"], "solve_time" => dict["solve_time"], "result" => dict )
end

#
function fix_things!(data)
    # fix number of poles
    data["dcpol"] = 1
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
    fix_things!(data)

    case = Dict{String, Any}()

    resultAC = run_acdcopf(data, ACPPowerModel, ipopt; setting = s)
    case["AC NLP obj"] = exctract_info(resultAC)

    resultQC = run_acdcopf(data, QCWRPowerModel, ipopt; setting = s)
    case["QC SOC"] = exctract_info(resultQC)
    # #
    resultQCTri = run_acdcopf(data, QCWRTriPowerModel, ipopt; setting = s)
    case["QCTri SOC"] = exctract_info(resultQCTri)
    # #
    resultSOCBIM = run_acdcopf(data, SOCWRPowerModel, ipopt; setting = s)
    case["BIM SOC"] = exctract_info(resultSOCBIM)
    # #
    resultSOCBFM = run_acdcopf(data, SOCDFPowerModel, ipopt; setting = s)
    case["BFM SOC"] = exctract_info(resultSOCBFM)
    # #
    resultSDP = run_acdcopf(data, SDPWRMPowerModel, mosek; setting = s)
    case["BIM SDP"] = exctract_info(resultSDP)
    # # #
    resultDC = run_acdcopf(data, DCPPowerModel, mosek; setting = s)
    case["DC LP"] = exctract_info(resultDC)
    #
    objective[file] = case
end
