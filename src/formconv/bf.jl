function variable_converter_filter_voltage(pm::_PM.AbstractBFModel; kwargs...)
    variable_converter_filter_voltage_magnitude_sqr(pm; kwargs...)
    variable_conv_transformer_current_sqr(pm; kwargs...)
end

function variable_converter_internal_voltage(pm::_PM.AbstractBFModel; kwargs...)
    variable_converter_internal_voltage_magnitude_sqr(pm; kwargs...)
    variable_conv_reactor_current_sqr(pm; kwargs...)
end
"""
Converter transformer constraints
```
p_tf_fr + ptf_to ==  rtf*itf
q_tf_fr + qtf_to ==  xtf*itf
p_tf_fr^2 + qtf_fr^2 <= w/tm^2 * itf
wf == w/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf
```
"""
function constraint_conv_transformer(pm::_PM.AbstractBFQPModel, n::Int,  i::Int, rtf, xtf, acbus, tm, transformer)
    w = _PM.var(pm, n,  :w, acbus)
    itf = _PM.var(pm, n,  :itf_sq, i)
    wf = _PM.var(pm, n,  :wf_ac, i)


    ptf_fr = _PM.var(pm, n,  :pconv_tf_fr, i)
    qtf_fr = _PM.var(pm, n,  :qconv_tf_fr, i)
    ptf_to = _PM.var(pm, n,  :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n,  :qconv_tf_to, i)


    if transformer
        JuMP.@constraint(pm.model,   ptf_fr + ptf_to ==  rtf*itf)
        JuMP.@constraint(pm.model,   qtf_fr + qtf_to ==  xtf*itf)
        JuMP.@constraint(pm.model,   ptf_fr^2 + qtf_fr^2 <= w/tm^2 * itf)
        JuMP.@constraint(pm.model,   wf == w/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, wf == w )
    end
end

function constraint_conv_transformer(pm::_PM.AbstractBFConicModel, n::Int,  i::Int, rtf, xtf, acbus, tm, transformer)
    w = _PM.var(pm, n,  :w, acbus)
    itf = _PM.var(pm, n,  :itf_sq, i)
    wf = _PM.var(pm, n,  :wf_ac, i)


    ptf_fr = _PM.var(pm, n,  :pconv_tf_fr, i)
    qtf_fr = _PM.var(pm, n,  :qconv_tf_fr, i)
    ptf_to = _PM.var(pm, n,  :pconv_tf_to, i)
    qtf_to = _PM.var(pm, n,  :qconv_tf_to, i)


    if transformer
        JuMP.@constraint(pm.model,   ptf_fr + ptf_to ==  rtf*itf)
        JuMP.@constraint(pm.model,   qtf_fr + qtf_to ==  xtf*itf)
        JuMP.@constraint(pm.model,   [w/(sqrt(2)*tm), itf/(sqrt(2)*tm), ptf_fr, qtf_fr] in JuMP.RotatedSecondOrderCone())
        JuMP.@constraint(pm.model,   wf == w/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf)
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, wf == w/tm^2 )
    end
end

"""
Converter reactor constraints
```
p_pr_fr + ppr_to == rc*ipr
q_pr_fr + qpr_to == xc*ipr
p_pr_fr^2 + qpr_fr^2 <= wf * ipr
wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr
```
"""
function constraint_conv_reactor(pm::_PM.AbstractBFQPModel, n::Int,  i::Int, rc, xc, reactor)
    wf = _PM.var(pm, n,  :wf_ac, i)
    ipr = _PM.var(pm, n,  :irc_sq, i)
    wc = _PM.var(pm, n,  :wc_ac, i)
    ppr_to = -_PM.var(pm, n,  :pconv_ac, i)
    qpr_to = -_PM.var(pm, n,  :qconv_ac, i)
    ppr_fr = _PM.var(pm, n,  :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n,  :qconv_pr_fr, i)

    if reactor
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        JuMP.@constraint(pm.model, ppr_fr^2 + qpr_fr^2 <= wf * ipr)
        JuMP.@constraint(pm.model, wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)

    else
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, wc == wf)
    end
end

function constraint_conv_reactor(pm::_PM.AbstractBFConicModel, n::Int,  i::Int, rc, xc, reactor)
    wf = _PM.var(pm, n,  :wf_ac, i)
    ipr = _PM.var(pm, n,  :irc_sq, i)
    wc = _PM.var(pm, n,  :wc_ac, i)
    ppr_to = -_PM.var(pm, n,  :pconv_ac, i)
    qpr_to = -_PM.var(pm, n,  :qconv_ac, i)
    ppr_fr = _PM.var(pm, n,  :pconv_pr_fr, i)
    qpr_fr = _PM.var(pm, n,  :qconv_pr_fr, i)

    if reactor
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        JuMP.@constraint(pm.model, [wf/sqrt(2), ipr/sqrt(2), ppr_fr, qpr_fr] in JuMP.RotatedSecondOrderCone())
        JuMP.@constraint(pm.model, wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)

    else
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, wc == wf)
    end
