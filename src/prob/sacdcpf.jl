export run_sacdcpf

"""
internal data required used solving a dc power flow

the primary use of this data structure is to prevent re-allocation of memory
between successive power flow solves

* `data` -- a power models data dictionary
* `busdc_gens` -- for each busdc id, a list of active generators representing dc side injections
* `amdc` -- an admittance matrix computed from the data dictionary for dc grid
* `busdc_type_idx` -- busdc types (i.e., 1, 2, 3) assigned for dc grid power flow
* `pdc_delta_base_idx` -- fixed active power delta at a busdc
* `pdc_inject_idx` -- variable active power generator injection at a busdc
* `vmdc_idx` -- variable voltage magnitude at a busdc
* `neighbors` -- neighboring buses to a given busdc
* `x0` -- 1*|N| variables, one for each busdc, varies based on busdc type   # TO DO check order for dc grid
* `F0` -- 1*|N| busdc power balance evaluation values, active power only    # TO DO check order for dc grid
* `J0` -- a sparse matrix holding the Jacobian of the F0 power balance evaluation function

The postfix `_idx` indicates the admittance matrix indexing convention.
"""
struct DCPowerFlowData
    data::Dict{String,<:Any}
    busdc_gens::Dict{Int,Vector}
    amdc::_PM.AdmittanceMatrix{Float64}
    busdc_type_idx::Vector{Int}
    pdc_delta_base_idx::Vector{Float64}
    pdc_inject_idx::Vector{Float64}
    vmdc_idx::Vector{Float64}
    neighbors::Vector{Set{Int}}
    x0::Vector{Float64}
    F0::Vector{Float64}
    J0::SparseArrays.SparseMatrixCSC{Float64,Int}
end


"""
This function solves sequential ac-dc power flow
"""
function run_sacdcpf(file::String; kwargs...)
    data = _PM.parse_file(file)
    PowerModelsACDC.process_additional_data!(data)
    return run_sacdcpf(data::Dict{String,Any}, kwargs...)
end


function run_sacdcpf(data)

    data["load_ref"] = Dict{String, Any}()
    data["load_ref"] = deepcopy(data["load"])
    data["gen_ref"] = Dict{String, Any}()
    data["gen_ref"] = deepcopy(data["gen"])
    data["bus_ref"] = Dict{String, Any}()
    data["bus_ref"] = deepcopy(data["bus"])

    network = deepcopy(data)

    # STEP 1: Add converter injections as additional injections, e.g. generators (PV bus), or loads (PQ bus)
    
    add_converter_ac_injections!(data)

    # STEP 2: Calculate Initial AC power flow
    result = _PM.compute_ac_pf(data)
    if result["termination_status"] != true
        Memento.warn(_LOGGER, "Initial ac powerflow in sequential acdc power flow does not converge.")
        # exit()
    end     
    
        
    conv_qnts = Dict{String, Any}()
    pgrid_slacks = []
    result_sacdc_pf = Dict{String,Any}()
    resultdc = Dict{String,Any}()
    result_sacdc_pf["iterations"] = 0
    iteration = 1
    convergence = 1
    time_start_iteration = time()
    while convergence > 0
        
        # STEP 3: Calculate converter voltages, currents, losses, and DC side PowerModels

        conv_qnts = calc_converter_quantities(result["solution"], data)     
        

        vm_p = Float64[]
        va_p = Float64[]
        for (i,bus) in data["bus"]
            push!(vm_p, result["solution"]["bus"]["$i"]["vm"])
            push!(va_p, result["solution"]["bus"]["$i"]["va"])
        end


        # STEP 4: Add dc converter injections as additional injections in dc grid, e.g. generators (PV bus)

        add_dc_converter_injections!(data,conv_qnts)
        
        # STEP 5: Calculate DC grid power flows

        try
            resultdc = compute_dc_pf(data, conv_qnts)
        catch exception
            Memento.warn(_LOGGER, "dc powerflow in sequential acdc power flow does not converge.")     
            break
        end
        
        # STEP 6: Calculate AC power injections from slack converter_quantities

        pgrid_slacks = compute_slack_converter_ac_injection(resultdc["solution"], data, conv_qnts)

        # STEP 7: Update slack converter injection

        for (gen_id, pgrid) in pgrid_slacks
            data["gen"]["$gen_id"]["pg"] = pgrid
        end
        
        # STEP 8: Re-calculate AC power flows

        try
            result = _PM.compute_ac_pf(data)
        catch exception
            Memento.warn(_LOGGER, "ac powerflow in sequential acdc power flow does not converge.")   
            break
        end

        # STEP 9: Check "vm" and "va" for convergence

        vm_c = Float64[]
        va_c = Float64[]
        for (j,bus) in data["bus"]
            push!(vm_c, result["solution"]["bus"]["$j"]["vm"])
            push!(va_c, result["solution"]["bus"]["$j"]["va"])
        end

        if isapprox(vm_p,vm_c; atol = 0.00001) && isapprox(abs.(va_p), abs.(va_c); atol = 0.001)
            Memento.info(_LOGGER, "Sequential acdc power flow has converged.")
            break
        end

        iteration += 1
        
    end

    
    result_sacdc_pf = generate_results(result_sacdc_pf, data, result, conv_qnts, pgrid_slacks, time_start_iteration, iteration, resultdc)

    # data cleanup !

    # Reset load in data

    data["load"] = deepcopy(data["load_ref"])
    data["bus"] = deepcopy(data["bus_ref"])
    delete!(data, "gendc")
    delete!(data, "load_ref")
    delete!(data, "bus_ref")
    
    # delete dummy gens

    gen_ref_num = maximum([gen["index"] for (g, gen) in data["gen_ref"]])
    for (i,gen) in data["gen"]
        if gen["index"] > gen_ref_num
            delete!(data["gen"], "$i")
            delete!(result_sacdc_pf["solution"]["gen"], "$i")
        end
    end

    data = deepcopy(network)

    return result_sacdc_pf

