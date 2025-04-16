
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

function process_additional_data!(data; tnep = false)
    to_pu!(data)
    if haskey(data, "pst")
        process_pst_data!(data)
    end
    if haskey(data, "load_flex")
        process_flexible_demand_data!(data)
    end
    fix_data!(data; tnep = tnep)
    convert_matpowerdcline_to_branchdc!(data)
end

function process_pst_data!(data)
    if !haskey(data, "multinetwork") || data["multinetwork"] == false
        to_pu_single_network_pst!(data)
        fix_data_single_network_pst!(data)
    else
        to_pu_multi_network_pst!(data)
        fix_data_multi_network_pst!(data)
    end
end

function to_pu_single_network_pst!(data)
    MVAbase = data["baseMVA"]
    for (i, pst) in data["pst"]
        scale_pst_data!(pst, MVAbase)
    end
end

function fix_data_single_network_pst!(data)
    for (i, pst) in data["pst"]
        pst["g_fr"] = 0
        pst["b_fr"] = 0
        pst["g_to"] = 0
        pst["b_to"] = 0
        pst["tap"] = 1.0
    end
end
function to_pu_multi_network_pst!(data)
    MVAbase = data["baseMVA"]
    for (n, network) in data["nw"]
        MVAbase = network["baseMVA"]
        for (i, pst) in network[n]["pst"]
            scale_pst_data!(pst, MVAbase)
        end
    end
end

function fix_data_multi_network_pst!(data)
    for (n, network) in data["nw"]
        for (i, pst) in network[n]data["pst"]
            pst["g_fr"] = 0
            pst["b_fr"] = 0
            pst["g_to"] = 0
            pst["b_to"] = 0
            pst["tap"] = 1.0
        end
    end
end

function scale_pst_data!(pst, MVAbase)
    rescale_power = x -> x/MVAbase
    _PM._apply_func!(pst, "rate_a", rescale_power)
    _PM._apply_func!(pst, "rate_b", rescale_power)
    _PM._apply_func!(pst, "rate_c", rescale_power)
    _PM._apply_func!(pst, "angle", deg2rad)
    _PM._apply_func!(pst, "angmin", deg2rad)
    _PM._apply_func!(pst, "angmax", deg2rad)
end


function process_flexible_demand_data!(data)
    if !haskey(data, "multinetwork") || data["multinetwork"] == false
        process_flexible_demand_data_single_network!(data)
    else
        process_flexible_demand_data_multi_network!(data)
    end
end

function process_flexible_demand_data_single_network!(data)
    for (le, load_flex) in data["load_flex"]

        # ID of load point
        idx = load_flex["load_id"]

        # Superior bound on voluntary load reduction (not consumed power) as a fraction of the total reference demand (0 ≤ pred_rel_max ≤ 1)
        data["load"]["$idx"]["pred_rel_max"] = load_flex["pred_rel_max"]

        # Compensation for consuming less (i.e. voluntary demand reduction) (€/MWh)
        data["load"]["$idx"]["cost_red"] = load_flex["cost_red"]

        # Compensation for load curtailment (i.e. involuntary demand reduction) (€/MWh)
        data["load"]["$idx"]["cost_curt"] = load_flex["cost_curt"]

        # Whether load is flexible (boolean)
        data["load"]["$idx"]["flex"] = load_flex["flex"]

        # Power factor angle θ, giving the reactive power as Q = P ⨉ tan(θ)
        if haskey(load_flex, "pf_angle")
            data["load"]["$idx"]["pf_angle"] = load_flex["pf_angle"]
        end

        # Rescale cost and power input values to the p.u. values used internally in the model
        rescale_cost = x -> x*data["baseMVA"]
        rescale_power = x -> x/data["baseMVA"]
        _PM._apply_func!(data["load"]["$idx"], "cost_red", rescale_cost)
        _PM._apply_func!(data["load"]["$idx"], "cost_curt", rescale_cost)
    end
    delete!(data, "load_flex")
    return data
end