end
"""
Links converter power & current
```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::_PM.AbstractBFQPModel, n::Int,  i::Int, Umax, Imax)
    wc = _PM.var(pm, n,  :wc_ac, i)
    pconv_ac = _PM.var(pm, n,  :pconv_ac, i)
    qconv_ac = _PM.var(pm, n,  :qconv_ac, i)
    iconv = _PM.var(pm, n,  :iconv_ac, i)
    iconv_sq = _PM.var(pm, n,  :iconv_ac_sq, i)

    JuMP.@constraint(pm.model, pconv_ac^2 + qconv_ac^2 <=  wc * iconv_sq)
    JuMP.@constraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (Umax)^2 * iconv^2)
    JuMP.@constraint(pm.model, iconv^2 <= iconv_sq)
    JuMP.@constraint(pm.model, iconv_sq <= iconv*Imax)
end

function constraint_converter_current(pm::_PM.AbstractBFConicModel, n::Int,  i::Int, Umax, Imax)
    wc = _PM.var(pm, n,  :wc_ac, i)
    pconv_ac = _PM.var(pm, n,  :pconv_ac, i)
    qconv_ac = _PM.var(pm, n,  :qconv_ac, i)
    iconv = _PM.var(pm, n,  :iconv_ac, i)
    iconv_sq = _PM.var(pm, n,  :iconv_ac_sq, i)

    JuMP.@constraint(pm.model, [wc/sqrt(2), iconv_sq/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    JuMP.@constraint(pm.model, [Umax * iconv/sqrt(2), Umax * iconv/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    JuMP.@constraint(pm.model, [iconv_sq, iconv/sqrt(2), iconv/sqrt(2)] in JuMP.RotatedSecondOrderCone())
    JuMP.@constraint(pm.model, iconv_sq <= iconv*Imax)
end


############### TNEP Constraints #######################################
function variable_converter_filter_voltage_ne(pm::_PM.AbstractBFModel; kwargs...)
    variable_converter_filter_voltage_magnitude_sqr_ne(pm; kwargs...)
    variable_conv_transformer_current_sqr_ne(pm; kwargs...)
end

function variable_converter_internal_voltage_ne(pm::_PM.AbstractBFModel; kwargs...)
    variable_converter_internal_voltage_magnitude_sqr_ne(pm; kwargs...)
    variable_conv_reactor_current_sqr_ne(pm; kwargs...)
end

"""
Converter transformer constraints

```
p_tf_fr + ptf_to ==  rtf*itf
q_tf_fr + qtf_to ==  xtf*itf
p_tf_fr^2 + qtf_fr^2 <= w/tm^2 * itf
wf == w/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf
```
"""
function constraint_conv_transformer_ne(pm::_PM.AbstractBFQPModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    w = _PM.var(pm, n, :w, acbus)
    itf = _PM.var(pm, n, :itf_sq_ne, i)
    wf = _PM.var(pm, n, :wf_ac_ne, i)
    w_du = _PM.var(pm, n, :w_du, i)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr_ne, i)
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to_ne, i)
    z = _PM.var(pm, n, :conv_ne)[i]

    if transformer
        JuMP.@constraint(pm.model,   ptf_fr + ptf_to ==  rtf*itf)
        JuMP.@constraint(pm.model,   qtf_fr + qtf_to ==  xtf*itf)
        JuMP.@constraint(pm.model,   ptf_fr^2 + qtf_fr^2 <= w_du/tm^2 * itf)
        JuMP.@constraint(pm.model,   wf  == w_du/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf)
        _IM.relaxation_equality_on_off(pm.model, w, w_du, z)
        JuMP.@constraint(pm.model, w_du >= z*JuMP.lower_bound(w))
        JuMP.@constraint(pm.model, w_du <= z*JuMP.upper_bound(w))
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, wf == w_du)
        _IM.relaxation_equality_on_off(pm.model, w, w_du, z)
        JuMP.@constraint(pm.model, w_du >= z*JuMP.lower_bound(w))
        JuMP.@constraint(pm.model, w_du <= z*JuMP.upper_bound(w))
    end
end

function constraint_conv_transformer_ne(pm::_PM.AbstractBFConicModel, n::Int, i::Int, rtf, xtf, acbus, tm, transformer)
    w = _PM.var(pm, n, :w, acbus)
    itf = _PM.var(pm, n, :itf_sq_ne, i)
    wf = _PM.var(pm, n, :wf_ac_ne, i)
    w_du = _PM.var(pm, n, :w_du, i)
    ptf_fr = _PM.var(pm, n, :pconv_tf_fr_ne, i)
    qtf_fr = _PM.var(pm, n, :qconv_tf_fr_ne, i)
    ptf_to = _PM.var(pm, n, :pconv_tf_to_ne, i)
    qtf_to = _PM.var(pm, n, :qconv_tf_to_ne, i)
    z = _PM.var(pm, n, :conv_ne)[i]

    if transformer
        JuMP.@constraint(pm.model,   ptf_fr + ptf_to ==  rtf*itf)
        JuMP.@constraint(pm.model,   qtf_fr + qtf_to ==  xtf*itf)
        JuMP.@constraint(pm.model,   [w_du/(sqrt(2)*tm), itf/(sqrt(2)*tm), ptf_fr, qtf_fr] in JuMP.RotatedSecondOrderCone())
        JuMP.@constraint(pm.model,   wf  == w_du/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf)
        _IM.relaxation_equality_on_off(pm.model, w, w_du, z)
        JuMP.@constraint(pm.model, w_du >= z*JuMP.lower_bound(w))
        JuMP.@constraint(pm.model, w_du <= z*JuMP.upper_bound(w))
    else
        JuMP.@constraint(pm.model, ptf_fr + ptf_to == 0)
        JuMP.@constraint(pm.model, qtf_fr + qtf_to == 0)
        JuMP.@constraint(pm.model, wf == w_du )
        _IM.relaxation_equality_on_off(pm.model, w, w_du, z)
        JuMP.@constraint(pm.model, w_du >= z*JuMP.lower_bound(w))
        JuMP.@constraint(pm.model, w_du <= z*JuMP.upper_bound(w))
    end
end

"""
Converter reactor constraints