end



"""
This function adds converter injections as dummy generators and loads in the ac grid 
"""
function add_converter_ac_injections!(data)
    load_num = maximum([load["index"] for (l, load) in data["load"]])
    gen_num = maximum([gen["index"] for (g, gen) in data["gen"]])
    bus_load_pair = Dict(load["load_bus"] => l for (l,load) in data["load_ref"])
    load_idx = 1
    gen_idx = 1
    for (c, conv) in data["convdc"]
        conv_bus = conv["busac_i"]
        if conv["type_dc"] == 2
                idx = gen_num + gen_idx
                data["gen"]["$idx"] = Dict{String, Any}()
                data["gen"]["$idx"]["pg"] = -conv["P_g"]
                data["gen"]["$idx"]["qg"] = conv["Q_g"]    
                data["gen"]["$idx"]["model"] = 2
                data["gen"]["$idx"]["startup"] = 0.0
                data["gen"]["$idx"]["gen_bus"] = conv_bus
                data["gen"]["$idx"]["vg"] = conv["Vtar"] 
                data["gen"]["$idx"]["mbase"] = 100
                data["gen"]["$idx"]["index"] = idx
                data["gen"]["$idx"]["cost"] = [0.0, 0.0]
                data["gen"]["$idx"]["qmax"] = conv["Qacmax"]
                data["gen"]["$idx"]["pmax"] = conv["Pacmax"]
                data["gen"]["$idx"]["qmin"] = conv["Qacmin"]
                data["gen"]["$idx"]["pmin"] = conv["Pacmin"]
                data["gen"]["$idx"]["ncost"] = 2
                data["gen"]["$idx"]["type"] = "dcconv"
                data["gen"]["$idx"]["gen_status"] = conv["status"]
                data["gen"]["$idx"]["conv_id"] = conv["index"]
                data["bus"]["$conv_bus"]["bus_type"] = 2
                gen_idx += 1
        elseif conv["type_dc"] == 1
            if haskey(bus_load_pair, conv_bus)
                if conv["type_ac"] == 1
                    data["load"]["$(bus_load_pair[conv_bus])"]["pd"] += -conv["P_g"]
                    data["load"]["$(bus_load_pair[conv_bus])"]["qd"] += -conv["Q_g"]
                elseif conv["type_ac"] == 2
                     # adding load for active power
                    data["load"]["$(bus_load_pair[conv_bus])"]["pd"] += -conv["P_g"]
                    data["load"]["$(bus_load_pair[conv_bus])"]["qd"] += 0.0
                    # adding gen for reactive power
                    idx = gen_num + gen_idx
                    data["gen"]["$idx"] = Dict{String, Any}()
                    data["gen"]["$idx"]["pg"] = 0.0
                    data["gen"]["$idx"]["qg"] = conv["Q_g"]    
                    data["gen"]["$idx"]["model"] = 2
                    data["gen"]["$idx"]["startup"] = 0.0
                    data["gen"]["$idx"]["gen_bus"] = conv_bus
                    data["gen"]["$idx"]["vg"] = conv["Vtar"] 
                    data["gen"]["$idx"]["mbase"] = 100
                    data["gen"]["$idx"]["index"] = idx
                    data["gen"]["$idx"]["cost"] = [0.0, 0.0]
                    data["gen"]["$idx"]["qmax"] = conv["Qacmax"]
                    data["gen"]["$idx"]["pmax"] = conv["Pacmax"]
                    data["gen"]["$idx"]["qmin"] = conv["Qacmin"]
                    data["gen"]["$idx"]["pmin"] = conv["Pacmin"]
                    data["gen"]["$idx"]["ncost"] = 2
                    data["gen"]["$idx"]["type"] = "dcconv"
                    data["gen"]["$idx"]["gen_status"] = conv["status"]
                    data["gen"]["$idx"]["conv_id"] = conv["index"]
                    gen_idx += 1
                end
            else
                data["load"]["$(load_num + load_idx)"] = Dict{String, Any}()
                if conv["type_ac"] == 1
                    data["load"]["$(load_num + load_idx)"]["pd"] = -conv["P_g"]
                    data["load"]["$(load_num + load_idx)"]["qd"] = -conv["Q_g"]
                elseif conv["type_ac"] == 2
                    data["load"]["$(load_num + load_idx)"]["pd"] = -conv["P_g"]
                    data["load"]["$(load_num + load_idx)"]["qd"] = 0.0
                    # adding gen for reactive power
                    idx = gen_num + gen_idx
                    data["gen"]["$idx"] = Dict{String, Any}()
                    data["gen"]["$idx"]["pg"] = 0.0
                    data["gen"]["$idx"]["qg"] = conv["Q_g"]    
                    data["gen"]["$idx"]["model"] = 2
                    data["gen"]["$idx"]["startup"] = 0.0
                    data["gen"]["$idx"]["gen_bus"] = conv_bus
                    data["gen"]["$idx"]["vg"] = conv["Vtar"] 
                    data["gen"]["$idx"]["mbase"] = 100
                    data["gen"]["$idx"]["index"] = idx
                    data["gen"]["$idx"]["cost"] = [0.0, 0.0]
                    data["gen"]["$idx"]["qmax"] = conv["Qacmax"]
                    data["gen"]["$idx"]["pmax"] = conv["Pacmax"]
                    data["gen"]["$idx"]["qmin"] = conv["Qacmin"]
                    data["gen"]["$idx"]["pmin"] = conv["Pacmin"]
                    data["gen"]["$idx"]["ncost"] = 2
                    data["gen"]["$idx"]["type"] = "dcconv"
                    data["gen"]["$idx"]["gen_status"] = conv["status"]
                    data["gen"]["$idx"]["conv_id"] = conv["index"]
                    gen_idx += 1
                end
                data["load"]["$(load_num + load_idx)"]["source_id"] = Any["bus", conv_bus]
                data["load"]["$(load_num + load_idx)"]["load_bus"]  = conv_bus
                data["load"]["$(load_num + load_idx)"]["status"]    = conv["status"]
                data["load"]["$(load_num + load_idx)"]["index"]     = load_num + load_idx
                load_idx += 1
            end
        end
    end