function process_flexible_demand_data_multi_network!(data)
    for (n, network) in data["nw"]
        for (le, load_flex) in data["load_flex"]
            # ID of load point
            idx = load_flex["load_id"]
            # Superior bound on voluntary load reduction (not consumed power) as a fraction of the total reference demand (0 ≤ pred_rel_max ≤ 1)
            data["nw"][n]["load"]["$idx"]["pred_rel_max"] = load_flex["pred_rel_max"]

            # Compensation for consuming less (i.e. voluntary demand reduction) (€/MWh)
            data["nw"][n]["load"]["$idx"]["cost_red"] = load_flex["cost_red"]

            # Compensation for load curtailment (i.e. involuntary demand reduction) (€/MWh)
            data["nw"][n]["load"]["$idx"]["cost_curt"] = load_flex["cost_curt"]

            # Whether load is flexible (boolean)
            data["nw"][n]["load"]["$idx"]["flex"] = load_flex["flex"]

            # Power factor angle θ, giving the reactive power as Q = P ⨉ tan(θ)
            if haskey(load_flex, "pf_angle")
                data["nw"][n]["load"]["$idx"]["pf_angle"] = load_flex["pf_angle"]
            end

            # Rescale cost and power input values to the p.u. values used internally in the model
            rescale_cost = x -> x*data["baseMVA"]
            rescale_power = x -> x/data["baseMVA"]
            _PM._apply_func!(data["nw"][n]["load"]["$idx"], "cost_red", rescale_cost)
            _PM._apply_func!(data["nw"][n]["load"]["$idx"], "cost_curt", rescale_cost)
        end
    end
    delete!(data, "load_flex")
    return data
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
                # conv["cost"] = conv["cost"]/length(data["nw"])
            end
        end
        if haskey(data["nw"][n], "branchdc_ne")
            for (i, branchdc) in data["nw"][n]["branchdc_ne"]
                set_branchdc_pu(branchdc, MVAbase)
                # branchdc["cost"] = branchdc["cost"]/length(data["nw"])
            end
        end
        # if haskey(data["nw"][n], "ne_branch")
        #     for (i, ne_branch) in data["nw"][n]["ne_branch"]
        #         ne_branch["construction_cost"] = ne_branch["construction_cost"]/length(data["nw"])
        #     end
        # end
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


function fix_data!(data; tnep = false)
    rescale_energy_cost = x -> (MWhbase/dollarbase)*x
    if is_single_network(data)
        fix_data_single_network!(data; tnep = tnep)
    else
        fix_data_multinetwork!(data; tnep = tnep)
    end
end

function fix_data_single_network!(data; tnep = false)
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
    if haskey(data, "load")
        for (l, load) in data["load"]
            if !haskey(load, "flex")
                load["flex"] = 0
            end
        end
    end
    if tnep
        if !haskey(data, "ne_branch")
            data["ne_branch"] = Dict()
        end
    end
end

function fix_data_multinetwork!(data; tnep = false)
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
        if haskey(data["nw"][n], "load")
            for (l, load) in data["nw"][n]["load"]
                if !haskey(load, "flex")
                    load["flex"] = 0
                end
            end
        end
        if tnep
            if !haskey(data["nw"][n],  "ne_branch")
                data["nw"][n]["ne_branch"] = Dict()
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
    if haskey(conv, "Pacset")
        _PM._apply_func!(conv, "Pacset", rescale_power)
    end
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


function prepare_uc_data!(data; borders = nothing, t_hvdc = nothing, ffr_cost = nothing, uc = false, time_interval = 1, frequency_parameters::Dict{String, Any})
    prepare_generator_data!(data; uc = uc)
    data["uc_parameters"] = Dict{String, Any}("time_interval" => time_interval)
    data["frequency_parameters"] = frequency_parameters

    if !isnothing(borders)
        find_and_assign_xb_lines!(data, borders)
    end

    if haskey(data, "convdc")
        for (c, conv) in data["convdc"]
            conv_bus = conv["busac_i"]
            conv["zone"] = data["bus"]["$conv_bus"]["zone"]
            conv["area"] = data["bus"]["$conv_bus"]["area"]
        end
    end

    # Add empth dictionary for PSTs
    if !haskey(data, "pst")
        data["pst"] = Dict{String, Any}()
    end

    # Add empty dictionaries for HVDC if only AC grid...
    if !haskey(data, "convdc")
        data["busdc"] = Dict{String, Any}()
        data["convdc"] = Dict{String, Any}()
        data["branchdc"] = Dict{String, Any}()
    end

    # Add empty dictionary if no AC tie lines are defined
    if !haskey(data, "tie_lines")
        data["tie_lines"] = Dict{String, Any}()
    end

    # Add empty dictionary if no areas are defined
    if !haskey(data, "areas")
        data["areas"] = Dict{String, Any}()
    end

    return data
