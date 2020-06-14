function converter_cost(data)
    for(c,conv) in data["convdc_ne"]
        conv["cost"] = conv["Pacmax"]*0.083 *100+ 28
        display(conv["cost"])
    end
end

function converter_parameters_rxb(data)
for (c,conv) in data["convdc_ne"]
    # display("converter")
    # xtf = conv["xtf"]
    # bf = conv["bf"]
    # xc = conv["xc"]
    # Pmax = conv["Pacmax"]
    # Qmax = conv["Qacmax"]
    # println("convter:$c", "xtf:$xtf", "bf:$bf", "xc:$xc", "P: $Pmax", "Q: $Qmax")

    bus = conv["busac_i"]
    display(bus)
    base_kV = data["bus"]["$bus"]["base_kv"]
    base_S = sqrt((100*conv["Pacmax"])^2+(100*conv["Qacmax"])^2) #base MVA = 100
    base_Z = base_kV^2/base_S # L-L votlage/3 phase power
    base_Y= 1/base_Z
    display("baseS:$base_S")
    conv["xtf"] = 0.10*100/base_S #new X =old X *(100MVA/old Sbase)
    # display(conv["xtf"])
    # display(base_Z)
    conv["rtf"] = conv["xtf"]/100
    conv["bf"] = 0.08*base_S/100
    conv["xc"] = 0.07*100/base_S #new X =old X *(100MVA/old Zbase)
    # display(conv["xc"])
    # display(base_Z)
    conv["rc"] = conv["xc"]/100 #new X =old X *(100MVA/old Zbase)
    rtf = conv["rtf"]
    xtf = conv["xtf"]
    bf = conv["bf"]
    Pmax = conv["Pacmax"]
    Pmin =  conv["Pacmin"]
    Qmax = conv["Qacmax"]
    Qmin =  conv["Qacmin"]

    conv["Imax"] = sqrt(Pmax^2+Qmax^2)
    xc = conv["xc"]
    rc = conv["rc"]
    Imax = conv["Imax"]

    # println("convter:$c", "xtf:$xtf", "bf:$bf", "xc:$xc","baseS:$base_S", "baseZ:$base_Z","Pmin: $Pmin", "Pmax: $Pmax", "Qmin: $Qmin", "Qmax: $Qmax")
    println("rtf:$rtf","     ", "xtf:$xtf","     ", "bf:$bf", "     ","rc:$rc", "     ","xc:$xc", "     ","Imax:$Imax","     ","Pmin: $Pmin", "     ","Pmax: $Pmax" )
    if xtf > 0.1 || xc > 0.1
        # display("Casldfjew;afjz;lsdjf ;ljewbaf;ahjdfkj daslvncf;ahfdjasf newohf::$c")
    end
end
end
