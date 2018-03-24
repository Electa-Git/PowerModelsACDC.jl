"""
Creates transformer, filter and phase reactor model at ac side of converter

```
pconv_ac[i]
```
"""
function constraint_converter_filter_transformer_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, bv, rc, xc, acbus, transformer, filter, reactor) where {T <: PowerModels.AbstractWRForm}
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

    if transformer
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

    if reactor
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
function constraint_voltage_dc(pm::GenericPowerModel{T}, n::Int) where {T <: PowerModels.AbstractWRForm}
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
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, bus_ac, Umax) where {T <: PowerModels.AbstractWRForm}
    wac = pm.var[:nw][n][:w][bus_ac]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= 3 * wac * iconv_sq)
    pm.con[:nw][n][:conv_i_sqrt][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= 3 * (Umax)^2 * iconv^2)
end
