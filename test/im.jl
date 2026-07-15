
function inductionmachinedata()
    
    global_dict = PowerModelsACDC._get_pu_bases(1000, 220) # 3-PH MVA, LL-RMS, Original setting was 100,320
    global_dict["omega"] = 2π * 50
    data = Dict{String, Any}()
    
    data["source_type"] = "matpower"
    data["name"] = "network"
    data["source_version"] = "0.0.0"
    data["per_unit"] = true
    data["dcpol"] = 2 # Monopolar (1) or bipolar and symmetrically grounded monopolar (2)
    data["baseMVA"] = global_dict["S"] / 1e6
    data["bus"] = Dict{String, Any}()
    data["im"] = Dict{String, Any}()
    data["busdc"] = Dict{String, Any}()
    data["shunt"] = Dict{String, Any}()     # empty
    data["dcline"] = Dict{String, Any}()    # empty
    data["storage"] = Dict{String, Any}()   # empty
    data["switch"] = Dict{String, Any}()    # empty
    data["load"] = Dict{String, Any}()      # empty
    data["branch"] = Dict{String, Any}()
    data["branchdc"] = Dict{String, Any}()
    data["gen"] = Dict{String, Any}()
    data["im"] = Dict{String, Any}()
    data["sssc"] = Dict{String, Any}()  # empty (avoid warning from PMACDC)
    data["im"] = Dict{String, Any}()
    data["sssc"] = Dict{String, Any}()  # empty (avoid warning from PMACDC)
    data["convdc"] = Dict{String, Any}()
    data["pst"] = Dict{String, Any}() ## Empty (Phase shifting transformer)
    data["gendc"] = Dict{String, Any}()


    #Add one bus
    bus = string(1)
    
    (data["bus"])[bus] = Dict{String, Any}()
    ((data["bus"])[bus])["source_id"] = Any["bus", parse(Int, bus)]
    ((data["bus"])[bus])["index"] = parse(Int, bus)
    ((data["bus"])[bus])["bus_i"] = parse(Int, bus)
    ((data["bus"])[bus])["zone"] = 1
    ((data["bus"])[bus])["area"] = 1
    ((data["bus"])[bus])["vmin"] = 0.9
    ((data["bus"])[bus])["vmax"] = 1.1
    ((data["bus"])[bus])["vm"] = 1
    ((data["bus"])[bus])["va"] = 0
    ((data["bus"])[bus])["base_kv"] = global_dict["V"] / 1e3
    ((data["bus"])[bus])["bus_type"] = 3 # bus type - depends on components 1 is default PQ

    # Add ideal voltage source

    key = 1
    key = string(key)

    # Network component
    (data["gen"])[key] = Dict{String, Any}()
    ((data["gen"])[key])["mBase"] = global_dict["S"] / 1e6
    ((data["gen"])[key])["gen_bus"] = 1     
    ((data["gen"])[key])["pc1"] = 0
    ((data["gen"])[key])["pc2"] = 0
    ((data["gen"])[key])["qc1min"] = 0
    ((data["gen"])[key])["qc1max"] = 0
    ((data["gen"])[key])["qc2min"] = 0
    ((data["gen"])[key])["qc2max"] = 0
    ((data["gen"])[key])["ramp_agc"] = 0
    ((data["gen"])[key])["ramp_q"] = 0
    ((data["gen"])[key])["ramp_10"] = 0
    ((data["gen"])[key])["ramp_30"] = 0
    ((data["gen"])[key])["apf"] = 0
    ((data["gen"])[key])["startup"] = 0
    ((data["gen"])[key])["shutdown"] = 0

    ((data["gen"])[key])["gen_status"] = 1
    ((data["gen"])[key])["source_id"] = Any["gen", parse(Int, key)]
    ((data["gen"])[key])["index"] = parse(Int, key)

    ((data["gen"])[key])["pg"] =0.0
    ((data["gen"])[key])["qg"] = 0.0
    ((data["gen"])[key])["pmin"] = 0.0
    ((data["gen"])[key])["pmax"] = 0.0
    ((data["gen"])[key])["qmin"] = 0.0
    ((data["gen"])[key])["qmax"] = 0.0
    ((data["gen"])[key])["vg"] = 1.0 #Accesor function to treat multiple field names for AC Voltage

    # not using
    ((data["gen"])[key])["model"] = 1
    ((data["gen"])[key])["cost"] = 0
    ((data["gen"])[key])["ncost"] = 0

    # Add induction machine data

    key=1
    key_str = string(key)
    ac_bus = 1

    
    impscale = 1.0#((machine.Vᵃᶜ_base)^2/machine.S_base)/global_dict["Z_base"]

    data["im"][key_str] = Dict{String, Any}()
    
    machine = (;T_0 = 0.9, l_rl=0.165, l_m=1.66,l_sl=0.15,r_r=0.01,r_s=0.01,A=0.95,B=0.05,C=0,m=2)    # Power flow initial values
    data["im"][key_str]["P_ag"] = machine.T_0/global_dict["S"]
    data["im"][key_str]["Q_ag"] = 0.0
    data["im"][key_str]["status"] = 1
    data["im"][key_str]["im_bus"] = ac_bus

    # Power flow limits (not used in power flow)
    data["im"][key_str]["Pacmin"] = 0.9 * machine.T_0/global_dict["S"]
    data["im"][key_str]["Vmmin"] = 0.9 # Should be extended with local_base/global_base but we do not care (not used in PF)
    data["im"][key_str]["Vmmax"] = 1.1
    data["im"][key_str]["Pacmax"] = 1.1 * machine.T_0 /global_dict["S"]
    data["im"][key_str]["Pacrated"] = machine.T_0 /global_dict["S"]

    # Power flow elements
    data["im"][key_str]["x_m"] = machine.l_m * impscale # In per unit equal
    data["im"][key_str]["x_rl"] = machine.l_rl * impscale
    data["im"][key_str]["x_sl"] = machine.l_sl * impscale
    data["im"][key_str]["r_r"] = machine.r_r * impscale
    data["im"][key_str]["r_s"] = machine.r_s * impscale

    # Torque parameters
    data["im"][key_str]["torque"] =  Dict{String, Any}()
    data["im"][key_str]["torque"]["T_0"] = machine.T_0 
    data["im"][key_str]["torque"]["A"] = machine.A
    data["im"][key_str]["torque"]["B"] = machine.B
    data["im"][key_str]["torque"]["C"] = machine.C
    data["im"][key_str]["torque"]["m"] = machine.m

    return data
end

@testset "Induction Machine" begin

    data = inductionmachinedata()
    # ipopt = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-8, "print_level" => 5, "max_iter" => 4000, "check_derivatives_for_naninf" => "yes", "grad_f_constant"=>"yes", 
                                                # "bound_relax_factor" => 1e-8, "expect_infeasible_problem"=> "yes", "fixed_variable_treatment"=>"relax_bounds")
    
    s = Dict("output" => Dict("branch_flows" => true), "conv_losses_mp" => false)
    result = solve_acdcpf(data, PowerModels.ACPPowerModel, Ipopt.Optimizer; setting = s)

    # Grid active and reactive power from solving the detailed state-space equations of IM
    @test result["termination_status"] == LOCALLY_SOLVED
    @test isapprox(result["solution"]["im"]["1"]["pg"], 0.89442199456220407, atol=1e-7)
    @test isapprox(result["solution"]["im"]["1"]["qg"], 0.8632554248071891, atol=1e-7)

end