end


"""
This function calculates converter station power flows 
"""
function calc_converter_quantities(result, data)
    conv_qnts = Dict{String, Any}()
    for (conv_id, conv) in data["convdc"]
            # Create a dict for all converters
            conv_qnts["$conv_id"] = Dict{String, Any}()
            # Grid voltage
            conv_bus = conv["busac_i"]
            conv_qnts["$conv_id"]["vm_grid"] = result["bus"]["$conv_bus"]["vm"]
            conv_qnts["$conv_id"]["va_grid"] = result["bus"]["$conv_bus"]["va"]
            tm = data["convdc"]["$conv_id"]["tm"]
            conv_qnts["$conv_id"]["Ugrid"] = Ugrid = (result["bus"]["$conv_bus"]["vm"]*exp(-result["bus"]["$conv_bus"]["va"]im))/tm
            
            # Power injections
            if conv["type_dc"] == 2
                for (g, gen) in data["gen"]
                    if haskey(gen, "type") && gen["type"] == "dcconv" && gen["conv_id"] == conv["index"]
                        conv_qnts["$conv_id"]["Pgrid"] = Pgrid = result["gen"][g]["pg"]
                        conv_qnts["$conv_id"]["Qgrid"] = Qgrid = result["gen"][g]["qg"]
                    end
                end       
            elseif conv["type_dc"] == 1
                if conv["type_ac"] == 1
                    bus_load_ref_pair = Dict(load["load_bus"] => l for (l,load) in data["load_ref"])
                    bus_load_pair_new = Dict(load["load_bus"] => l for (l,load) in data["load"] if !haskey(data["load_ref"],l))
                    if haskey(bus_load_ref_pair, conv_bus)
                        conv_qnts["$conv_id"]["Pgrid"] = Pgrid = data["load"]["$(bus_load_ref_pair[conv_bus])"]["pd"] - data["load_ref"]["$(bus_load_ref_pair[conv_bus])"]["pd"] 
                        conv_qnts["$conv_id"]["Qgrid"] = Qgrid = data["load"]["$(bus_load_ref_pair[conv_bus])"]["qd"] - data["load_ref"]["$(bus_load_ref_pair[conv_bus])"]["qd"]
                    elseif haskey(bus_load_pair_new, conv_bus)
                        conv_qnts["$conv_id"]["Pgrid"] = Pgrid = data["load"]["$(bus_load_pair_new[conv_bus])"]["pd"]
                        conv_qnts["$conv_id"]["Qgrid"] = Qgrid = data["load"]["$(bus_load_pair_new[conv_bus])"]["qd"]
                    end
                elseif conv["type_ac"] == 2
                    bus_load_ref_pair = Dict(load["load_bus"] => l for (l,load) in data["load_ref"])
                    bus_load_pair_new = Dict(load["load_bus"] => l for (l,load) in data["load"] if !haskey(data["load_ref"],l))
                    if haskey(bus_load_ref_pair, conv_bus)
                        conv_qnts["$conv_id"]["Pgrid"] = Pgrid = data["load"]["$(bus_load_ref_pair[conv_bus])"]["pd"] - data["load_ref"]["$(bus_load_ref_pair[conv_bus])"]["pd"] 
                    elseif haskey(bus_load_pair_new, conv_bus)
                        conv_qnts["$conv_id"]["Pgrid"] = Pgrid = data["load"]["$(bus_load_pair_new[conv_bus])"]["pd"]
                    end
                    for (g, gen) in data["gen"]
                        if haskey(gen, "type") && gen["type"] == "dcconv" && gen["conv_id"] == conv["index"]
                            conv_qnts["$conv_id"]["Qgrid"] = Qgrid = result["gen"][g]["qg"]
                        end
                    end        
                end

            end
            conv_qnts["$conv_id"]["Sgrid"] = Sgrid = Pgrid + Qgrid*im
            # Transformer current calculation: Itf = Sgrid / Ugrid
            Itf = conj(Sgrid / Ugrid)
            # Filter current If = -Ufilter * Bf = -(Ugrid - Itf * (Rtf + j Ztf)) 
            Ztf = (data["convdc"]["$conv_id"]["rtf"] + data["convdc"]["$conv_id"]["xtf"]im ) * data["convdc"]["$conv_id"]["transformer"]
            conv_qnts["$conv_id"]["Ztf"] = Ztf
            conv_qnts["$conv_id"]["Bf"] = Bf = data["convdc"]["$conv_id"]["bf"] * data["convdc"]["$conv_id"]["filter"]
            # If = -(Ugrid - Itf*(Ztf)) * Bf
            conv_qnts["$conv_id"]["Uf"] = Uf = (Ugrid - Itf*(Ztf))
            conv_qnts["$conv_id"]["If"] = If = (Ugrid - Itf*(Ztf)) * (-Bf*im)
            # Reactor current Ipr = Itf - If
            conv_qnts["$conv_id"]["Ipr"] = Ipr = Itf - If
            # Converter voltage Uc = Uf - Ic * Zpr & Ic = Ipr
            Zpr = (data["convdc"]["$conv_id"]["rc"] + data["convdc"]["$conv_id"]["xc"]im ) * data["convdc"]["$conv_id"]["reactor"] 
            conv_qnts["$conv_id"]["Zpr"] = Zpr
            Uc = (Ugrid - Itf*(Ztf)) - Ipr * Zpr
            # Converter power Sconv = Uc * Ic'
            conv_qnts["$conv_id"]["Sconv"] = Sconv = Uc * conj(Ipr)
            Pconv = real(Sconv)
            Qconv = imag(Sconv)
            # Converter losses Ploss = a + b * |Ic| + c * Ic^2 
            Ploss = data["convdc"]["$conv_id"]["LossA"] + data["convdc"]["$conv_id"]["LossB"] * abs(Ipr) + data["convdc"]["$conv_id"]["LossCrec"] * abs(Ipr)^2
            # Pdc = Pconv - Ploss
            Pdc = -Pconv + Ploss 
            conv_qnts["$conv_id"]["Pconv"] = Pconv
            conv_qnts["$conv_id"]["Qconv"] = Qconv
            conv_qnts["$conv_id"]["Pdc"] = Pdc
            conv_qnts["$conv_id"]["Ploss"] = Ploss
            conv_qnts["$conv_id"]["Uc"] = Uc
            conv_qnts["$conv_id"]["Ptf_to"] = real(Uf * -conj(Itf)) 
            conv_qnts["$conv_id"]["Qtf_to"] = imag(Uf * -conj(Itf))
            conv_qnts["$conv_id"]["Ppr_fr"] = real(Uf * conj(Ipr)) 
            conv_qnts["$conv_id"]["Qpr_fr"] = imag(Uf * conj(Ipr))

        end 

    return conv_qnts
