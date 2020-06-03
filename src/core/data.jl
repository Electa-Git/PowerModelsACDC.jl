
function get_pu_bases(MVAbase, kVbase)
    eurobase = 1 #
    hourbase = 1 #

    Sbase = MVAbase * 1e6
    Vbase = kVbase  * 1e3
    #Zbase = (Vbase)^2 / (Sbase) # TODO
    kAbase = MVAbase / (sqrt(3) * kVbase)
    Zbase = 1/(kAbase^2 / MVAbase)
    Ibase = (Sbase)   / (Vbase)
    timebase = hourbase*3600
    Ebase = Sbase * timebase

    bases = Dict{String, Any}(
    "Z" => Zbase,         # Impedance (Ω)
    "I" => Ibase,         # Current (A)
    "€" => eurobase,      # Currency (€)
    "t" => timebase,      # Time (s)
    "S" => Sbase,         # Power (W)
    "V" => Vbase,         # Voltage (V)
    "E" => Ebase          # Energy (J)
    )
    return bases
end

function process_additional_data!(data)
    to_pu!(data)
    fix_data!(data)
    convert_matpowerdcline_to_branchdc!(data)
end

function is_single_network(data)
    return !haskey(data, "multinetwork") || data["multinetwork"] == false
end

function to_pu!(data)
    if is_single_network(data)
        to_pu_single_network!(data)
    else
        to_pu_multinetwork!(data)
    end
end

function to_pu_single_network!(data)
    MVAbase = data["baseMVA"]
    if haskey(data, "convdc")
        for (i, conv) in data["convdc"]
            dcbus = conv["busdc_i"]
            kVbase = conv["basekVac"]
            Zbase = get_pu_bases(MVAbase, kVbase)["Z"]
            Ibase = get_pu_bases(MVAbase, kVbase)["I"]

            set_conv_pu_power(conv, MVAbase)
            set_conv_pu_volt(conv, kVbase*sqrt(3))
            set_conv_pu_ohm(conv, Zbase)
        end
    end
    if haskey(data, "branchdc")
        for (i, branchdc) in data["branchdc"]
            set_branchdc_pu(branchdc, MVAbase)
        end
    end
    if haskey(data, "busdc")
        for (i, busdc) in data["busdc"]
            set_busdc_pu(busdc, MVAbase)
        end
    end
    if haskey(data, "convdc_ne")
        for (i, conv) in data["convdc_ne"]
            dcbus = conv["busdc_i"]
            kVbase = conv["basekVac"]
            Zbase = get_pu_bases(MVAbase, kVbase)["Z"]
            Ibase = get_pu_bases(MVAbase, kVbase)["I"]

            set_conv_pu_power(conv, MVAbase)
            set_conv_pu_volt(conv, kVbase*sqrt(3))
            set_conv_pu_ohm(conv, Zbase)
        end
    end
    if haskey(data, "branchdc_ne")
        for (i, branchdc) in data["branchdc_ne"]
            set_branchdc_pu(branchdc, MVAbase)
        end
    end
    if haskey(data, "busdc_ne")
        new_busdc_ne = Dict{String, Any}()
        for (i, busdc) in data["busdc_ne"]
            set_busdc_pu(busdc, MVAbase)
            new_bus = busdc["busdc_i"] # assigning new bus numbers: continous numbers from dc bus numbers
            if new_bus == i
                display("candidate dc buses and existing dc buses should have different bus numbers")
            end
            new_busdc_ne[string(new_bus)] = busdc # assigning new bus numbers: continous numbers from dc bus numbers
            busdc["index"] = new_bus
        end
        data["busdc_ne"] = new_busdc_ne # assigning new bus numbers: continous numbers from dc bus numbers
    end
end

