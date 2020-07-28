function build_mn_data(file_name)
    mp_data = PowerModels.parse_file(file_name)
    mp_data1 = InfrastructureModels.replicate(mp_data, 2, Set{String}(["source_type", "name", "source_version", "per_unit"]))
    PowerModelsACDC.process_additional_data!(mp_data1)
    return mp_data1
end
