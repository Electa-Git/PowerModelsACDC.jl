function build_mn_data(file_name)
    mp_data = PowerModels.parse_file(file_name)
    mp_data1 = InfrastructureModels.replicate(mp_data, 2, Set{String}(["source_type", "name", "source_version", "per_unit"]))
    PowerModelsACDC.process_additional_data!(mp_data1; tnep = true)
    return mp_data1
end

function prepare_uc_test_data(file)
    # Parse file using PowerModels
    data = PowerModels.parse_file(file)
    # Process demand reduction and curtailment data
    for (l, load) in data["load"]
        data["load"][l]["pred_rel_max"] = 0.3
        data["load"][l]["cost_red"] = 100.0 * data["baseMVA"]
        data["load"][l]["cost_curt"] = 10000.0 * data["baseMVA"]
        data["load"][l]["flex"] = 1
    end
    # Process inertia data
    _PMACDC.prepare_uc_data!(data; uc = true)

    number_of_hours = 24

    g_series = [0.4  0.5  0.66  0.7   0.7   0.9   0.95 1.02  1.15  1.3   1.35 1.3   1.21  1.08  1.0  0.96  0.93 1.0  1.1   1.2  1.08  1.05  0.99 0.89]
    l_series = [0.6  0.7  0.75  0.78  0.85  0.88  0.9  1.0   1.12  1.25  1.2  1.08  0.99  0.92  0.8  0.73  0.8  0.9  1.03  1.2  1.11  0.99  0.8  0.69]
    data["frequency_parameters"] = Dict{String, Any}("uc_time_interval" => 1) # hours

    mn_data = _PMACDC.create_multinetwork_uc_model!(data, number_of_hours, g_series, l_series)

    return mn_data
end