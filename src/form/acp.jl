"""
```
sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) == sum(pg[g] for g in bus_gens) + sum(pconvac[c] for c in bus_convs) - pd - gs*v^2
sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) == sum(qg[g] for g in bus_gens) + sum(qconvac[c] for c in bus_convs) - qd + bs*v^2
```
"""
function constraint_kcl_shunt{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_convs_ac, pd, qd, gs, bs)
    vm = pm.var[:nw][n][:vm][i]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    p_dc = pm.var[:nw][n][:p_dc]
    q_dc = pm.var[:nw][n][:q_dc]
    pconv_grid_ac = pm.var[:nw][n][:pconv_grid_ac]
    qconv_grid_ac = pm.var[:nw][n][:qconv_grid_ac]



    pm.con[:nw][n][:kcl_p][i] = @NLconstraint(pm.model, sum(p[a] for a in bus_arcs) + sum(p_dc[a_dc] for a_dc in bus_arcs_dc) + sum(pconv_grid_ac[c] for c in bus_convs_ac)  == sum(pg[g] for g in bus_gens)  - pd - gs*vm^2)
    pm.con[:nw][n][:kcl_q][i] = @NLconstraint(pm.model, sum(q[a] for a in bus_arcs) + sum(q_dc[a_dc] for a_dc in bus_arcs_dc) + sum(qconv_grid_ac[c] for c in bus_convs_ac)  == sum(qg[g] for g in bus_gens)  - qd + bs*vm^2)
end


"""
Creates Ohms constraints for DC branches

```
p[f_idx] == p * g[l] * vmdc[f_bus] * (vmdc[f_bus] - vmdc[t_bus])
```
"""
function constraint_ohms_dc_branch{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, f_bus, t_bus, f_idx, t_idx, g, p)
    p_dc_fr = pm.var[:nw][n][:p_dcgrid][f_idx]
    p_dc_to = pm.var[:nw][n][:p_dcgrid][t_idx]
    vmdc_fr = pm.var[:nw][n][:vdcm][f_bus]
    vmdc_to = pm.var[:nw][n][:vdcm][t_bus]

    @NLconstraint(pm.model, p_dc_fr == p * g * vmdc_fr * (vmdc_fr - vmdc_to))
    @NLconstraint(pm.model, p_dc_to == p * g * vmdc_to * (vmdc_to - vmdc_fr))
end


"""
Creates lossy converter model between AC and DC grid

```
pconv_ac[i] + pconv_dc[i] == a + bI + cI^2
```
"""
function constraint_converter_losses{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, a, b, c)
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    pconv_dc = pm.var[:nw][n][:pconv_dc][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_loss][i] = @NLconstraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c*iconv^2)
end

