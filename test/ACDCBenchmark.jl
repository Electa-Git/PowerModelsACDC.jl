using PowerModelsACDC
using PowerModels
using Ipopt
#using CPLEX
using SCS

files =
[
"./test/data/case5_2grids.m";
"./test/data/case5_acdc.m";
"./test/data/case5_dc.m";
"./test/data/case24_3zones_acdc.m";
]

scs = SCSSolver(max_iters=100000);
ipopt = IpoptSolver(tol=1e-6, print_level=0)
s = Dict("output" => Dict("branch_flows" => true))

objective = Dict{String, Any}()

for file in files
    case = Dict{String, Any}()

    resultAC = run_acdcopf(file, ACPPowerModel, ipopt; setting = s)
    case["AC NLP"] = resultAC["objective"]
    #
    resultQC = run_acdcopf(file, QCWRPowerModel, ipopt; setting = s)
    case["QC SOC"] = resultQC["objective"]
    # #
    resultQCTri = run_acdcopf(file, QCWRTriPowerModel, ipopt; setting = s)
    case["QCTri SOC"] = resultQCTri["objective"]
    # #
    resultSOCBIM = run_acdcopf(file, SOCWRPowerModel, ipopt; setting = s)
    case["BIM SOC"] = resultSOCBIM["objective"]
    # #
    resultSOCBFM = run_acdcopf(file, SOCDFPowerModel, ipopt; setting = s)
    case["BFM SOC"] = resultSOCBFM["objective"]
    # #
    resultSDP = run_acdcopf(file, SDPWRMPowerModel, scs; setting = s)
    case["BIM SDP"] = resultSDP["objective"]
    # #
    resultDC = run_acdcopf(file, DCPPowerModel, ipopt; setting = s)
    case["DC LP"] = resultDC["objective"]
    #
    objective[file] = case
end