end


"""
This function adds converter injections as dummy generators in the dc grid 
"""
function add_dc_converter_injections!(data,conv_qnts)
    # add dummy generators on busdc
    if haskey(data, "gendc")
        for (idx, conv) in data["convdc"]
            if conv["type_dc"] == 2
                data["gendc"]["$idx"]["pg"] = conv_qnts["$idx"]["Pdc"]
            end
        end
    else
        data["gendc"] = Dict{String, Any}()
        for (idx, conv) in data["convdc"]
            data["gendc"]["$idx"] = Dict{String, Any}()
            data["gendc"]["$idx"]["pg"] = -conv_qnts["$idx"]["Pdc"]
            data["gendc"]["$idx"]["qg"] = 0.0
            data["gendc"]["$idx"]["model"] = 2
            data["gendc"]["$idx"]["startup"] = 0.0
            data["gendc"]["$idx"]["gen_bus"] = conv["busdc_i"]
            data["gendc"]["$idx"]["vg"] = conv["Vtar"]
            data["gendc"]["$idx"]["mbase"] = 100
            data["gendc"]["$idx"]["index"] = idx
            data["gendc"]["$idx"]["cost"] = [0.0, 0.0]
            data["gendc"]["$idx"]["qmax"] = 0.0
            data["gendc"]["$idx"]["pmax"] = 1.2*conv["Pacmax"]
            data["gendc"]["$idx"]["qmin"] = 0.0
            data["gendc"]["$idx"]["pmin"] = conv["Pacmin"]
            data["gendc"]["$idx"]["ncost"] = 2
            data["gendc"]["$idx"]["type"] = "dcconv_busdc"
            data["gendc"]["$idx"]["gen_status"] = conv["status"]
            data["gendc"]["$idx"]["conv_id"] = conv["index"]
            bus_idx = conv["busdc_i"]
            if conv["type_dc"] == 1 || conv["type_dc"] == 3
                data["busdc"]["$bus_idx"]["bus_type"] = 1
            elseif conv["type_dc"] == 2
                data["busdc"]["$bus_idx"]["bus_type"] = 3
            end
        end
    end
end


"""
This function solves dc grid power flow
"""
function compute_dc_pf(data, conv_qnts)

    dcpf_data = instantiate_dcpf_data(data, conv_qnts)
    dc_pf_results =  _compute_dc_pf(dcpf_data)

    return dc_pf_results

end


