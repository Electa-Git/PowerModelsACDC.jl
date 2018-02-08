function process_additional_data!(data)
    mva_basedc = data["baseMVA"]
    rescale = x -> x/mva_basedc
    rescale_cost = x -> mva_basedc * x
    if data["multinetwork"] == false
        if haskey(data, "convdc")
            for (i, conv) in data["convdc"]
                PowerModels.apply_func(conv, "P_g", rescale)
                PowerModels.apply_func(conv, "Pdcset", rescale)
                PowerModels.apply_func(conv, "Q_g", rescale)
                PowerModels.apply_func(conv, "LossA", rescale)
                convbus = conv["busdc_i"]
                for (i, bus) in data["busdc"]
                    bus_id = bus["busdc_i"]
                    if bus_id == convbus
                        basekV = bus["basekVdc"]
                        rescale_volt = x -> x/basekV
                        PowerModels.apply_func(conv, "LossB", rescale_volt)
                        Zbase = (basekV*1000)^2 / (mva_basedc*1e6)
                        rescale_ohm = x -> x/Zbase
                        PowerModels.apply_func(conv, "LossCrec", rescale_ohm)
                        PowerModels.apply_func(conv, "LossCinv", rescale_ohm)
                    end
                end

            end
        end
        if haskey(data, "branchdc")
            for (i, branch) in data["branchdc"]
                PowerModels.apply_func(branch, "rateA", rescale)
                PowerModels.apply_func(branch, "rateB", rescale)
                PowerModels.apply_func(branch, "rateC", rescale)
            end
        end
    else
        for (n, network) in data["nw"]
            if haskey(data["nw"][n], "convdc")
                for (i, conv) in data["nw"][n]["convdc"]
                    PowerModels.apply_func(conv, "P_g", rescale)
                    PowerModels.apply_func(conv, "Pdcset", rescale)
                    PowerModels.apply_func(conv, "Q_g", rescale)
                    PowerModels.apply_func(conv, "LossA", rescale)
                    convbus = conv["busdc_i"]
                    for (i, bus) in data["nw"][n]["busdc"]
                        bus_id = bus["busdc_i"]
                        if bus_id == convbus
                            basekV = bus["basekVdc"]
                            rescale_volt = x -> x/basekV
                            PowerModels.apply_func(conv, "LossB", rescale_volt)
                            Zbase = (basekV*1000)^2 / (mva_basedc*1e6)
                            rescale_ohm = x -> x/Zbase
                            PowerModels.apply_func(conv, "LossCrec", rescale_ohm)
                            PowerModels.apply_func(conv, "LossCinv", rescale_ohm)
                        end
                    end
                end
            end
            if haskey(data["nw"][n], "branchdc")
                for (i, branch) in data["nw"][n]["branchdc"]
                    PowerModels.apply_func(branch, "rateA", rescale)
                    PowerModels.apply_func(branch, "rateB", rescale)
                    PowerModels.apply_func(branch, "rateC", rescale)
                end
            end
        end
    end
end