end


function prepare_generator_data!(data; uc = false)
    for (g, gen) in data["gen"]
        bus_id = gen["gen_bus"]
        gen["zone"] = data["bus"]["$bus_id"]["zone"]
        gen["area"] = data["bus"]["$bus_id"]["area"]
        gen["inertia_constants"] = data["inertia_constants"][g]["inertia_constant"]
        if uc == true
            gen["start_up_cost"] = gen["startup"] / (gen["pmax"])
            gen["ramp_rate"] = data["inertia_constants"][g]["ramp_rate"]
            if data["inertia_constants"][g]["inertia_constant"] <= 1
                gen["mut"] = 1
                gen["mdt"] = 1
                gen["res"] = true
            else
                gen["mut"] = 3
                gen["mdt"] = 4
                gen["res"] = false
            end
        end
    end
end

function create_multinetwork_uc_model!(data, number_of_hours, g_series, l_series; contingencies = false)

    if contingencies == true
        generator_contingencies = length(data["gen"])
        tie_line_contingencies = length(data["tie_lines"]) 
        converter_contingencies = length(data["convdc"]) 
        dc_branch_contingencies = length(data["branchdc"]) 
        number_of_contingencies = generator_contingencies #+ tie_line_contingencies + converter_contingencies +  dc_branch_contingencies + 1 # to also add the N case
        replicates = number_of_hours * number_of_contingencies
        # This for loop determines which "network" belongs to an hour, and which to a contingency, for book-keeping of the network ids
        # Format: [h1, c1 ... cn, h2, c1 ... cn, .... , hn, c1 ... cn]
        hour_ids = [];
        cont_ids = [];
        for i in 1:replicates
            if mod(i, number_of_contingencies) == 1
                push!(hour_ids, i)
            else
                push!(cont_ids, i)
            end
        end
    else
        number_of_contingencies = 0
        replicates = number_of_hours
        hour_ids = [];
        cont_ids = [];
        for i in 1:replicates
            push!(hour_ids, i)
        end
    end        

    ########### Using _IM.replicate networks

    mn_data = _IM.replicate(data, replicates, Set{String}(["source_type", "name", "source_version", "per_unit"]))

    # Add hour_ids and contingency_ids to the data dictionary 
    mn_data["hour_ids"] = hour_ids
    mn_data["cont_ids"] = cont_ids
    mn_data["number_of_hours"] = number_of_hours
    mn_data["number_of_contingencies"] = number_of_contingencies

    if contingencies == true
        create_contingencies!(mn_data, number_of_hours, number_of_contingencies)
            # This loop writes the generation and demand time series data
        iter = 0
        for nw = 1:replicates
            if mod(nw, number_of_contingencies) == 1
                iter += 1
                h_idx = Int(nw - number_of_contingencies + 1)
            end
            h_idx = iter
            for (g, gen) in mn_data["nw"]["$nw"]["gen"]
                if gen["res"] == true
                    gen["pmax"] = g_series[h_idx] * gen["pmax"]
                end
            end
            for (l, load) in mn_data["nw"]["$nw"]["load"]
                load["pd"] = l_series[h_idx] * load["pd"]
            end
        end
    else
        for h_idx = 1:number_of_hours
            for (g, gen) in mn_data["nw"]["$h_idx"]["gen"]
                if gen["res"] == true
                    gen["pmax"] = g_series[h_idx] * gen["pmax"]
                end
            end
            for (l, load) in mn_data["nw"]["$h_idx"]["load"]
                load["pd"] = l_series[h_idx] * load["pd"]
            end
        end
    end



    process_additional_data!(mn_data)

    return mn_data
end