function instantiate_dcpf_data(data::Dict{String,<:Any}, conv_qnts::Dict{String,<:Any})
    
    pdc_delta = calc_busdc_injection(data)
    
    # remove gendc injections from slack 
    for (i,gendc) in data["gendc"]
        gendc_bus = data["busdc"]["$(gendc["gen_bus"])"]
        if gendc["gen_status"] != 0
            if gendc_bus["bus_type"] == 3
                pdc_delta[gendc_bus["index"]] -= gendc["pg"]
            end
        end
    end


    busdc_gens = Dict{Int,Array{Any}}()
    for (i,gendc) in data["gendc"]
        # skip inactive generators
        if gendc["gen_status"] == 0
            continue
        end

        gendc_bus_id = gendc["gen_bus"]
        if !haskey(busdc_gens, gendc_bus_id)
            busdc_gens[gendc_bus_id] = []
        end
        push!(busdc_gens[gendc_bus_id], gendc)
    end

    for (busdc_id, gensdc) in busdc_gens
        sort!(gensdc, by=x -> (x["qmax"] - x["qmin"], x["index"]))
    end

    amdc = calc_admittance_matrix(data)
      
    busdc_type_idx = Int[data["busdc"]["$(bus_id)"]["bus_type"] for bus_id in amdc.idx_to_bus]

    pdc_delta_base_idx = Float64[-pdc_delta[bus_id] for bus_id in amdc.idx_to_bus]
    
    pdc_inject_idx = [0.0 for bus_id in amdc.idx_to_bus]

    vmdc_idx = [1.0 for bus_id in amdc.idx_to_bus]
    

    # for buses with non-1.0 bus voltages
    for (i,busdc) in data["busdc"]
        if busdc["bus_type"] == 2 || busdc["bus_type"] == 3
            vmdc_idx[amdc.bus_to_idx[busdc["index"]]] = busdc["Vdc"]
        end
    end


    neighbors = [Set{Int}([i]) for i in eachindex(amdc.idx_to_bus)]
    I, J, V = _PM.findnz(amdc.matrix)
    for nz in eachindex(V)
        push!(neighbors[I[nz]], J[nz])
        push!(neighbors[J[nz]], I[nz])
    end

    x0 = [0.0 for i in 1:length(amdc.idx_to_bus)]
    F0 = similar(x0)

    J0_I = Int[]
    J0_J = Int[]
    J0_V = Float64[]

    for i in eachindex(amdc.idx_to_bus)
    
        for j in neighbors[i]
            push!(J0_I, i); push!(J0_J, j); push!(J0_V, 0.0)
        end
    end
    J0 = _PM.sparse(J0_I, J0_J, J0_V)

    return DCPowerFlowData(data, busdc_gens, amdc, busdc_type_idx, pdc_delta_base_idx, pdc_inject_idx, vmdc_idx, neighbors, x0, F0, J0)
end


