
function get_pu_bases(MVAbase, kVbase)
    Zbase = (kVbase*1000)^2 / (MVAbase*1e6)
    Ibase = (MVAbase*1e6)   / (kVbase*1000)
    dollarbase = 1 #
    hourbase = 1 #
    MWhbase = MVAbase * hourbase
    return Zbase, Ibase
end


function process_additional_data!(data)
    assert(data["baseMVA"]>0)
    MVAbase = data["baseMVA"]

    rescale_energy_cost = x -> (MWhbase/dollarbase)*x

    if data["multinetwork"] == false
        if haskey(data, "convdc")
            for (i, conv) in data["convdc"]
                check_conv_parameters(conv)
                set_conv_pu_power(conv, MVAbase)

                convbus = conv["busdc_i"]
                for (i, bus) in data["busdc"]
                    bus_id = bus["busdc_i"]
                    if bus_id == convbus
                        kVbase = bus["basekVdc"]
                        Zbase, Ibase = get_pu_bases(MVAbase, kVbase)
                        set_conv_pu_volt(conv, kVbase)
                        set_conv_pu_ohm(conv, Zbase)
                    end
                end

            end
        end
        if haskey(data, "branchdc")
            for (i, branchdc) in data["branchdc"]
                check_branchdc_parameters(branchdc)
                set_branchdc_pu(branchdc, MVAbase)
            end
        end
        if !haskey(data, "dcpol")
            data["dcpol"] = 2
        end
        if haskey(data, "dcline")
            if !haskey(data, "convdc")
                data["convdc"] = Dict()
            end
            if !haskey(data, "branchdc")
                data["branchdc"] = Dict()
            end
            if !haskey(data, "busdc")
                data["busdc"] = Dict()
            end
            conv_i = length(data["convdc"])
            branch_i = length(data["branchdc"])
            bus_i = length(data["busdc"])
            for (i, dcline) in data["dcline"]
                # make DC bus from side
                bus_i = bus_i + 1
                data["busdc"]["$bus_i"] = get_busdc(bus_i)

                prev_bus = bus_i - 1
                if haskey(data["busdc"],["$prev_bus"])
                    data["busdc"]["$bus_i"]["basekVdc"] = data["busdc"]["$prev_bus"]["basekVdc"]
                else
                    data["busdc"]["$bus_i"]["basekVdc"] = 100 # arbitrary choice
                end

                # make one DC branch
                branch_i = branch_i + 1
                data["branchdc"]["$branch_i"] = get_branchdc(dcline, branch_i, bus_i)

                # converter 1
                conv_i = conv_i + 1
                pac = dcline["pf"]
                qac = dcline["qf"]
                vmac = dcline["vf"]
                acbus = dcline["f_bus"]
                kVbaseAC = data["bus"]["$fbus"]["base_kv"]
                vmax = data["bus"]["$fbus"]["vmax"]
                vmin = data["bus"]["$fbus"]["vmin"]
                Imax = max(dcline["pmaxf"], dcline["pmaxt"]) / sqrt(3) #assuming 1pu
                status = dcline["br_status"]
                qmaxac = dcline["qmaxf"]
                qminac = dcline["qminf"]
                lossA = 0
                lossB = 0
                pmaxac = 1 #TODO
                pminac = -1 #TODO
                data["convdc"]["$conv_i"] =  get_converter(conv_i, bus_i, acbus, kVbaseAC, vmax, vmin, status, pac, qac, qmaxac, qminac, vac, Imax, lossA, lossB, pmaxac, pminac)

                # DC bus to
                bus_i = bus_i + 1
                data["busdc"]["$bus_i"] = get_busdc(bus_i)
                prev_bus = bus_i - 1
                if haskey(data["busdc"],["$prev_bus"])
                    data["busdc"]["$bus_i"]["basekVdc"] = data["busdc"]["$prev_bus"]["basekVdc"]
                else
                    data["busdc"]["$bus_i"]["basekVdc"] = 100 # arbitrary choice
                end
                # converter 2
                conv_i = conv_i + 1
                acbus = dcline["t_bus"]
                pac = dcline["pt"]
                qac = dcline["qt"]
                vmac = dcline["vt"]
                kVbaseAC = data["bus"]["$tbus"]["base_kv"]
                vmax =  data["bus"]["$tbus"]["vmax"]
                vmin =  data["bus"]["$tbus"]["vmin"]
                Imax =  max(dcline["pmaxf"], dcline["pmaxt"]) / (sqrt(3)) # assuming 1pu
                status = dcline["br_status"]
                lossA = dcline["loss0"]
                lossB = dcline["loss1"]
                pmaxac = max(abs(dcline["pmaxt"]),abs(dcline["pmaxf"]))
                pminac = -min(abs(dcline["pmint"]),abs(dcline["pminf"]))
                qmaxac = dcline["qmaxt"]
                qminac = dcline["qmint"]
                data["convdc"]["$conv_i"] =  get_converter(conv_i, bus_i, acbus, kVbaseAC, vmax, vmin, status, pac, qac, qmaxac, qminac, vmac, Imax, lossA, lossB, pmaxac, pminac)
            end
        end
    else
        for (n, network) in data["nw"]
            if haskey(data["nw"][n], "convdc")
                for (i, conv) in data["nw"][n]["convdc"]
                    check_conv_parameters(conv)
                    set_conv_pu_power(conv, MVAbase)

                    convbus = conv["busdc_i"]
                    for (i, bus) in data["nw"][n]["busdc"]
                        bus_id = bus["busdc_i"]
                        if bus_id == convbus
                            kVbase = bus["basekVdc"]
                            Zbase, Ibase = get_pu_bases(MVAbase, kVbase)
                            set_conv_pu_volt(conv, kVbase)
                            set_conv_pu_ohm(conv, Zbase)
                        end
                    end
                end
            end
            if haskey(data["nw"][n], "branchdc")
                for (i, branchdc) in data["nw"][n]["branchdc"]
                    check_branch_parameters(branchdc)
                    set_branch_pu(branchdc, rescale)
                end
            end
        end
    end
