function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractWRMForm}
    pconv_grid_ac = pm.var[:nw][n][:pconv_grid_ac][i]
    qconv_grid_ac = pm.var[:nw][n][:qconv_grid_ac][i]
    pconv_grid_ac_to = pm.var[:nw][n][:pconv_grid_ac_to][i]
    qconv_grid_ac_to = pm.var[:nw][n][:qconv_grid_ac_to][i]

    #ac bus voltage
    w = pm.var[:nw][n][:w][acbus] # vm^2
    #filter voltage
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf
    wrf = pm.var[:nw][n][:wrf_ac][i] # vm*vmf*cos(va-vaf) =  vmf*vm*cos(vaf-va)
    wif = pm.var[:nw][n][:wif_ac][i] # vm*vmf*sin(va-vaf) = -vmf*vm*sin(vaf-va)

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, pconv_grid_ac ==  gtf*w/tm^2 + -gtf*wrf/tm + -btf*wif/tm)
        pm.con[:nw][n][:conv_tf_q_fr][i] = @constraint(pm.model, qconv_grid_ac == -btf*w/tm^2 +  btf*wrf/tm + -gtf*wif/tm)
        @constraint(pm.model, norm([ 2*wrf/tm;  2*wif/tm; w/tm^2-wf ]) <= w/tm^2+wf )

        pm.con[:nw][n][:conv_tf_p_to][i] = @constraint(pm.model, pconv_grid_ac_to ==  gtf*wf + -gtf*wrf/tm     + -btf*(-wif)/tm)
        pm.con[:nw][n][:conv_tf_q_to][i] = @constraint(pm.model, qconv_grid_ac_to == -btf*wf +  btf*wrf/tm     + -gtf*(-wif)/tm)
    else
        pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, w/tm^2 ==  wf)
        @constraint(pm.model, wrf ==  wf)
        @constraint(pm.model, wif ==  0)
        @constraint(pm.model, pconv_grid_ac + pconv_grid_ac_to == 0)
        @constraint(pm.model, qconv_grid_ac + qconv_grid_ac_to == 0)
    end
end

function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractWRMForm}
    ppr_fr = pm.var[:nw][n][:pconv_pr_from][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_from][i]
    ppr_to = -pm.var[:nw][n][:pconv_ac][i]
    qpr_to = -pm.var[:nw][n][:qconv_ac][i]

    #filter voltage
    wf = pm.var[:nw][n][:wf_ac][i]   # vmf * vmf

    #converter voltage
    wc = pm.var[:nw][n][:wc_ac][i]   # vmc * vmc
    wrc = pm.var[:nw][n][:wrc_ac][i] # vmc*vmf*cos(vac-vaf) =  vmf*vmc*cos(vaf-vac)
    wic = pm.var[:nw][n][:wic_ac][i] # vmc*vmf*sin(vac-vaf) = -vmf*vmc*sin(vaf-vac)

    zc  = rc  + im*xc

    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, ppr_to == gc*wc + -gc*wrc + -bc*wic)
        pm.con[:nw][n][:conv_pr_q][i] = @constraint(pm.model, qpr_to ==-bc*wc +  bc*wrc + -gc*wic)
        # PowerModels.relaxation_complex_product(pm.model, wf, wc, wrc, wic)
        @constraint(pm.model, norm([ 2*wrc;  2*wic; wf-wc ]) <= wf+wc )
        @constraint(pm.model, ppr_fr ==  gc *wf + -gc *wrc     + -bc *(-wic))
        @constraint(pm.model, qpr_fr == -bc *wf +  bc *wrc     + -gc *(-wic))
    else
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, wc ==  wf)
        @constraint(pm.model, wrc ==  wc)
        @constraint(pm.model, wic ==  0)
        @constraint(pm.model, ppr_fr + ppr_to == 0)
        @constraint(pm.model, qpr_fr + qpr_to == 0)
    end
end

"""
Model to approximate cross products of node voltages

```
wdcr[(i,j)] <= wdc[i]*wdc[j]
```
"""
function constraint_voltage_dc(pm::GenericPowerModel{T}, n::Int) where {T <: PowerModels.AbstractWRMForm}
    wdc = pm.var[:nw][n][:wdc]
    wdcr = pm.var[:nw][n][:wdcr]

    for (i,j) in keys(pm.ref[:nw][n][:buspairsdc])
        @constraint(pm.model, norm([ 2*wdcr[(i,j)]; wdc[i]-wdc[j] ]) <= wdc[i]+wdc[j] )
    end
end

"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, Umax) where {T <: PowerModels.AbstractWRMForm}
    # w_index = pm.ext[:nw][n][:lookup_w_index][i]
    # wac = pm.var[:nw][n][:WR][w_index, w_index]
    wc = pm.var[:nw][n][:wc_ac][i]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]
    pm.con[:nw][n][:conv_i][i] = @constraint(pm.model, norm([2pconv_ac;2qconv_ac; (wc-iconv_sq)]) <= (wc+iconv_sq))
    pm.con[:nw][n][:conv_i_sqrt][i] = @constraint(pm.model, norm([pconv_ac;qconv_ac]) <= (Umax* iconv))
    # pm.con[:nw][n][:conv_i][i] = @constraint(pm.model, norm([2pconv_ac;2qconv_ac; 3*(wac-iconv_sq)]) <= 3 *(wac+iconv_sq))
    # pm.con[:nw][n][:conv_i_sqrt][i] = @constraint(pm.model, norm([pconv_ac;qconv_ac]) <= sqrt(3 *(Umax)^2)* iconv)
end