function to_pu_multinetwork!(data)
    for (n, network) in data["nw"]
        MVAbase = network["baseMVA"]
        if haskey(data["nw"][n], "convdc")
            for (i, conv) in data["nw"][n]["convdc"]
                dcbus = conv["busdc_i"]
                kVbase = conv["basekVac"]
                Zbase = get_pu_bases(MVAbase, kVbase)["Z"]
                Ibase = get_pu_bases(MVAbase, kVbase)["I"]

                set_conv_pu_power(conv, MVAbase)
                set_conv_pu_volt(conv, kVbase*sqrt(3))
                set_conv_pu_ohm(conv, Zbase)
            end
        end
        if haskey(data["nw"][n], "branchdc")
            for (i, branchdc) in data["nw"][n]["branchdc"]
                set_branchdc_pu(branchdc, MVAbase)
            end
        end
        if haskey(data["nw"][n], "busdc")
            for (i, busdc) in data["nw"][n]["busdc"]
                set_busdc_pu(busdc, MVAbase)
            end
        end
        if haskey(data["nw"][n], "convdc_ne")
            for (i, conv) in data["nw"][n]["convdc_ne"]
                dcbus = conv["busdc_i"]
                kVbase = conv["basekVac"]
                Zbase = get_pu_bases(MVAbase, kVbase)["Z"]
                Ibase = get_pu_bases(MVAbase, kVbase)["I"]

                set_conv_pu_power(conv, MVAbase)
                set_conv_pu_volt(conv, kVbase*sqrt(3))
                set_conv_pu_ohm(conv, Zbase)
                conv["cost"] = conv["cost"]/length(data["nw"])
            end
        end
        if haskey(data["nw"][n], "branchdc_ne")
            for (i, branchdc) in data["nw"][n]["branchdc_ne"]
                set_branchdc_pu(branchdc, MVAbase)
                branchdc["cost"] = branchdc["cost"]/length(data["nw"])
            end
        end
        if haskey(data["nw"][n], "busdc_ne")
            new_busdc_ne = Dict{String, Any}()
            for (i, busdc) in data["nw"][n]["busdc_ne"]
                set_busdc_pu(busdc, MVAbase)
                new_bus = busdc["busdc_i"] # assigning new bus numbers: continous numbers from exisiting dc bus numbers
                if new_bus == i
                    display("candidate dc buses and existing dc buses should have different bus numbers")
                end
                new_busdc_ne[string(new_bus)] = busdc # assigning new bus numbers: continous numbers from dc bus numbers
                busdc["index"] = new_bus
            end
            data["nw"][string(n)]["busdc_ne"] = new_busdc_ne # assigning new bus numbers: continous numbers from exisiting dc bus numbers
        end
    end
end

function convert_matpowerdcline_to_branchdc!(data)
    if is_single_network(data)
        convert_matpowerdcline_to_branchdc_single_network!(data)
    else
        convert_matpowerdcline_to_branchdc_multinetwork!(data)
    end
end

function convert_matpowerdcline_to_branchdc_single_network!(data)
    MVAbase = data["baseMVA"]
    if haskey(data, "dcline") && haskey(data["dcline"], "1")
        if !haskey(data, "convdc")
            data["convdc"] = Dict{String, Any}()
        end
        if !haskey(data, "branchdc")
            data["branchdc"] = Dict{String, Any}()
        end
        if !haskey(data, "busdc")
            data["busdc"] = Dict{String, Any}()
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

            # DC bus to
            bus_i = bus_i + 1
            data["busdc"]["$bus_i"] = get_busdc(bus_i)
            prev_bus = bus_i - 1
            if haskey(data["busdc"],["$prev_bus"])
                data["busdc"]["$bus_i"]["basekVdc"] = data["busdc"]["$prev_bus"]["basekVdc"]
            else
                data["busdc"]["$bus_i"]["basekVdc"] = 100 # arbitrary choice
            end

            branch_i = branch_i + 1
            conv_i = conv_i + 1
            converter1, converter2, branchdc = convert_to_dcbranch_and_converters(data, dcline, branch_i, conv_i, bus_i-1, bus_i)
            data["branchdc"]["$branch_i"] = branchdc
            data["convdc"]["$conv_i"] = converter1
            conv_i = conv_i + 1
            data["convdc"]["$conv_i"] = converter2
        end
    end
    data["dcline"] = []
end

