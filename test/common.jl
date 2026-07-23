function inductionmachine_data()
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
    ((data["gen"])[key])["vg"] = 1.0 # Accessor function to treat multiple field names for AC Voltage

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

    machine = (;T_0 = 0.9, l_rl=0.165, l_m=1.66,l_sl=0.15,r_r=0.01,r_s=0.01,A=0.95,B=0.05,C=0,m=2) # Power flow initial values
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

function build_mn_data(file_name)
    mp_data = parse_file(file_name; tnep=true)
    mp_data1 = PowerModels.replicate(mp_data, 2; global_keys=Set{String}(["source_type", "name", "source_version", "per_unit"]))
    return mp_data1
end

function prepare_uc_test_data(file; contingencies=nothing, tielines=nothing, number_of_hours=24)
    # Parse file using PowerModels
    data = PowerModels.parse_file(file)
    # Process demand reduction and curtailment data
    for (l, load) in data["load"]
        data["load"][l]["pred_rel_max"] = 0.3
        data["load"][l]["cost_red"] = 100.0 * data["baseMVA"]
        data["load"][l]["cost_curt"] = 10000.0 * data["baseMVA"]
        data["load"][l]["flex"] = 1
    end

    if !isnothing(tielines)
        data["tie_lines"] = tielines
    end

    data, frequency_parameters = add_fcuc_data!(data)
    prepare_uc_data!(data; uc=true, frequency_parameters=frequency_parameters)

    g_series = [0.4 0.5 0.66 0.7 0.7 0.9 0.95 1.02 1.15 1.3 1.35 1.3 1.21 1.08 1.0 0.96 0.93 1.0 1.1 1.2 1.08 1.05 0.99 0.89]
    l_series = [0.6 0.7 0.75 0.78 0.85 0.88 0.9 1.0 1.12 1.25 1.2 1.08 0.99 0.92 0.8 0.73 0.8 0.9 1.03 1.2 1.11 0.99 0.8 0.69]

    mn_data = create_multinetwork_uc_model!(data, number_of_hours, g_series, l_series, contingencies=contingencies)

    return mn_data
end


function add_fcuc_data!(data)
    frequency_parameters = Dict{String,Any}()
    frequency_parameters["fmin"] = 49.0
    frequency_parameters["fmax"] = 51.0
    frequency_parameters["f0"] = 50.0
    frequency_parameters["fdb"] = 0.1
    frequency_parameters["t_fcr"] = 1.0
    frequency_parameters["t_fcrd"] = 6.0
    frequency_parameters["delta_fss"] = 0.1
    frequency_parameters["t_hvdc"] = 0.3
    frequency_parameters["ffr_cost"] = 50.0
    frequency_parameters["fcr_cost"] = 20.0

    for (g, gen) in data["gen"]
        gen["ramp_rate"] = 1.0
        gen["ramp_rate_per_s"] = gen["pmax"] / 3600
        gen["fcr_contribution"] = true
        gen["mdt"] = 2
        gen["mut"] = 2
    end

    for (s, storage) in data["storage"]
        bus_id = storage["storage_bus"]
        if storage["status"] == 1
            storage["zone"] = data["bus"]["$bus_id"]["zone"]
            storage["area"] = data["bus"]["$bus_id"]["area"]
            storage["inertia_constants"] = 4.0
            storage["start_up_cost"] = 1000.0
            storage["ramp_rate"] = 1.0
            storage["ramp_rate_per_s"] = storage["ramp_rate"] / 3600
            storage["fcr_contribution"] = true
            storage["mdt"] = 1.0
            storage["mut"] = 1.0
        else
            delete!(data["storage"], s)
        end
    end

    return data, frequency_parameters
end

function prepare_storage_opf_data(file)
    # Parse file using PowerModels
    data = PowerModels.parse_file(file)
    # Process demand reduction and curtailment data
    for (l, load) in data["load"]
        data["load"][l]["pred_rel_max"] = 0.3
        data["load"][l]["cost_red"] = 100.0 * data["baseMVA"]
        data["load"][l]["cost_curt"] = 10000.0 * data["baseMVA"]
        data["load"][l]["flex"] = 1
    end

    # indicate which generators are renewable
    for (g, gen) in data["gen"]
        if g == "2" || g == "8"
            data["gen"][g]["res"] = true
        else
            data["gen"][g]["res"] = false
        end
    end

    # create a matrix with time points where storage should have a fixed content (column 1), and the fixed energy content in p.u. (column 2)
    for (s, strg) in data["storage"]
        data["storage"][s]["fixed_energy"] = [
            25 0.5
            49 0.4
            73 0.3
            97 0.6
        ]
    end

    # We are going to consider 3 typical days which will make up in total five days. The sequence is [day1 day2 day1 day3 day1]
    number_of_hours = 120

    # This is an arbitrary generation and demand series, later replace with something more representative
    g_series = [0.4 0.5 0.66 0.7 0.7 0.9 0.95 1.02 1.15 1.3 1.35 1.3 1.21 1.08 1.0 0.96 0.93 1.0 1.1 1.2 1.08 1.05 0.99 0.89]
    l_series = [0.6 0.7 0.75 0.78 0.85 0.88 0.9 1.0 1.12 1.25 1.2 1.08 0.99 0.92 0.8 0.73 0.8 0.9 1.03 1.2 1.11 0.99 0.8 0.69]

    # just define demand and generation time series for each representative day
    day1g = g_series
    day1l = l_series
    day2g = 0.5 * day1g
    day2l = 1.2 * day1l
    day3g = 0.7 * day1g
    day3l = 1.5 * day1l

    # put all days to
    timeseries_g = hcat(day1g, day2g, day1g, day3g, day1g)
    timeseries_l = hcat(day1l, day2l, day1l, day3l, day1l)

    # create multinetwork data structure
    mn_data = create_multinetwork_uc_model!(data, number_of_hours, timeseries_g, timeseries_l)

    return mn_data
end