function _compute_dc_pf(dcpf_data::DCPowerFlowData; finite_differencing=false, flat_start=false, kwargs...)
    time_start = time()
    data = dcpf_data.data
    amdc = dcpf_data.amdc
    busdc_type_idx = dcpf_data.busdc_type_idx
    pdc_delta_base_idx = dcpf_data.pdc_delta_base_idx
    pdc_inject_idx = dcpf_data.pdc_inject_idx
    vmdc_idx = dcpf_data.vmdc_idx
    neighbors = dcpf_data.neighbors
    x0 = dcpf_data.x0
    F0 = dcpf_data.F0
    J0 = dcpf_data.J0

    # dc power flow, nodal power balance function eval
    function f!(F::Vector{Float64}, x::Vector{Float64})
        for i in eachindex(amdc.idx_to_bus)
            if busdc_type_idx[i] == 1
                vmdc_idx[i] = x[i]
            elseif busdc_type_idx[i] == 2
            elseif busdc_type_idx[i] == 3
                pdc_inject_idx[i] = x[i]
            else
                @assert false
            end
        end

        for i in eachindex(amdc.idx_to_bus)
            balance_real = pdc_delta_base_idx[i] + pdc_inject_idx[i]
            for j in neighbors[i]
                if i == j
                    balance_real += vmdc_idx[i] * vmdc_idx[i] *  amdc.matrix[i,i]
                else
                    balance_real += vmdc_idx[i] * vmdc_idx[j] * amdc.matrix[i,j] 
                end
            end
            F[i] = balance_real
        end


    end


    # dc power flow, sparse jacobian computation
    function jsp!(J::_PM.SparseArrays.SparseMatrixCSC{Float64,Int}, x::Vector{Float64})
        for i in eachindex(amdc.idx_to_bus)

            for j in neighbors[i]

                bus_type = busdc_type_idx[j]
                if bus_type == 1
                    if i == j
                        y_ii = amdc.matrix[i,i]
                        J[i, j] =  2 * y_ii * vmdc_idx[i] + sum(amdc.matrix[i,k] * vmdc_idx[k] for k in neighbors[i] if k != i)
                    else
                        y_ij = amdc.matrix[i,j]
                        J[i, j] = vmdc_idx[i] * y_ij 
                    end
                elseif bus_type == 2
                    if i == j
                        J[i, j] = 1.0
                    else
                        J[i, j] = 0.0
                    end
                elseif bus_type == 3
                    if i == j
                        J[i, j] = 1.0
                    else
                        J[i, j] = 0.0
                    end
                else
                    @assert false
                end
            end
        end
    end


    # basic init point
    for i in eachindex(amdc.idx_to_bus)
        if busdc_type_idx[i] == 1
            x0[i] = 1.0
        elseif busdc_type_idx[i] == 2
        elseif busdc_type_idx[i] == 3
        else
            @assert false
        end
    end

    # warm-start point
    if !flat_start
        pdc_inject = Dict{Int,Float64}(busdc["index"] => 0.0 for (i,busdc) in data["busdc"])
        for (i,gendc) in data["gendc"]
            if gendc["gen_status"] != 0
                if haskey(gendc, "pg_start")
                    pdc_inject[gendc["gen_bus"]] += gendc["pg_start"]
                end
            end
        end


        for (i,bid) in enumerate(amdc.idx_to_bus)
            busdc = data["busdc"]["$(bid)"]
            if busdc_type_idx[i] == 1
                if haskey(busdc, "vm_start")
                    x0[i] = busdc["vm_start"]
                end
            elseif busdc_type_idx[i] == 2
            elseif busdc_type_idx[i] == 3
                x0[i] = -pdc_inject[bid]
            else
                @assert false
            end
        end
    end


    
    if finite_differencing
        result = NLsolve.nlsolve(f!, x0; kwargs...)
    else
        df = NLsolve.OnceDifferentiable(f!, jsp!, x0, F0, J0)
        result = NLsolve.nlsolve(df, x0, xtol = 0.0, ftol = 1e-8, iterations = 1000, show_trace = false)
    end

    solution = Dict("per_unit" => dcpf_data.data["per_unit"])

    converged = result.x_converged || result.f_converged

    if !converged
        Memento.warn(_LOGGER, "dc power flow solver convergence failed! use `show_trace = true` for more details")
    else
        data = dcpf_data.data
        busdc_gens = dcpf_data.busdc_gens
        amdc = dcpf_data.amdc
        busdc_type_idx = dcpf_data.busdc_type_idx

        busdc_assignment= Dict{String,Any}()
        for (i,busdc) in data["busdc"]
            if busdc["bus_type"] != 4
                busdc_idx = amdc.bus_to_idx[busdc["index"]]

                busdc_assignment[i] = Dict(
                    "Vdc" => dcpf_data.vmdc_idx[busdc_idx]
                )
            end
        end

        gendc_assignment= Dict{String,Any}()
        for (i,gendc) in data["gendc"]
            if gendc["gen_status"] != 0
                gendc_assignment[i] = Dict(
                    "pg" => gendc["pg"]
                )
            end
        end


        for (i,bid) in enumerate(amdc.idx_to_bus)
            busdc = busdc_assignment["$(bid)"]

            if busdc_type_idx[i] == 1
                busdc["Vdc"] = result.zero[i]
            elseif busdc_type_idx[i] == 2
                for gendc in busdc_gens[bid]
                    sol_gen = gendc_assignment["$(gendc["index"])"]
                end
            elseif busdc_type_idx[i] == 3
                for gendc in busdc_gens[bid]
                    sol_gen = gendc_assignment["$(gendc["index"])"]
                    sol_gen["pg"] = 0.0
                end
                pg_remaining = result.zero[i]
                _assign_pg!(gendc_assignment, busdc_gens[bid], pg_remaining)
            else
                @assert false
            end
        end

        solution = Dict(
            "per_unit" => data["per_unit"],
            "busdc" => busdc_assignment,
            "gendc" => gendc_assignment,
        )
    end

    results = Dict(
        "optimizer" => "NLsolve",
        "termination_status" => converged,
        "objective" => 0.0,
        "solution" => solution,
        "solve_time" => time() - time_start
    )

    return results
end


"""
This function calculates dc bus injections 
"""
function calc_busdc_injection(data::Dict{String,<:Any})
    busdc_values = Dict(busdc["index"] => Dict{String,Float64}() for (i,busdc) in data["busdc"])
    for (i,busdc) in data["busdc"]
        bvals = busdc_values[busdc["index"]]
        bvals["pg"] = 0.0
    end
    for (i,gendc) in data["gendc"]
        if gendc["gen_status"] != 0
            bvals = busdc_values[gendc["gen_bus"]]
            bvals["pg"] += gendc["pg"]
        end
    end
    pdc_delta = Dict{Int,Float64}()
    for (i,busdc) in data["busdc"]
        if busdc["bus_type"] != 4
            bvals = busdc_values[busdc["index"]]
            p_delta = bvals["pg"] 
        else
            p_delta = NaN
        end
        pdc_delta[busdc["index"]] = p_delta
    end
    return pdc_delta
end


"""
This function calculates dc admittance matrix 
"""
function calc_admittance_matrix(data::Dict{String,<:Any})

    dc_buses = [x.second for x in data["busdc"]]       
    sort!(dc_buses, by=x->x["index"])

    idx_to_busdc = [x["index"] for x in dc_buses]
    busdc_to_idx = Dict(x["index"] => i for (i,x) in enumerate(dc_buses))

    I = Int[]
    J = Int[]
    V = Float64[]

    for (i,branchdc) in data["branchdc"]
        f_bus = branchdc["fbusdc"]
        t_bus = branchdc["tbusdc"]
        if branchdc["status"] != 0 && haskey(busdc_to_idx, f_bus) && haskey(busdc_to_idx, t_bus)
            f_bus = busdc_to_idx[f_bus]
            t_bus = busdc_to_idx[t_bus]
            g = inv(branchdc["r"])
            p = data["dcpol"]       
            push!(I, f_bus); push!(J, t_bus); push!(V, -p*g)
            push!(I, t_bus); push!(J, f_bus); push!(V, -p*g)
            push!(I, f_bus); push!(J, f_bus); push!(V, p*g)
            push!(I, t_bus); push!(J, t_bus); push!(V, p*g)
        end
    end

    m = _PM.sparse(I,J,V)

    amdc =  _PM.AdmittanceMatrix(idx_to_busdc, busdc_to_idx, m)
    return amdc
