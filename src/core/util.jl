# Containts utilitiy functions needed across the package

function get_previous_hour_network_id(pm::_PM.AbstractPowerModel, nw::Int; uc = false)
    if !haskey(pm.ref[:it][:pm], :number_of_contingencies)
        number_of_contingencies = 0
    else
        number_of_contingencies = pm.ref[:it][:pm][:number_of_contingencies]
    end
    if uc == false
        previous_hour_network = nw - 1
    else
        if number_of_contingencies == 0
            previous_hour_id = Int((nw - 1))
            previous_hour_network = pm.ref[:it][:pm][:hour_ids][previous_hour_id]
        else
            previous_hour_id = Int((nw - 1) / number_of_contingencies)
            previous_hour_network = pm.ref[:it][:pm][:hour_ids][previous_hour_id]
        end
    end

    return previous_hour_network
end


function get_reference_network_id(pm::_PM.AbstractPowerModel, nw::Int; uc = false)
    if !haskey(pm.ref[:it][:pm], :number_of_contingencies)
        number_of_contingencies = 0
    else
        number_of_contingencies = pm.ref[:it][:pm][:number_of_contingencies]
    end

    if uc == false || number_of_contingencies == 0
        reference_network_idx = nw 
    else
        if mod(nw, number_of_contingencies) == 0
            hour_id = Int(nw - number_of_contingencies + 1)
        else
            hour_id = Int(nw - mod(nw, number_of_contingencies) + 1)
        end
        reference_network_idx = hour_id
    end

    return reference_network_idx 
end