function convert_matpowerdcline_to_branchdc_multinetwork!(data)
    for (n, network) in data["nw"]
        MVAbase = network["baseMVA"]
        if haskey(data["nw"][n], "dcline") && haskey(data["nw"][n]["dcline"], "1")
            if !haskey(data["nw"][n], "convdc")
                data["nw"][n]["convdc"] = Dict{String, Any}()
            end
            if !haskey(data["nw"][n], "branchdc")
                data["nw"][n]["branchdc"] = Dict{String, Any}()
            end
            if !haskey(data["nw"][n], "busdc")
                data["nw"][n]["busdc"] = Dict{String, Any}()
            end
            conv_i = length(data["nw"][n]["convdc"])
            branch_i = length(data["nw"][n]["branchdc"])
            bus_i = length(data["nw"][n]["busdc"])

            for (i, dcline) in data["nw"][n]["dcline"]
                # make DC bus from side
                bus_i = bus_i + 1
                data["nw"][n]["busdc"]["$bus_i"] = get_busdc(bus_i)

                prev_bus = bus_i - 1
                if haskey(data["nw"][n]["busdc"],["$prev_bus"])
                    data["nw"][n]["busdc"]["$bus_i"]["basekVdc"] = data["nw"][n]["busdc"]["$prev_bus"]["basekVdc"]
                else
                    data["nw"][n]["busdc"]["$bus_i"]["basekVdc"] = 100 # arbitrary choice
                end

                # DC bus to
                bus_i = bus_i + 1
                data["nw"][n]["busdc"]["$bus_i"] = get_busdc(bus_i)
                prev_bus = bus_i - 1
                if haskey(data["nw"][n]["busdc"],["$prev_bus"])
                    data["nw"][n]["busdc"]["$bus_i"]["basekVdc"] = data["nw"][n]["busdc"]["$prev_bus"]["basekVdc"]
                else
                    data["nw"][n]["busdc"]["$bus_i"]["basekVdc"] = 100 # arbitrary choice
                end

                branch_i = branch_i + 1
                conv_i = conv_i + 1
                converter1, converter2, branchdc = convert_to_dcbranch_and_converters(data["nw"][n], dcline, branch_i, conv_i, bus_i-1, bus_i)
                data["nw"][n]["branchdc"]["$branch_i"] = branchdc
                data["nw"][n]["convdc"]["$conv_i"] = converter1
                conv_i = conv_i + 1
                data["nw"][n]["convdc"]["$conv_i"] = converter2
            end
        end
        data["nw"][n]["dcline"] = []
    end
end


function fix_data!(data)


    rescale_energy_cost = x -> (MWhbase/dollarbase)*x

    if is_single_network(data)
        fix_data_single_network!(data)
    else
        fix_data_multinetwork!(data)
    end
end

function fix_data_single_network!(data)
    MVAbase = data["baseMVA"]
    @assert(MVAbase>0)
    if haskey(data, "convdc")
        for (i, conv) in data["convdc"]
            check_conv_parameters(conv)
        end
    end
    if haskey(data, "branchdc")
        for (i, branchdc) in data["branchdc"]
            check_branchdc_parameters(branchdc)
        end
    end
    if haskey(data, "busdc")
        new_busdc = Dict{String, Any}()
        for (i, busdc) in data["busdc"]
            new_bus = busdc["busdc_i"] # assigning new bus numbers: continous numbers from dc bus numbers
            new_busdc[string(new_bus)] = busdc # assigning new bus numbers: continous numbers from dc bus numbers
        end
        data["busdc"] = new_busdc # assigning new bus numbers: continous numbers from dc bus numbers
    end
    if !haskey(data, "dcpol")
        data["dcpol"] = 2
    end
    if haskey(data, "convdc_ne")
        for (i, conv) in data["convdc_ne"]
            check_conv_parameters(conv)
        end
    end
    if haskey(data, "branchdc_ne")
        for (i, branchdc) in data["branchdc_ne"]
            check_branchdc_parameters(branchdc)
        end
    end
end

function fix_data_multinetwork!(data)
    for (n, network) in data["nw"]
        MVAbase = network["baseMVA"]
        @assert(MVAbase>0)
        if haskey(data["nw"][n], "convdc")
            for (i, conv) in data["nw"][n]["convdc"]
                check_conv_parameters(conv)
            end
        end
        if haskey(data["nw"][n], "branchdc")
            for (i, branchdc) in data["nw"][n]["branchdc"]
                check_branchdc_parameters(branchdc)
            end
        end
        if haskey(data["nw"][n], "busdc")
            new_busdc = Dict{String, Any}()
            for (i, busdc) in data["nw"][n]["busdc"]
                new_bus = busdc["busdc_i"] # assigning new bus numbers: continous numbers from dc bus numbers
                new_busdc[string(new_bus)] = busdc # assigning new bus numbers: continous numbers from dc bus numbers
            end
            data["nw"][n]["busdc"] = new_busdc # assigning new bus numbers: continous numbers from dc bus numbers
        end
        if !haskey(data["nw"][n], "dcpol")
            data["nw"][n]["dcpol"] = 2
        end
        if haskey(data["nw"][n], "convdc_ne")
            for (i, conv) in data["nw"][n]["convdc_ne"]
                check_conv_parameters(conv)
            end
        end
        if haskey(data["nw"][n], "branchdc_ne")
            for (i, branchdc) in data["nw"][n]["branchdc_ne"]
                check_branchdc_parameters(branchdc)
            end
        end
    end
