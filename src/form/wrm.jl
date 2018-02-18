"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*w
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*w
```
"""
function constraint_kcl_shunt{T <: PowerModels.AbstractWRMForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, pd, qd, gs, bs)
    w_index = pm.ext[:nw][n][:lookup_w_index][i]
    w = pm.var[:nw][n][:WR][w_index, w_index]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    p_dc = pm.var[:nw][n][:p_dc]
    q_dc = pm.var[:nw][n][:q_dc]
    pconv_ac = pm.var[:nw][n][:pconv_ac]
    qconv_ac = pm.var[:nw][n][:qconv_ac]

    pm.con[:nw][n][:kcl_p][i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) + sum(pconv_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - pd  - gs*w)
    pm.con[:nw][n][:kcl_q][i] = @constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) + sum(qconv_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - qd  + bs*w)
end



"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch{T <: PowerModels.AbstractWRMForm}(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p)
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]

    wdc_fr = pm.var[:nw][n][:wdc][f_bus]
    wdc_to = pm.var[:nw][n][:wdc][t_bus]
    wdc_frto = pm.var[:nw][n][:wdcr][(f_bus, t_bus)]

    @constraint(pm.model, p_dc_fr == p * g *  (wdc_fr - wdc_frto))
    @constraint(pm.model, p_dc_to == p * g *  (wdc_to - wdc_frto))
end


"""
Creates lossy converter model between AC and DC grid

```
pconv_ac[i] + pconv_dc[i] == a + bI + cIsq
```
"""
function constraint_converter_losses{T <: PowerModels.AbstractWRMForm}(pm::GenericPowerModel{T}, n::Int, i::Int, a, b, c)
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    pconv_dc = pm.var[:nw][n][:pconv_dc][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]

    pm.con[:nw][n][:conv_loss][i] = @constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv_sq)
end


"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc{T <: PowerModels.AbstractWRMForm}(pm::GenericPowerModel{T}, n::Int)
    wdc = pm.var[:nw][n][:wdc]
    wdcr = pm.var[:nw][n][:wdcr]

    for (i,j) in keys(pm.ref[:nw][n][:buspairsdc])
        @constraint(pm.model, norm([ 2*wdcr[(i,j)]; wdc[i]-wdc[j] ]) <= wdc[i]+wdc[j] )
    end
end

"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= 3 * wdc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= 3 * (Umax)^2] * (iconv_ac[i])^2
```
"""
function constraint_converter_current{T <: PowerModels.AbstractWRMForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_ac,Umax)
    w_index = pm.ext[:nw][n][:lookup_w_index][i]
    wac = pm.var[:nw][n][:WR][w_index, w_index]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]


    pm.con[:nw][n][:conv_i][i] = @constraint(pm.model, norm([2pconv_ac;2qconv_ac; 3*(wac-iconv_sq)]) <= 3 *(wac+iconv_sq))
    pm.con[:nw][n][:conv_i_sqrt][i] = @constraint(pm.model, norm([pconv_ac;qconv_ac]) <= sqrt(3 *(Umax)^2)* iconv)

end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint{T <: PowerModels.AbstractWRMForm}(pm::GenericPowerModel{T}, n::Int, i, vdcm)
    wdc = pm.var[:nw][n][:wdc][i]
    pm.con[:nw][n][:v_dc][i] = @constraint(pm.model, wdc == vdcm^2)
end

function add_dc_bus_voltage_setpoint{T <: PowerModels.AbstractWRMForm}(sol, pm::GenericPowerModel{T})
    PowerModels.add_setpoint(sol, pm, "busdc", "vm", :wdc; scale = (x,item) -> sqrt(x))
end
