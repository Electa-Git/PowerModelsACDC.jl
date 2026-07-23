function inductionmachine_data()
    global_dict = PowerModelsACDC._get_pu_bases(1000, 220) # 3-PH MVA, LL-RMS, Original setting was 100,320
    global_dict["omega"] = 2π * 50

    data = Dict{String,Any}(
        "per_unit" => true,
        "baseMVA" => global_dict["S"]/1e6,
        "bus" => Dict{String,Any}(),
        "im" => Dict{String,Any}(),
        "shunt" => Dict{String,Any}(),
        "dcline" => Dict{String,Any}(),
        "storage" => Dict{String,Any}(),
        "switch" => Dict{String,Any}(),
        "load" => Dict{String,Any}(),
        "branch" => Dict{String,Any}(),
        "gen" => Dict{String,Any}(),
        "im" => Dict{String,Any}(),
        "sssc" => Dict{String,Any}(), # Avoids warning
        "im" => Dict{String,Any}(),
        "pst" => Dict{String,Any}(), # Avoids warning
        "gendc" => Dict{String,Any}() # Avoids warning
    )

    # Add one bus
    bus_id = 1
    data["bus"]["$bus_id"] = Dict{String,Any}(
        "source_id" => Any["bus", bus_id],
        "index" => bus_id,
        "bus_i" => bus_id,
        "zone" => 1,
        "area" => 1,
        "vmin" => 0.9,
        "vmax" => 1.1,
        "vm" => 1,
        "va" => 0,
        "base_kv" => global_dict["V"] / 1e3,
        "bus_type" => 3 # bus type - depends on components 1 is default PQ
    )

    # Add ideal voltage source
    gen_id = 1
    data["gen"]["$gen_id"] = Dict{String,Any}(
        "mBase" => global_dict["S"] / 1e6,
        "gen_bus" => 1,
        "pc1" => 0,
        "pc2" => 0,
        "qc1min" => 0,
        "qc1max" => 0,
        "qc2min" => 0,
        "qc2max" => 0,
        "ramp_agc" => 0,
        "ramp_q" => 0,
        "ramp_10" => 0,
        "ramp_30" => 0,
        "apf" => 0,
        "startup" => 0,
        "shutdown" => 0,
        "gen_status" => 1,
        "source_id" => Any["gen", gen_id],
        "index" => gen_id,
        "pg" => 0.0,
        "qg" => 0.0,
        "pmin" => 0.0,
        "pmax" => 0.0,
        "qmin" => 0.0,
        "qmax" => 0.0,
        "vg" => 1.0,
        "model" => 1,
        "cost" => 0,
        "ncost" => 0
    )

    # Add induction machine data
    ac_bus = 1
    impscale = 1.0 #((machine.Vᵃᶜ_base)^2/machine.S_base)/global_dict["Z_base"]
    machine = (; T_0=0.9, l_rl=0.165, l_m=1.66, l_sl=0.15, r_r=0.01, r_s=0.01, A=0.95, B=0.05, C=0, m=2) # Power flow initial values
    im_id = 1
    data["im"]["$im_id"] = Dict{String,Any}(
        "P_ag" => machine.T_0/global_dict["S"],
        "Q_ag" => 0.0,
        "status" => 1,
        "im_bus" => ac_bus,

        # Power flow limits (not used in power flow)
        "Pacmin" => 0.9 * machine.T_0/global_dict["S"],
        "Vmmin" => 0.9, # Should be extended with local_base/global_base but we do not care (not used in PF)
        "Vmmax" => 1.1,
        "Pacmax" => 1.1 * machine.T_0 / global_dict["S"],
        "Pacrated" => machine.T_0 / global_dict["S"],

        # Power flow elements
        "x_m" => machine.l_m * impscale, # In per unit equal
        "x_rl" => machine.l_rl * impscale,
        "x_sl" => machine.l_sl * impscale,
        "r_r" => machine.r_r * impscale,
        "r_s" => machine.r_s * impscale,

        # Torque parameters
        "torque" => Dict{String,Any}(
            "T_0" => machine.T_0,
            "A" => machine.A,
            "B" => machine.B,
            "C" => machine.C,
            "m" => machine.m,
        ),
    )

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