end

function check_branchdc_parameters(branchdc)
    @assert(branchdc["rateA"]>=0)
    @assert(branchdc["rateB"]>=0)
    @assert(branchdc["rateC"]>=0)
end

function set_branchdc_pu(branchdc, MVAbase)
    rescale_power = x -> x/MVAbase
    _PM._apply_func!(branchdc, "rateA", rescale_power)
    _PM._apply_func!(branchdc, "rateB", rescale_power)
    _PM._apply_func!(branchdc, "rateC", rescale_power)
end

function set_busdc_pu(busdc, MVAbase)
    rescale_power = x -> x/MVAbase
    _PM._apply_func!(busdc, "Pdc", rescale_power)
end

function set_conv_pu_power(conv, MVAbase)
    rescale_power = x -> x/MVAbase
    _PM._apply_func!(conv, "P_g", rescale_power)
    _PM._apply_func!(conv, "Q_g", rescale_power)
    _PM._apply_func!(conv, "Pdcset", rescale_power)
    _PM._apply_func!(conv, "LossA", rescale_power)
    _PM._apply_func!(conv, "Pacmax", rescale_power)
    _PM._apply_func!(conv, "Pacmin", rescale_power)
    _PM._apply_func!(conv, "Qacmax", rescale_power)
    _PM._apply_func!(conv, "Qacmin", rescale_power)
    _PM._apply_func!(conv, "Pacrated", rescale_power)
    _PM._apply_func!(conv, "Qacrated", rescale_power)
end

function set_conv_pu_volt(conv, kVbase)
    rescale_volt = x -> x  / (kVbase)
    _PM._apply_func!(conv, "LossB", rescale_volt)
end

function set_conv_pu_ohm(conv, Zbase)
    rescale_ohm = x -> x / Zbase
    _PM._apply_func!(conv, "LossCrec", rescale_ohm)
    _PM._apply_func!(conv, "LossCinv", rescale_ohm)
end

function check_conv_parameters(conv)
    @assert(conv["LossA"]>=0)
    @assert(conv["LossB"]>=0)
    @assert(conv["LossCrec"]>=0)
    @assert(conv["LossCinv"]>=0)
    conv_id = conv["index"]
    conv["Pacrated"] = max(abs(conv["Pacmax"]),abs(conv["Pacmin"]))
    conv["Qacrated"] = max(abs(conv["Qacmax"]),abs(conv["Qacmin"]))
    if conv["Imax"] < sqrt(conv["Pacrated"]^2 + conv["Qacrated"]^2)
        Memento.warn(_PM._LOGGER, "Inconsistent current limit for converter $conv_id, it will be updated.")
        conv["Imax"] = sqrt(conv["Pacrated"]^2 + conv["Qacrated"]^2)
    end
    if conv["LossCrec"] != conv["LossCinv"]
        Memento.warn(_PM._LOGGER, "The losses of converter $conv_id are different in inverter and rectifier mode, inverter losses are used.")
    end
    if conv["islcc"] == 1
        Memento.warn(_PM._LOGGER, "Converter $conv_id is an LCC, reactive power limits might be updated.")
        if abs(conv["Pacmax"]) >= abs(conv["Pacmin"])
            conv["phimin"] = 0
            conv["phimax"] = acos(conv["Pacmin"] / conv["Pacmax"])
        else
            conv["phimin"] = pi - acos(conv["Pacmax"] / conv["Pacmin"])
            conv["phimax"] = pi
        end
        conv["Qacmax"] = conv["Pacrated"]
        conv["Qacrated"] = conv["Pacrated"]
        conv["Qacmin"] =  0
    end
    @assert(conv["Pacmax"]>=conv["Pacmin"])
    @assert(conv["Qacmax"]>=conv["Qacmin"])
    @assert(conv["Pacrated"]>=0)
    @assert(conv["Qacrated"]>=0)
end


function get_branchdc(matpowerdcline, branch_i, fbusdc, tbusdc)
    branchdc = Dict{String, Any}()
    branchdc["index"] = branch_i
    branchdc["fbusdc"] = fbusdc
    branchdc["tbusdc"] = tbusdc
    branchdc["r"] = 0
    branchdc["l"] = 0
    branchdc["c"] = 0
    branchdc["rateA"] = max(matpowerdcline["pmaxf"], matpowerdcline["pmaxt"])
    branchdc["rateB"] = max(matpowerdcline["pmaxf"], matpowerdcline["pmaxt"])
    branchdc["rateC"] = max(matpowerdcline["pmaxf"], matpowerdcline["pmaxt"])
    branchdc["status"] = matpowerdcline["br_status"]
    return branchdc
