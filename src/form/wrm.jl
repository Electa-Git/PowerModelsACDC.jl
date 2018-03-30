function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractWRMForm}
    ptf_fr = pm.var[:nw][n][:pconv_tf_fr][i]
    qtf_fr = pm.var[:nw][n][:qconv_tf_fr][i]
    ptf_to = pm.var[:nw][n][:pconv_tf_to][i]
    qtf_to = pm.var[:nw][n][:qconv_tf_to][i]

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
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm.model, gtf, btf, w, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to, tm)
        pm.con[:nw][n][:conv_tf_p_fr][i] = c1
        pm.con[:nw][n][:conv_tf_q_fr][i] = c2
        pm.con[:nw][n][:conv_tf_p_to][i] = c3
        pm.con[:nw][n][:conv_tf_q_to][i] = c4

        @constraint(pm.model, norm([ 2*wrf;  2*wif; w-wf ]) <= w+wf )

    else
        pcon, qcon = constraint_lossless_section(pm, w/tm^2, wf, wrf, wif, ptf_fr, ptf_to, qtf_fr, qtf_to)
        #
        # @constraint(pm.model, w/tm^2 ==  wf)
        # @constraint(pm.model, wrf ==  wf)
        # @constraint(pm.model, wif ==  0)
        # pm.con[:nw][n][:conv_tf_p_fr][i] = @constraint(pm.model, ptf_fr + ptf_to == 0)
        # pm.con[:nw][n][:conv_tf_q_to][i] = @constraint(pm.model, qtf_fr + qtf_to == 0)
    end
end

function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractWRMForm}
    ppr_fr = pm.var[:nw][n][:pconv_pr_fr][i]
    qpr_fr = pm.var[:nw][n][:qconv_pr_fr][i]
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
        c1, c2, c3, c4 = ac_power_flow_constraints_w(pm.model, gc, bc, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to, 1)
        @constraint(pm.model, norm([ 2*wrc;  2*wic; wf-wc ]) <= wf+wc )
    else
        pcon, qcon = constraint_lossless_section(pm, wf, wc, wrc, wic, ppr_fr, ppr_to, qpr_fr, qpr_to)
        #
        # @constraint(pm.model, wc ==  wf)
        # @constraint(pm.model, wrc ==  wc)
        # @constraint(pm.model, wic ==  0)
        # @constraint(pm.model, ppr_fr + ppr_to == 0)
        # @constraint(pm.model, qpr_fr + qpr_to == 0)
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
end
