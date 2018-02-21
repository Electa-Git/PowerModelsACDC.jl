"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*w
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*w
```
"""
function constraint_kcl_shunt{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, pd, qd, gs, bs)
    w = pm.var[:nw][n][:w][i]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    p_dc = pm.var[:nw][n][:p_dc]
    q_dc = pm.var[:nw][n][:q_dc]
    pconv_grid_ac = pm.var[:nw][n][:pconv_grid_ac]
    qconv_grid_ac = pm.var[:nw][n][:qconv_grid_ac]

    pm.con[:nw][n][:kcl_p][i] = @constraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - pd  - gs*w)
    pm.con[:nw][n][:kcl_q][i] = @constraint(pm.model, sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - qd  + bs*w)
end



"""
Creates Ohms constraints for DC branches

```
p[f_idx] + p[t_idx] == p * g[l] * (wdc[f_bus] - wdcr[f_bus,t_bus])
```
"""
function constraint_ohms_dc_branch{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p)
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
pconv_ac[i] + pconv_dc[i] == a + b*I + c*Isq
```
"""
function constraint_converter_losses{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i::Int, a, b, c)
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    pconv_dc = pm.var[:nw][n][:pconv_dc][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]

    pm.con[:nw][n][:conv_loss][i] = @constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv_sq)
end

"""
Creates transformer, filter and phase reactor model at ac side of converter

```
pconv_ac[i]
```
"""
function constraint_converter_filter_transformer_reactor{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, bv, rc, xc, acbus; zthresh = 0.0015)
    assert(zthresh>=0)
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    pconv_grid_ac = pm.var[:nw][n][:pconv_grid_ac][i]
    qconv_grid_ac = pm.var[:nw][n][:qconv_grid_ac][i]

    w = pm.var[:nw][n][:w][acbus] # vm^2
    #filter voltage
    wf_ac = pm.var[:nw][n][:wf_ac][i]   # vmf_ac * vmf_ac
    wrf_ac = pm.var[:nw][n][:wrf_ac][i] # vm*vmf_ac*cos(va-vaf_ac) =  vmf_ac*vm*cos(vaf_ac-va)
    wif_ac = pm.var[:nw][n][:wif_ac][i] # vm*vmf_ac*sin(va-vaf_ac) = -vmf_ac*vm*sin(vaf_ac-va)

    #converter voltage
    wc_ac = pm.var[:nw][n][:wc_ac][i]   # vmc_ac * vmc_ac
    wrc_ac = pm.var[:nw][n][:wrc_ac][i] # vmc_ac*vmf_ac*cos(vac_ac-vaf_ac) =  vmf_ac*vmc_ac*cos(vaf_ac-vac_ac)
    wic_ac = pm.var[:nw][n][:wic_ac][i] # vmc_ac*vmf_ac*sin(vac_ac-vaf_ac) = -vmf_ac*vmc_ac*sin(vaf_ac-vac_ac)

    ztf = rtf + im*xtf
    zc  = rc  + im*xc

    if abs(ztf) > zthresh
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, pconv_grid_ac ==  gtf*w + -gtf*wrf_ac + -btf*wif_ac)
        pm.con[:nw][n][:conv_tf_q][i] = @constraint(pm.model, qconv_grid_ac == -btf*w +  btf*wrf_ac + -gtf*wif_ac)
        PowerModels.relaxation_complex_product(pm.model, w, wf_ac, wrf_ac, wif_ac)
        pconv_grid_ac_ji =  gtf*wf_ac + -gtf*wrf_ac     + -btf*(-wif_ac)
        qconv_grid_ac_ji = -btf*wf_ac +  btf*wrf_ac     + -gtf*(-wif_ac)
    else
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, w ==  wf_ac)
        @constraint(pm.model, wrf_ac ==  wf_ac)
        @constraint(pm.model, wif_ac ==  0)
        pconv_grid_ac_ji = -pconv_grid_ac
        qconv_grid_ac_ji = -qconv_grid_ac
    end

    if abs(zc) > zthresh
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, -pconv_ac == gc*wc_ac + -gc*wrc_ac + -bc*wic_ac)
        pm.con[:nw][n][:conv_pr_q][i] = @constraint(pm.model, -qconv_ac ==-bc*wc_ac +  bc*wrc_ac + -gc*wic_ac)
        PowerModels.relaxation_complex_product(pm.model, wf_ac, wc_ac, wrc_ac, wic_ac)
        pconv_ac_ji =  gc *wf_ac + -gc *wrc_ac     + -bc *(-wic_ac)
        qconv_ac_ji = -bc *wf_ac +  bc *wrc_ac     + -gc *(-wic_ac)
    else
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, wc_ac ==  wf_ac)
        @constraint(pm.model, wrc_ac ==  wc_ac)
        @constraint(pm.model, wic_ac ==  0)
        pconv_ac_ji = pconv_ac
        qconv_ac_ji = qconv_ac
    end

    pm.con[:nw][n][:conv_kcl_p][i] = @constraint(pm.model, pconv_grid_ac_ji + pconv_ac_ji == 0 )
    pm.con[:nw][n][:conv_kcl_q][i] = @constraint(pm.model, qconv_grid_ac_ji + qconv_ac_ji + -bv*wf_ac == 0)

end


"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int)
    wdc = pm.var[:nw][n][:wdc]
    wdcr = pm.var[:nw][n][:wdcr]

    for (i,j) in keys(pm.ref[:nw][n][:buspairsdc])
        PowerModels.relaxation_complex_product(pm.model, wdc[i], wdc[j], wdcr[(i,j)], 0)
    end
end

"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= 3 * wdc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= 3 * (Umax)^2] * (iconv_ac[i])^2
```
"""
function constraint_converter_current{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_ac, Umax)
    wac = pm.var[:nw][n][:w][bus_ac]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= 3 * wac * iconv_sq)
    pm.con[:nw][n][:conv_i_sqrt][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= 3 * (Umax)^2 * iconv^2)

end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int, i, vdcm)
    wdc = pm.var[:nw][n][:wdc][i]
    pm.con[:nw][n][:v_dc][i] = @constraint(pm.model, wdc == vdcm^2)
end

function variable_converter_filter_voltage{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...)
    variable_converter_filter_voltage_wr_wrm(pm, n; kwargs...)
end

function variable_converter_internal_voltage{T <: PowerModels.AbstractWRForm}(pm::GenericPowerModel{T}, n::Int=pm.cnw; kwargs...)
    variable_converter_internal_voltage_wr_wrm(pm, n; kwargs...)
end


function add_dc_bus_voltage_setpoint{T <: PowerModels.AbstractWRForm}(sol, pm::GenericPowerModel{T})
    PowerModels.add_setpoint(sol, pm, "busdc", "vm", :wdc; scale = (x,item) -> sqrt(x))
end

function add_converter_voltage_setpoint{T <: PowerModels.AbstractWRForm}(sol, pm::GenericPowerModel{T})
    PowerModels.add_setpoint(sol, pm, "convdc", "vmconv", :wc_ac; scale = (x,item) -> sqrt(x))
    PowerModels.add_setpoint(sol, pm, "convdc", "vmfilt", :wf_ac; scale = (x,item) -> sqrt(x))
end