function create_contingencies!(mn_data, number_of_hours, number_of_contingencies)

    gen_keys = sort(parse.(Int, collect(keys(mn_data["nw"]["1"]["gen"]))))
    conv_keys = sort(parse.(Int, collect(keys(mn_data["nw"]["1"]["convdc"]))))
    tie_line_keys = sort(parse.(Int, collect(keys(mn_data["nw"]["1"]["tie_lines"]))))
    dc_branch_keys = sort(parse.(Int, collect(keys(mn_data["nw"]["1"]["branchdc"]))))

    for idx in 1:number_of_hours * number_of_contingencies
        if any(idx .== mn_data["hour_ids"])
            mn_data["nw"]["$idx"]["contingency"] = Dict{String, Any}("gen_id" => nothing, "branch_id" => nothing, "conv_id" => nothing, "dcbranch_id" => nothing)
        elseif mod(idx - 1, number_of_contingencies) <= length(gen_keys)
            c_id = mod(idx - 1, number_of_contingencies)
            mn_data["nw"]["$idx"]["contingency"] = Dict{String, Any}("gen_id" => gen_keys[c_id], "branch_id" => nothing, "conv_id" => nothing, "dcbranch_id" => nothing)
        elseif mod(idx - 1, number_of_contingencies) <= length(gen_keys) + length(tie_line_keys)
            c_id = mod(idx - 1, number_of_contingencies)
            b_idx = c_id - length(gen_keys)
            mn_data["nw"]["$idx"]["contingency"] = Dict{String, Any}("gen_id" => nothing, "branch_id" => tie_line_keys[b_idx], "conv_id" => nothing, "dcbranch_id" => nothing)
        elseif mod(idx - 1, number_of_contingencies) <= length(gen_keys) + length(tie_line_keys) + length(conv_keys)
            c_id = mod(idx - 1, number_of_contingencies)
            c_idx = c_id - length(gen_keys) - length(tie_line_keys)
            mn_data["nw"]["$idx"]["contingency"] = Dict{String, Any}("gen_id" => nothing, "branch_id" => nothing, "conv_id" => conv_keys[c_idx], "dcbranch_id" => nothing)
        else
            c_id = mod(idx-1, number_of_contingencies)
            b_idx = c_id - length(gen_keys) - length(tie_line_keys) - length(conv_keys)
            mn_data["nw"]["$idx"]["contingency"] = Dict{String, Any}("gen_id" => nothing, "branch_id" => nothing, "conv_id" => nothing, "dcbranch_id" => dc_branch_keys[b_idx])
        end
    end
    return mn_data
end

function prepare_redispatch_opf_data(reference_solution, grid_data; contingency = nothing, rd_cost_factor = 1, inertia_limit = nothing, zonal_input = nothing, zonal_result = nothing, zone = nothing, border_slack = nothing)
    grid_data_rd = deepcopy(grid_data)

    for (g, gen) in grid_data_rd["gen"]
        if haskey(reference_solution["gen"], g)
            gen["pg"] = reference_solution["gen"][g]["pg"]
            if gen["pg"] == 0.0
                gen["dispatch_status"] = 0
            else
                gen["dispatch_status"] = 1
            end 
        else
            gen["dispatch_status"] = 0
        end
        
        gen["rdcost_up"] = gen["cost"][1] * rd_cost_factor
        gen["rdcost_down"] = gen["cost"][1] * rd_cost_factor * 0
    end

    for (l, load) in grid_data_rd["load"]
        if haskey(reference_solution["load"], l)
            load["pd"] = reference_solution["load"][l]["pflex"]
        end
    end

    for (c, conv) in grid_data_rd["convdc"]
        conv["P_g"] = -reference_solution["convdc"][c]["ptf_to"]
    end

    if !isnothing(contingency)
        if haskey(grid_data_rd, "borders")
            for (b, border) in grid_data_rd["borders"]
                for (br, branch) in  border["xb_lines"]
                    if branch["index"] == contingency
                        print(b, " ", br)
                        delete!(grid_data_rd["borders"][b]["xb_lines"], br)
                    end
                end
            end
        end
        grid_data_rd["branch"]["$contingency"]["br_status"] = 0
    end

    if !isnothing(inertia_limit)
        grid_data_rd["inertia_limit"] = inertia_limit
    end

    if  !isnothing(zone)
        determine_total_xb_flow!(zonal_input, grid_data_rd, grid_data_rd, zonal_result, hour, zone)
    end

    if haskey(grid_data_rd, "borders")
        for (bo, border) in grid_data_rd["borders"]
            if !isnothing(border_slack)
                border["slack"] = border_slack
            else
                border["slack"] = 0
            end
        end
    end
    return grid_data_rd
end



