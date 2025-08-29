function build_mn_data(file_name)
    mp_data = PowerModels.parse_file(file_name)
    mp_data1 = InfrastructureModels.replicate(mp_data, 2, Set{String}(["source_type", "name", "source_version", "per_unit"]))
    PowerModelsACDC.process_additional_data!(mp_data1; tnep = true)
    return mp_data1
end

function prepare_uc_test_data(file; contingencies = false)
    # Parse file using PowerModels
    data = PowerModels.parse_file(file)
    # Process demand reduction and curtailment data
    for (l, load) in data["load"]
        data["load"][l]["pred_rel_max"] = 0.3
        data["load"][l]["cost_red"] = 100.0 * data["baseMVA"]
        data["load"][l]["cost_curt"] = 10000.0 * data["baseMVA"]
        data["load"][l]["flex"] = 1
    end

    data, frequency_parameters = add_fcuc_data!(data)
    _PMACDC.prepare_uc_data!(data; uc = true, frequency_parameters = frequency_parameters)

    number_of_hours = 24

    g_series = [0.4  0.5  0.66  0.7   0.7   0.9   0.95 1.02  1.15  1.3   1.35 1.3   1.21  1.08  1.0  0.96  0.93 1.0  1.1   1.2  1.08  1.05  0.99 0.89]
    l_series = [0.6  0.7  0.75  0.78  0.85  0.88  0.9  1.0   1.12  1.25  1.2  1.08  0.99  0.92  0.8  0.73  0.8  0.9  1.03  1.2  1.11  0.99  0.8  0.69]

    mn_data = _PMACDC.create_multinetwork_uc_model!(data, number_of_hours, g_series, l_series, contingencies = contingencies)

    return mn_data
end


function add_fcuc_data!(data)
    frequency_parameters = Dict{String, Any}()
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
            storage["ramp_rate_per_s"] =   storage["ramp_rate"] / 3600  
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

    # indeicate which generators are renewable
    for (g, gen) in data["gen"]
    if g == "2" || g == "8"
            data["gen"][g]["res"] = true
    else
            data["gen"][g]["res"] = false
    end
    end     

    # create a matrix with time points where storage should have a fixed content (column 1), and the fixed energy content in p.u. (column 2)
    for (s, strg) in data["storage"]
        data["storage"][s]["fixed_energy"] = [25 0.5
                                            49 0.4
                                            73 0.3
                                            97 0.6]
    end

    # We are going to consider 3 typical days which will make up in total five days. The sequence is [day1 day2 day1 day3 day1]
    number_of_hours = 120

    # this is an arbutary generation and demand series, later replace with something more representative
    g_series = [0.4  0.5  0.66  0.7   0.7   0.9   0.95 1.02  1.15  1.3   1.35 1.3   1.21  1.08  1.0  0.96  0.93 1.0  1.1   1.2  1.08  1.05  0.99 0.89]
    l_series = [0.6  0.7  0.75  0.78  0.85  0.88  0.9  1.0   1.12  1.25  1.2  1.08  0.99  0.92  0.8  0.73  0.8  0.9  1.03  1.2  1.11  0.99  0.8  0.69]

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
    mn_data = _PMACDC.create_multinetwork_uc_model!(data, number_of_hours, timeseries_g, timeseries_l)

    return mn_data
end