end


"""
This function performs internal iteration to calculate slack converter ac grid active injection 
"""
function compute_slack_converter_ac_injection(resultdc, data, conv_qnts)
    Pdc1 = 0.0
    pgrid_slacks_new =  []
    slack_conv_busac_i = 0
    for (conv_id, conv) in data["convdc"]
        if conv["type_dc"] == 2
            for (gen_id, gendc) in data["gendc"]
                if gendc["gen_bus"] == conv["busdc_i"]
                    Pdc1 = -resultdc["gendc"]["$gen_id"]["pg"]                    
                end
            end

            Ploss0 = conv_qnts["$conv_id"]["Ploss"]
            Qconv0 = conv_qnts["$conv_id"]["Qconv"]
            Uc0 = conv_qnts["$conv_id"]["Uc"]
            Ugrid0 = conv_qnts["$conv_id"]["Ugrid"]
            Zpr = conv_qnts["$conv_id"]["Zpr"]
            Ztf = conv_qnts["$conv_id"]["Ztf"]
            Bf = conv_qnts["$conv_id"]["Bf"]
            
            # iteration 1-Fwd
            Pconv1 = -Pdc1 + Ploss0 
            Sconv1 = Pconv1 + Qconv0*im
            Ipr1 = conj(Sconv1/Uc0)
            If1 = (Uc0 + Ipr1 * Zpr) * (-Bf*im)
            Itf1 = If1 + Ipr1    
            Sgrid1 = Ugrid0 * conj(Itf1)

            # iteration 1-Rev
            Itf2 = conj(Sgrid1/Ugrid0)
            # If1 = -(Ugrid0 - Itf2*(Ztf)) * Bf
            If2 = (Ugrid0 - Itf2*(Ztf)) * (-Bf*im)
            Ipr2 = Itf2 - If2
            # Uc1 = (Ugrid0 - Itf2*(Ztf)) - Ipr2 * Zpr
            Sconv2 = Uc0 * conj(Ipr2) 
            Pconv2 = real(Sconv2)
            Ploss1 = Pconv2 + Pdc1

            # Extract new values
            Pconv_new = -Pdc1 + Ploss1 
            Sconv_new = Pconv_new + Qconv0*im
            Ipr_new = conj(Sconv_new/Uc0)
            If_new = (Uc0 + Ipr2 * Zpr) * (-Bf*im)
            Itf_new = If_new + Ipr_new 
            Sgrid_new = Ugrid0 * conj(Itf_new)
            slack_conv_busac_i = conv["busac_i"]

            #
            conv_qnts["$conv_id"]["Pgrid"] = real(Sgrid_new)
            conv_qnts["$conv_id"]["Qgrid"] = imag(Sgrid_new)

            for (g, gen) in data["gen"]
                if haskey(gen, "type") && gen["type"] == "dcconv" && gen["gen_bus"] == slack_conv_busac_i && gen["conv_id"] == conv["index"]
                    push!( pgrid_slacks_new, (gen["index"], real(Sgrid_new)) )
                end
            end

        end
    end

    return pgrid_slacks_new
end


