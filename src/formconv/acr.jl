"""
Creates lossy converter model between AC and DC grid using a lifted converter current magnitude variable
```
pconv_ac[i] + pconv_dc[i] == a + b * iconv[i] + c * iconv_sq[i]
```
Links the converter current magnitude variable with the squared converter current magnitude variable
```
iconv_sq[i] == iconv[i]^2 
```
"""
function constraint_converter_losses(pm::_PM.AbstractACRModel, n::Int, i::Int, a, b, c, plmax)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    iconv = _PM.var(pm, n, :iconv_ac, i)
    iconv_sq = _PM.var(pm, n, :iconv_ac_sq, i)

    JuMP.@constraint(pm.model, iconv_sq == iconv^2)
    JuMP.@constraint(pm.model, pconv_ac + pconv_dc == a + b*iconv + c* iconv_sq)
end
"""
Links converter power & current
```
pconv_ac[i]^2 + pconv_dc[i]^2 == (vrc[i]^2 + vic[i]^2) * iconv_sq[i]
```
"""
function constraint_converter_current(pm::_PM.AbstractACRModel, n::Int, i::Int, Umax, Imax)
    vrc = _PM.var(pm, n, :vrc, i)
    vic = _PM.var(pm, n, :vic, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac, i)
    iconv_sq = _PM.var(pm, n, :iconv_ac_sq, i)
    
    JuMP.@constraint(pm.model, pconv_ac^2 + qconv_ac^2 == (vrc^2 + vic^2) * iconv_sq)         
end
"""
Converter transformer constraints
```
p_tf_fr ==  g/(tm^2)*(vr_fr^2+vi_fr^2) + -g/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -b/(tm)*(vi_fr*vr_to-vr_fr*vi*to)
q_tf_fr == -b/(tm^2)*(vr_fr^2+vi_fr^2) +  b/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -g/(tm)*(vi_fr*vr_to-vr_fr*vi*to)
p_tf_to ==  g*(vr_to^2+vi_to^2)        + -g/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -b/(tm)*(-(vi_fr*vr_to-vr_fr*vi*to))
q_tf_to == -b*(vr_to^2+vi_to^2)        +  b/(tm)*(vr_fr*vr_to + vi_fr*vi_to) + -g/(tm)*(-(vi_fr*vr_to-vr_fr*vi*to))
```
"""
function constraint_conv_transformer(pm::_PM.AbstractACRModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr, i)
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)

    vr = _PM.var(pm, n, :vr, acbus)
    vi = _PM.var(pm, n, :vi, acbus)
    vrf = _PM.var(pm, n, :vrf, i)      
    vif = _PM.var(pm, n, :vif, i) 

    ztf = rtf + im*xtf
    if transformer
        ytf = 1/(rtf + im*xtf)
        gtf = real(ytf)
        btf = imag(ytf)
        
        JuMP.@constraint(pm.model, ptf_fr ==  gtf / tm^2 * (vr^2 + vi^2)  + -gtf / tm * (vr * vrf + vi * vif) + -btf / tm * (vi * vrf - vr * vif) )
        JuMP.@constraint(pm.model, qtf_fr == -btf / tm^2 * (vr^2 + vi^2)  - -btf / tm * (vr * vrf + vi * vif) + -gtf / tm * (vi * vrf - vr * vif) )
        JuMP.@constraint(pm.model, ptf_to ==  gtf * (vrf^2 + vif^2)       + -gtf / tm * (vr * vrf + vi * vif) + -btf / tm * (-(vi * vrf - vr * vif)) )
        JuMP.@constraint(pm.model, qtf_to == -btf * (vrf^2 + vif^2)       - -btf / tm * (vr * vrf + vi * vif) + -gtf / tm * (-(vi * vrf - vr * vif)) )

    else
        
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, vr == vrf)
        JuMP.@constraint(pm.model, vi == vif)
    end