end

function get_busdc(bus_i)
    busdc = Dict{String, Any}()
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
    conv = Dict{String, Any}()
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
    conv["LossA"] = lossA
    conv["LossB"] = lossB
    conv["LossCrec"] = 0
    conv["LossCinv"] = 0
    conv["droop"] = 0
    conv["islcc"] = 0
    conv["Pdcset"] = 0
    conv["Vdcset"] = 1
    conv["tm"] = 1
    conv["dVdcSet"] = 0
    conv["Qacmax"] = qmaxac
    conv["Qacmin"] = qminac
    conv["Pacmax"] = pmaxac
    conv["Pacmin"] = pminac
    check_conv_parameters(conv)
    return conv
end


function convert_to_dcbranch_and_converters(data, dcline, branchdc_id, conv_i, fbusdc, tbusdc)
    # make one more DC branch
    branchdc = get_branchdc(dcline, branchdc_id, fbusdc, tbusdc)
    vmaxf = data["bus"]["$fbusdc"]["vmax"]
    vminf = data["bus"]["$fbusdc"]["vmin"]
    vmaxt =  data["bus"]["$tbusdc"]["vmax"]
    vmint =  data["bus"]["$tbusdc"]["vmin"]

    pac = dcline["pf"]
    qac = dcline["qf"]
    vmac = dcline["vf"]
    acbus = dcline["f_bus"]
    kVbaseAC = data["bus"]["$fbusdc"]["base_kv"]
    Imax =  sqrt(dcline["pmaxf"]^2 + dcline["qmaxf"]^2) / vminf
    status = dcline["br_status"]
    qmaxac = dcline["qmaxf"]
    qminac = dcline["qminf"]
    lossA = dcline["loss0"] /2
    lossB = dcline["loss1"]
    vac = 1
    pmaxac = dcline["pmaxf"]
    pminac = dcline["pminf"]
    converter1 =  get_converter(conv_i, fbusdc, acbus, kVbaseAC, vmaxf, vminf, status, pac, qac, qmaxac, qminac, vac, Imax, lossA, lossB, pmaxac, pminac)


    # converter 2
    conv_i = conv_i + 1
    acbus = dcline["t_bus"]
    pac = dcline["pt"]
    qac = dcline["qt"]
    vmac = dcline["vt"]
    kVbaseAC = data["bus"]["$tbusdc"]["base_kv"]
    Imax =  sqrt(dcline["pmaxt"]^2 + dcline["qmaxt"]^2) / vmint# assuming 1pu
    status = dcline["br_status"]
    lossA = dcline["loss0"] / 2
    lossB = 0
    pmaxac =  dcline["pmaxt"]
    pminac =  dcline["pmint"]
    qmaxac = dcline["qmaxt"]
    qminac = dcline["qmint"]
    converter2 =  get_converter(conv_i, tbusdc, acbus, kVbaseAC, vmaxt, vmint, status, pac, qac, qmaxac, qminac, vac, Imax, lossA, lossB, pmaxac, pminac)

    return converter1, converter2, branchdc
end

function converter_bounds(pmin, pmax, loss0, loss1)
    if pmin >= 0 && pmax >=0
        pminf = pmin
        pmaxf = pmax
        pmint = loss0 - pmaxf * (1 - loss1)
        pmaxt = loss0 - pminf * (1 - loss1)
    end
    if pmin >= 0 && pmax < 0
        pminf = pmin
        pmint = pmax
        pmaxf = (-pmint + loss0) / (1-loss1)
        pmaxt = loss0 - pminf * (1 - loss1)
    end
    if pmin < 0 && pmax >= 0
        pmaxt = -pmin
        pmaxf = pmax
        pminf = (-pmaxt + loss0) / (1-loss1)
        pmint = loss0 - pmaxf * (1 - loss1)
    end
    if pmin < 0 && pmax < 0
        pmaxt = -pmin
        pmint = pmax
        pmaxf = (-pmint + loss0) / (1-loss1)
        pminf = (-pmaxt + loss0) / (1-loss1)
    end
    return pminf, pmaxf, pmint, pmaxt
end