"""
This function generates results similar to acdcpf
"""
function generate_results(result_sacdc_pf, data, result, conv_qnts, pgrid_slacks, time_start_iteration, iteration, resultdc)
    result_sacdc_pf["time_iteration"] = time() - time_start_iteration
    result_sacdc_pf["iterations"] = iteration
    result_sacdc_pf["solution"] = result["solution"]
    result_sacdc_pf["optimizer"] = NLsolve
    result_sacdc_pf["per_unit"] = data["per_unit"]
    result_sacdc_pf["termination_status"] = "Converged"
    result_sacdc_pf["objective"] = 0.0
    result_sacdc_pf["solution"]["convdc"] = Dict{String,Any}()

    for (i,conv) in data["convdc"]
        if conv["status"] != 0
            if conv["type_dc"] != 2
                result_sacdc_pf["solution"]["convdc"][i] = Dict(
                    "vmfilt" => abs(conv_qnts[i]["Uf"]),
                    "qpr_fr" => conv_qnts[i]["Qpr_fr"],
                    "ppr_fr" => conv_qnts[i]["Ppr_fr"],
                    "qconv"  => imag(conv_qnts[i]["Sconv"]),
                    "iconv"  => abs(conv_qnts[i]["Ipr"]),
                    "pgrid"  => -data["convdc"][i]["P_g"],
                    "qtf_to" => conv_qnts[i]["Qtf_to"],
                    "phi"    => angle(conv_qnts[i]["Sconv"]),
                    "vaconv" => angle(conv_qnts[i]["Uc"]),
                    "pconv"  => conv_qnts[i]["Pconv"],
                    "ptf_to" => conv_qnts[i]["Ptf_to"],                     
                    "vmconv" => abs(conv_qnts[i]["Uc"]),
                    "vafilt" => angle(conv_qnts[i]["Uf"]),
                    "pdc"    => conv_qnts[i]["Pdc"],
                    "qgrid"  => -data["convdc"][i]["Q_g"]
                )
                bus_load_ref_pair = Dict(load["load_bus"] => l for (l,load) in data["load_ref"])
                bus_load_pair_new = Dict(load["load_bus"] => l for (l,load) in data["load"] if !haskey(data["load_ref"],l))
                conv_bus = conv["busac_i"]
                if haskey(bus_load_ref_pair, conv_bus)
                    result_sacdc_pf["solution"]["convdc"][i]["pgrid"] = - (data["load"]["$(bus_load_ref_pair[conv_bus])"]["pd"] - data["load_ref"]["$(bus_load_ref_pair[conv_bus])"]["pd"])
                    result_sacdc_pf["solution"]["convdc"][i]["qgrid"] = - (data["load"]["$(bus_load_ref_pair[conv_bus])"]["qd"] - data["load_ref"]["$(bus_load_ref_pair[conv_bus])"]["qd"])
                elseif haskey(bus_load_pair_new, conv_bus)
                    result_sacdc_pf["solution"]["convdc"][i]["pgrid"] = - (data["load"]["$(bus_load_pair_new[conv_bus])"]["pd"])
                    result_sacdc_pf["solution"]["convdc"][i]["qgrid"] = - (data["load"]["$(bus_load_pair_new[conv_bus])"]["qd"])
                end
                #
                if conv["type_ac"] == 2
                    result_sacdc_pf["solution"]["convdc"][i]["qgrid"] = [result["solution"]["gen"][g]["qg"] for (g, gen) in data["gen"] if haskey(gen, "type") && gen["type"] == "dcconv" && gen["conv_id"] == conv["index"]][1]
                end
            else
                result_sacdc_pf["solution"]["convdc"][i] = Dict(
                    "vmfilt" => abs(conv_qnts[i]["Uf"]),
                    "qpr_fr" => conv_qnts[i]["Qpr_fr"],
                    "ppr_fr" => conv_qnts[i]["Ppr_fr"],
                    "qconv"  => imag(conv_qnts[i]["Sconv"]),
                    "iconv"  => abs(conv_qnts[i]["Ipr"]),
                    "pgrid"  => [result["solution"]["gen"][g]["pg"] for (g, gen) in data["gen"] if haskey(gen, "type") && gen["type"] == "dcconv" && gen["conv_id"] == conv["index"]][1],
                    "qtf_to" => conv_qnts[i]["Qtf_to"],
                    "phi"    => angle(conv_qnts[i]["Sconv"]),
                    "vaconv" => angle(conv_qnts[i]["Uc"]),
                    "pconv"  => real(conv_qnts[i]["Sconv"]),
                    "ptf_to" => conv_qnts[i]["Ptf_to"],                     
                    "vmconv" => abs(conv_qnts[i]["Uc"]),
                    "vafilt" => angle(conv_qnts[i]["Uf"]),
                    "pdc"    => -conv_qnts[i]["Pdc"],
                    "qgrid"  => [result["solution"]["gen"][g]["qg"] for (g, gen) in data["gen"] if haskey(gen, "type") && gen["type"] == "dcconv" && gen["conv_id"] == conv["index"]][1]
                )        
            end
        end
    end

    result_sacdc_pf["solution"]["busdc"] = Dict{String,Any}()
    for (i,bsdc) in data["busdc"]
        result_sacdc_pf["solution"]["busdc"][i] = Dict(
            "vm" => resultdc["solution"]["busdc"][i]["Vdc"]
        )
    end

    result_sacdc_pf["solution"]["branchdc"] = Dict{String,Any}()
    for (i,brdc) in data["branchdc"]
        if brdc["status"] != 0
            result_sacdc_pf["solution"]["branchdc"][i] = Dict(
                "pt" => data["dcpol"] * (1/brdc["r"]) * resultdc["solution"]["busdc"]["$(brdc["tbusdc"])"]["Vdc"] * (resultdc["solution"]["busdc"]["$(brdc["tbusdc"])"]["Vdc"] - resultdc["solution"]["busdc"]["$(brdc["fbusdc"])"]["Vdc"]),
                "pf" => data["dcpol"] * (1/brdc["r"]) * resultdc["solution"]["busdc"]["$(brdc["fbusdc"])"]["Vdc"] * (resultdc["solution"]["busdc"]["$(brdc["fbusdc"])"]["Vdc"] - resultdc["solution"]["busdc"]["$(brdc["tbusdc"])"]["Vdc"])
            )
        end
    end
    return result_sacdc_pf
end


"""
This function assigns active power to active generators representing dc side injections within limits
"""
function _assign_pg!(sol_gens::Dict{String,<:Any}, busdc_gens::Vector, pg_remaining::Float64)
    for gendc in busdc_gens[1:end-1]
        pmin = gendc["pmin"]
        pmax = gendc["pmax"]

        if (pg_remaining <= 0.0 && pmin >= 0.0) || (pg_remaining >= 0.0 && pmax <= 0.0)
            # keep pg assignment as zero
            continue
        end

        sol_gen = sol_gens["$(gendc["index"])"]
        if pg_remaining < pmin
            sol_gen["pg"] = pmin
        elseif pg_remaining > pmax
            sol_gen["pg"] = pmax
        else
            sol_gen["pg"] = pg_remaining
            pg_remaining = 0.0
            break
        end
        pg_remaining -= sol_gen["pg"]
    end
    if !isapprox(pg_remaining, 0.0)
        gendc = busdc_gens[end]
        sol_gen = sol_gens["$(gendc["index"])"]
        sol_gen["pg"] = pg_remaining
    end
end