"""
Creates transformer, filter and phase reactor model at ac side of converter

```
pconv_ac[i]
```
"""
function constraint_converter_filter_transformer_reactor{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, rtf, xtf, bv, rc, xc, acbus, transformer, filter, reactor)
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    pconv_grid_ac = pm.var[:nw][n][:pconv_grid_ac][i]
    qconv_grid_ac = pm.var[:nw][n][:qconv_grid_ac][i]
    #filter voltage
    vmf_ac = pm.var[:nw][n][:vmf_ac][i]
    vaf_ac = pm.var[:nw][n][:vaf_ac][i]
    #converter voltage
    vmc_ac = pm.var[:nw][n][:vmc_ac][i]
    vac_ac = pm.var[:nw][n][:vac_ac][i]

    vm = pm.var[:nw][n][:vm][acbus]
    va = pm.var[:nw][n][:va][acbus]
    display(bv)
    display(filter)
    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        pm.con[:nw][n][:conv_tf_p][i] = @NLconstraint(pm.model, pconv_grid_ac ==  gtf*vm^2 + -gtf*vm*vmf_ac*cos(va-vaf_ac) + -btf*vm*vmf_ac*sin(va-vaf_ac))
        pm.con[:nw][n][:conv_tf_q][i] = @NLconstraint(pm.model, qconv_grid_ac == -btf*vm^2 +  btf*vm*vmf_ac*cos(va-vaf_ac) + -gtf*vm*vmf_ac*sin(va-vaf_ac))
    else
        pm.con[:nw][n][:conv_tf_p][i] = @constraint(pm.model, va == vaf_ac)
        pm.con[:nw][n][:conv_tf_q][i] = @constraint(pm.model, vm == vmf_ac)
    end

    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)
        pm.con[:nw][n][:conv_pr_p][i] = @NLconstraint(pm.model, -pconv_ac == gc*vmc_ac^2 + -gc*vmc_ac*vmf_ac*cos(vac_ac-vaf_ac) + -bc*vmc_ac*vmf_ac*sin(vac_ac-vaf_ac))
        pm.con[:nw][n][:conv_pr_q][i] = @NLconstraint(pm.model, -qconv_ac ==-bc*vmc_ac^2 +  bc*vmc_ac*vmf_ac*cos(vac_ac-vaf_ac) + -gc*vmc_ac*vmf_ac*sin(vac_ac-vaf_ac))
    else
        pm.con[:nw][n][:conv_pr_p][i] = @constraint(pm.model, vac_ac == vaf_ac)
        pm.con[:nw][n][:conv_pr_q][i] = @constraint(pm.model, vmc_ac == vmf_ac)
    end
    display(pm.con[:nw][n][:conv_pr_p][i])
    display(pm.con[:nw][n][:conv_pr_q][i])


    if transformer && reactor
        pm.con[:nw][n][:conv_kcl_p][i] = @NLconstraint(pm.model,
        gtf*vmf_ac^2 + -gtf*vmf_ac*vm    *cos(vaf_ac - va)     + -btf*vmf_ac*vm    *sin(vaf_ac - va) +
        gc *vmf_ac^2 + -gc *vmf_ac*vmc_ac*cos(vaf_ac - vac_ac) + -bc *vmf_ac*vmc_ac*sin(vaf_ac - vac_ac) == 0 )
        pm.con[:nw][n][:conv_kcl_q][i] = @NLconstraint(pm.model,
        -btf*vmf_ac^2 +  btf*vmf_ac*vm*    cos(vaf_ac - va)     + -gtf*vmf_ac*vm    *sin(vaf_ac - va) +
        -bc *vmf_ac^2 +  bc *vmf_ac*vmc_ac*cos(vaf_ac - vac_ac) + -gc *vmf_ac*vmc_ac*sin(vaf_ac - vac_ac) +
        -bv * filter *vmf_ac^2 ==0)
    elseif !transformer && reactor
        pm.con[:nw][n][:conv_kcl_p][i] = @NLconstraint(pm.model,
        -pconv_grid_ac +
        gc *vmf_ac^2 + -gc *vmf_ac*vmc_ac*cos(vaf_ac - vac_ac) + -bc *vmf_ac*vmc_ac*sin(vaf_ac - vac_ac) == 0 )
        pm.con[:nw][n][:conv_kcl_q][i] = @NLconstraint(pm.model,
        -qconv_grid_ac +
        -bc *vmf_ac^2 +  bc *vmf_ac*vmc_ac*cos(vaf_ac - vac_ac) + -gc *vmf_ac*vmc_ac*sin(vaf_ac - vac_ac) +
        -bv * filter *vmf_ac^2 ==0)
    elseif transformer && !reactor
        pm.con[:nw][n][:conv_kcl_p][i] = @NLconstraint(pm.model,
        gtf*vmf_ac^2 + -gtf*vmf_ac*vm    *cos(vaf_ac - va)     + -btf*vmf_ac*vm    *sin(vaf_ac - va) +
        pconv_ac == 0 )
        pm.con[:nw][n][:conv_kcl_q][i] = @NLconstraint(pm.model,
        -btf*vmf_ac^2 +  btf*vmf_ac*vm*    cos(vaf_ac - va)     + -gtf*vmf_ac*vm    *sin(vaf_ac - va) +
        qconv_ac +
        -bv * filter *vmf_ac^2 ==0)
    elseif !transformer && !reactor
        pm.con[:nw][n][:conv_kcl_p][i] = @constraint(pm.model,
        -pconv_grid_ac +
        pconv_ac == 0 )
        pm.con[:nw][n][:conv_kcl_q][i] = @NLconstraint(pm.model,
        -qconv_grid_ac +
        qconv_ac +
        -bv * filter *vmf_ac^2 ==0)
    end
end



"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 == 3 * vm[i]^2 * iconv_ac[i]^2
```
"""
function constraint_converter_current{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i::Int, bus_ac, Umax)
    vm = pm.var[:nw][n][:vm][bus_ac]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]

    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 == 3 * vm^2 * iconv^2)
end

"`vdc[i] == vdcm`"
function constraint_dc_voltage_magnitude_setpoint{T <: PowerModels.AbstractACPForm}(pm::GenericPowerModel{T}, n::Int, i, vdcm)
    v = pm.var[:nw][n][:vdcm][i]
    pm.con[:nw][n][:v_dc][i] = @constraint(pm.model, v == vdcm)
end