```
p_pr_fr + ppr_to == rc*ipr
q_pr_fr + qpr_to == xc*ipr
p_pr_fr^2 + qpr_fr^2 <= wf * ipr
wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr
```
"""
function constraint_conv_reactor_ne(pm::_PM.AbstractBFQPModel, n::Int, i::Int, rc, xc, reactor)
    wf = _PM.var(pm, n, :wf_ac_ne, i)
    ipr = _PM.var(pm, n, :iconv_ac_sq_ne, i)
    wc = _PM.var(pm, n, :wc_ac_ne, i)
    ppr_to = -_PM.var(pm, n, :pconv_ac_ne, i)
    qpr_to = -_PM.var(pm, n, :qconv_ac_ne, i)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr_ne, i)

    if reactor
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        JuMP.@constraint(pm.model, ppr_fr^2 + qpr_fr^2 <= wf * ipr)
        JuMP.@constraint(pm.model, wc  == wf  -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)
    else
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, wc  == wf )
    end
end

function constraint_conv_reactor_ne(pm::_PM.AbstractBFConicModel, n::Int, i::Int, rc, xc, reactor)
    wf = _PM.var(pm, n, :wf_ac_ne, i)
    ipr = _PM.var(pm, n, :irc_sq_ne, i)
    wc = _PM.var(pm, n, :wc_ac_ne, i)
    ppr_to = -_PM.var(pm, n, :pconv_ac_ne, i)
    qpr_to = -_PM.var(pm, n, :qconv_ac_ne, i)
    ppr_fr = _PM.var(pm, n, :pconv_pr_fr_ne, i)
    qpr_fr = _PM.var(pm, n, :qconv_pr_fr_ne, i)


    if reactor
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        JuMP.@constraint(pm.model, [wf/sqrt(2), ipr/sqrt(2), ppr_fr, qpr_fr] in JuMP.RotatedSecondOrderCone())
        JuMP.@constraint(pm.model, wc  == wf  -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)
    else
        JuMP.@constraint(pm.model, ppr_fr + ppr_to == 0)
        JuMP.@constraint(pm.model, qpr_fr + qpr_to == 0)
        JuMP.@constraint(pm.model, wc  == wf )
    end
end

"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current_ne(pm::_PM.AbstractBFQPModel, n::Int, i::Int, Umax, Imax)
    wc = _PM.var(pm, n, :wc_ac_ne, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne, i)
    iconv = _PM.var(pm, n, :iconv_ac_ne, i)
    iconv_sq = _PM.var(pm, n, :iconv_ac_sq_ne, i)

    JuMP.@constraint(pm.model,      pconv_ac^2 + qconv_ac^2 <=  wc * iconv_sq)
    JuMP.@constraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (Umax)^2 * iconv^2)
    JuMP.@constraint(pm.model, iconv^2 <= iconv_sq)

    JuMP.@constraint(pm.model, iconv_sq <= iconv*Imax)
end
function constraint_converter_current_ne(pm::_PM.AbstractBFConicModel, n::Int, i::Int, Umax, Imax)
    wc = _PM.var(pm, n, :wc_ac_ne, i)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne, i)
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne, i)
    iconv = _PM.var(pm, n, :iconv_ac_ne, i)
    iconv_sq = _PM.var(pm, n, :iconv_ac_sq_ne, i)
    irc_sq = _PM.var(pm, n, :irc_sq_ne, i)

    JuMP.@constraint(pm.model, [wc/sqrt(2), iconv_sq/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    JuMP.@constraint(pm.model, [Umax * iconv/sqrt(2), Umax * iconv/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())

    JuMP.@constraint(pm.model, iconv_sq <= iconv*Imax)
    JuMP.@constraint(pm.model, iconv_sq == irc_sq)
end