end


function check_branchdc_parameters(branchdc)
    assert(branchdc["rateA"]>=0)
    assert(branchdc["rateB"]>=0)
    assert(branchdc["rateC"]>=0)
end

function set_branchdc_pu(branchdc, MVAbase)
    rescale_power = x -> x/MVAbase
    PowerModels.apply_func(branchdc, "rateA", rescale_power)
    PowerModels.apply_func(branchdc, "rateB", rescale_power)
    PowerModels.apply_func(branchdc, "rateC", rescale_power)
end

function set_conv_pu_power(conv, MVAbase)
    rescale_power = x -> x/MVAbase
    PowerModels.apply_func(conv, "P_g", rescale_power)
    PowerModels.apply_func(conv, "Q_g", rescale_power)
    PowerModels.apply_func(conv, "Pdcset", rescale_power)
    PowerModels.apply_func(conv, "LossA", rescale_power)
    PowerModels.apply_func(conv, "Pacmax", rescale_power)
    PowerModels.apply_func(conv, "Pacmin", rescale_power)
    PowerModels.apply_func(conv, "Qacmax", rescale_power)
    PowerModels.apply_func(conv, "Qacmin", rescale_power)
    PowerModels.apply_func(conv, "Pacrated", rescale_power)
    PowerModels.apply_func(conv, "Qacrated", rescale_power)
end

function set_conv_pu_volt(conv, kVbase)
    rescale_volt = x -> x/kVbase
    PowerModels.apply_func(conv, "LossB", rescale_volt)
end

function set_conv_pu_ohm(conv, Zbase)
    rescale_ohm = x -> x/Zbase
    PowerModels.apply_func(conv, "LossCrec", rescale_ohm)
    PowerModels.apply_func(conv, "LossCinv", rescale_ohm)
end

function check_conv_parameters(conv)
    conv["Pacrated"] = max(abs(conv["Pacmax"]),abs(conv["Pacmin"]))
    conv["Qacrated"] = max(abs(conv["Qacmax"]),abs(conv["Qacmin"]))
    assert(conv["LossA"]>=0)
    assert(conv["LossB"]>=0)
    assert(conv["LossCrec"]>=0)
    assert(conv["LossCinv"]>=0)
    assert(conv["Pacmax"]>=conv["Pacmin"])
    assert(conv["Qacmax"]>=conv["Qacmin"])
    assert(conv["Pacrated"]>=0)
    assert(conv["Qacrated"]>=0)
end


function get_branchdc(matpowerdcline, branch_i, bus_i)
    branchdc = Dict()
    branchdc["index"] = branch_i
    branchdc["fbusdc"] = bus_i
    branchdc["tbusdc"] = bus_i + 1
    branchdc["r"] = 1e-5
    branchdc["l"] = 1e-5
    branchdc["c"] = 0
    branchdc["rateA"] = max(matpowerdcline["pmaxf"], matpowerdcline["pmaxt"])
    branchdc["rateB"] = max(matpowerdcline["pmaxf"], matpowerdcline["pmaxt"])
    branchdc["rateC"] = max(matpowerdcline["pmaxf"], matpowerdcline["pmaxt"])
    branchdc["status"] = matpowerdcline["br_status"]
    return branchdc
end

function get_busdc(bus_i)
    busdc = Dict()
    busdc["index"] = bus_i
    busdc["busdc_i"] = bus_i
    busdc["grid"] = 1
    busdc["Pdc"] = 0
    busdc["Vdc"] = 1
    busdc["Vdcmax"] = 1.1
    busdc["Vdcmin"] = 0.9
    busdc["Cdc"] = 0
    return busdc
end

function get_converter(conv_i, dcbus, acbus, kVbaseAC, vmax, vmin, status, pac, qac, qmaxac, qminac, vmac, Imax, lossA, lossB, pmaxac, pminac)
    conv = Dict()
    conv["index"] = conv_i
    conv["busdc_i"] = dcbus
    conv["busac_i"] = acbus
    conv["type_dc"] = 1
    conv["type_ac"] = 2
    conv["P_g"] = pac
    conv["Q_g"] = qac
    conv["Vtar"] = vmac
    conv["rtf"] = 0
    conv["xtf"] = 0
    conv["transformer"] = 0
    conv["bf"] = 0
    conv["filter"] = 0
    conv["rc"] = 0
    conv["xc"] = 0
    conv["reactor"] = 0
    conv["basekVac"] = kVbaseAC
    conv["Vmmax"] =  vmax
    conv["Vmmin"] =  vmin
    conv["Imax"] =  Imax # assuming 1pu
    conv["status"] = status
    conv["LossA"] = dcline["loss0"]
    conv["LossB"] = dcline["loss1"]
    conv["LossCrec"] = 0
    conv["LossCinv"] = 0
    conv["droop"] = 0
    conv["Pdcset"] = 0
    conv["Vdcset"] = 1
    conv["dVdcSet"] = 0
    conv["Qacmax"] = qmaxac
    conv["Qacmin"] = qminac
    conv["Pacmax"] = pmaxac
    conv["Pacmin"] = pminac
    check_conv_parameters(conv)
    return conv
end
