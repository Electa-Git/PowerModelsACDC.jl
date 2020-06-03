function multinetwork_data(sn_data::Dict{String,Any}, extradata::Dict{String,Any}, global_keys::Set{String})
    count = extradata["dim"]
    if InfrastructureModels.ismultinetwork(sn_data)
        error("replicate can only be used on single networks")
    end

    name = get(sn_data, "name", "anonymous")

    mn_data = Dict{String,Any}(
        "nw" => Dict{String,Any}()
    )

    sn_data_tmp = deepcopy(sn_data)
    for k in global_keys
        if haskey(sn_data_tmp, k)
            mn_data[k] = sn_data_tmp[k]
        end

        # note this is robust to cases where k is not present in sn_data_tmp
        delete!(sn_data_tmp, k)
    end
    mn_data["multinetwork"] = true
    mn_data["name"] = "$(count) replicates of $(name)"

    for k in global_keys
        delete!(sn_data_tmp, k)
    end
    sn_data_tmp["dcpol"] = sn_data["dcpol"]
    sn_data_tmp["dcline"] = sn_data["dcline"]

    for n in 1:count
        mn_data["nw"]["$n"] = copy(sn_data_tmp)
        for (key, element) in extradata
            if key == "dim"
            else
                if haskey(mn_data["nw"]["$n"], key)
                    mn_data["nw"]["$n"][key] = copy(sn_data_tmp[key])
                    for (l, element) in extradata[key]
                        if haskey(mn_data["nw"]["$n"][key], l)
                            mn_data["nw"]["$n"][key][l] = deepcopy(sn_data_tmp[key][l])
                            for (m, property) in extradata[key][l]
                                if haskey(mn_data["nw"]["$n"][key][l], m)
                                    mn_data["nw"]["$n"][key][l][m] = property[n]
                                else
                                    warn(_PM.LOGGER, ["Property ", m ," for , ", key, " " , l, " not found, will be ingnored"])
                                end
                            end
                        else
                            warn(_PM.LOGGER, [key, " " , l,  " not found, will be ingnored"])
                        end
                    end
                else
                    warn(_PM.LOGGER, ["Key ", key, " not found, will be ingnored"])
                end
            end
        end

    end

    return mn_data
end