end
"""
Converter reactor constraints
```
-pconv_ac == gc*(vrc^2 + vic^2) + -gc*(vrc * vrf + vic * vif) + -bc*(vic * vrf - vrc * vif)
-qconv_ac ==-bc*(vrc^2 + vic^2) +  bc*(vrc * vrf + vic * vif) + -gc*(vic * vrf - vrc * vif)
p_pr_fr ==  gc *(vrf^2 + vif^2) + -gc *(vrc * vrf + vic * vif) + -bc *(-(vic * vrf - vrc * vif))
q_pr_fr == -bc *(vrf^2 + vif^2) +  bc *(vrc * vrf + vic * vif) + -gc *(-(vic * vrf - vrc * vif))
```
"""
function constraint_conv_reactor(pm::_PM.AbstractACRModel, n::Int, i::Int, rc, xc, reactor)
    pconv_ac = _PM.var(pm, n,  :pconv_ac, i)
    qconv_ac = _PM.var(pm, n,  :qconv_ac, i)
    ppr_to = - pconv_ac
    qpr_to = - qconv_ac
    ppr_fr = _PM.var(pm, n,  :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n,  :qconv_pr_fr, i)

    vrf = _PM.var(pm, n, :vrf, i) 
    vif = _PM.var(pm, n, :vif, i) 
    vrc = _PM.var(pm, n, :vrc, i) 
    vic = _PM.var(pm, n, :vic, i) 

    zc = rc + im*xc
    if reactor
        yc = 1/(zc)
        gc = real(yc)
        bc = imag(yc)                                      
        JuMP.@constraint(pm.model, - pconv_ac ==  gc * (vrc^2 + vic^2) + -gc * (vrc * vrf + vic * vif) + -bc * (vic * vrf - vrc * vif))  
        JuMP.@constraint(pm.model, - qconv_ac == -bc * (vrc^2 + vic^2) +  bc * (vrc * vrf + vic * vif) + -gc * (vic * vrf - vrc * vif)) 
        JuMP.@constraint(pm.model, ppr_fr ==  gc * (vrf^2 + vif^2) + -gc * (vrc * vrf + vic * vif) + -bc * (-(vic * vrf - vrc * vif)))
        JuMP.@constraint(pm.model, qpr_fr == -bc * (vrf^2 + vif^2) +  bc * (vrc * vrf + vic * vif) + -gc * (-(vic * vrf - vrc * vif)))


    else
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, vrc == vrf)
        JuMP.@constraint(pm.model, vic == vif)
    end
end
"""
Converter filter constraints
```
ppr_fr + ptf_to == 0
qpr_fr + qtf_to +  (-bv) * filter *(vrf^2 + vif^2) == 0
```
"""
function constraint_conv_filter(pm::_PM.AbstractACRModel, n::Int, i::Int, bv, filter)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to, i)

    vrf = _PM.var(pm, n, :vrf, i)
    vif = _PM.var(pm, n, :vif, i)
    
    JuMP.@constraint(pm.model,   ppr_fr + ptf_to == 0 )
   JuMP.@constraint(pm.model, qpr_fr + qtf_to +  (-bv) * filter *(vrf^2 + vif^2) == 0)
   
end
"""
LCC firing angle constraints
```
pconv_ac == cos(phi) * Srated
qconv_ac == sin(phi) * Srated
```
"""
function constraint_conv_firing_angle(pm::_PM.AbstractACRModel, n::Int, i::Int, S, P1, Q1, P2, Q2)
    p = _PM.var(pm, n, :pconv_ac, i)
    q = _PM.var(pm, n, :qconv_ac, i)
    phi = _PM.var(pm, n, :phiconv, i)

    JuMP.@constraint(pm.model,   p == cos(phi) * S)
    JuMP.@constraint(pm.model,   q == sin(phi) * S)
end

function constraint_dc_droop_control(pm::_PM.AbstractACRModel, n::Int, i::Int, busdc_i, vref_dc, pref, k_droop; dc_power = true)
    pconv_dc = _PM.var(pm, n, :pconv_dc, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac, i)
    vdc = _PM.var(pm, n, :vdcm, busdc_i)

    if dc_power == true
        JuMP.@constraint(pm.model, pconv_dc == pref -  1 / k_droop * (vdc - vref_dc))
    else
        JuMP.@constraint(pm.model, pconv_ac == pref -  1 / k_droop * (vdc - vref_dc))
    end
end

#################### TNEP Constraints #########################