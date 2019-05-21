function variable_converter_filter_voltage(pm::GenericPowerModel{T}; kwargs...) where {T <: PowerModels.AbstractBFForm}
    variable_converter_filter_voltage_magnitude_sqr(pm; kwargs...)
    variable_conv_transformer_current_sqr(pm; kwargs...)
end

function variable_converter_internal_voltage(pm::GenericPowerModel{T}; kwargs...) where {T <: PowerModels.AbstractBFForm}
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
function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractBFQPForm}
    w = PowerModels.var(pm, n, cnd, :w, acbus)
    itf = PowerModels.var(pm, n, cnd, :itf_sq, i)
    wf = PowerModels.var(pm, n, cnd, :wf_ac, i)


    ptf_fr = PowerModels.var(pm, n, cnd, :pconv_tf_fr, i)
    qtf_fr = PowerModels.var(pm, n, cnd, :qconv_tf_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)
    qtf_to = PowerModels.var(pm, n, cnd, :qconv_tf_to, i)


    if transformer
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = @constraint(pm.model,   ptf_fr + ptf_to ==  rtf*itf)
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = @constraint(pm.model,   qtf_fr + qtf_to ==  xtf*itf)
        PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = @constraint(pm.model,   ptf_fr^2 + qtf_fr^2 <= w/tm^2 * itf)
        PowerModels.con(pm, n, cnd, :conv_tf_q_to)[i] = @constraint(pm.model,   wf == w/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf)
    else
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = @constraint(pm.model, ptf_fr + ptf_to == 0)
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = @constraint(pm.model, qtf_fr + qtf_to == 0)
        @constraint(pm.model, wf == w/tm^2 )
    end
end

function constraint_conv_transformer(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, rtf, xtf, acbus, tm, transformer) where {T <: PowerModels.AbstractBFConicForm}
    w = PowerModels.var(pm, n, cnd, :w, acbus)
    itf = PowerModels.var(pm, n, cnd, :itf_sq, i)
    wf = PowerModels.var(pm, n, cnd, :wf_ac, i)


    ptf_fr = PowerModels.var(pm, n, cnd, :pconv_tf_fr, i)
    qtf_fr = PowerModels.var(pm, n, cnd, :qconv_tf_fr, i)
    ptf_to = PowerModels.var(pm, n, cnd, :pconv_tf_to, i)
    qtf_to = PowerModels.var(pm, n, cnd, :qconv_tf_to, i)


    if transformer
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = @constraint(pm.model,   ptf_fr + ptf_to ==  rtf*itf)
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = @constraint(pm.model,   qtf_fr + qtf_to ==  xtf*itf)
        # PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = @constraint(pm.model,   norm([2*ptf_fr; 2*qtf_fr; w/tm^2 - itf]) <= w/tm^2 + itf)
        # PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = @constraint(pm.model,   norm([2*ptf_fr; 2*qtf_fr; w/tm - itf/tm]) <= w/tm + itf/tm)
        # PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = @constraint(pm.model,   [2*ptf_fr, 2*qtf_fr, w/tm - itf/tm, w/tm + itf/tm] in JuMP.RotatedSecondOrderCone())
        PowerModels.con(pm, n, cnd, :conv_tf_p_to)[i] = @constraint(pm.model,   [w/(sqrt(2)*tm), itf/(sqrt(2)*tm), ptf_fr, qtf_fr] in JuMP.RotatedSecondOrderCone())
        PowerModels.con(pm, n, cnd, :conv_tf_q_to)[i] = @constraint(pm.model,   wf == w/tm^2 -2*(rtf*ptf_fr + xtf*qtf_fr) + (rtf^2 + xtf^2)*itf)
    else
        PowerModels.con(pm, n, cnd, :conv_tf_p_fr)[i] = @constraint(pm.model, ptf_fr + ptf_to == 0)
        PowerModels.con(pm, n, cnd, :conv_tf_q_fr)[i] = @constraint(pm.model, qtf_fr + qtf_to == 0)
        @constraint(pm.model, wf == w/tm^2 )
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
function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractBFQPForm}
    wf = PowerModels.var(pm, n, cnd, :wf_ac, i)
    ipr = PowerModels.var(pm, n, cnd, :irc_sq, i)
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    ppr_to = -PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qpr_to = -PowerModels.var(pm, n, cnd, :qconv_ac, i)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    qpr_fr = PowerModels.var(pm, n, cnd, :qconv_pr_fr, i)

    if reactor
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = @constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = @constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        @constraint(pm.model, ppr_fr^2 + qpr_fr^2 <= wf * ipr)
        @constraint(pm.model, wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)

    else
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = @constraint(pm.model, ppr_fr + ppr_to == 0)
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = @constraint(pm.model, qpr_fr + qpr_to == 0)
        @constraint(pm.model, wc == wf)
    end
end

function constraint_conv_reactor(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, rc, xc, reactor) where {T <: PowerModels.AbstractBFConicForm}
    wf = PowerModels.var(pm, n, cnd, :wf_ac, i)
    ipr = PowerModels.var(pm, n, cnd, :irc_sq, i)
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    ppr_to = -PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qpr_to = -PowerModels.var(pm, n, cnd, :qconv_ac, i)
    ppr_fr = PowerModels.var(pm, n, cnd, :pconv_pr_fr, i)
    qpr_fr = PowerModels.var(pm, n, cnd, :qconv_pr_fr, i)

    if reactor
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = @constraint(pm.model, ppr_fr + ppr_to == rc*ipr)
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = @constraint(pm.model, qpr_fr + qpr_to == xc*ipr)
        # @constraint(pm.model, norm([2*ppr_fr; 2*qpr_fr; wf - ipr]) <= wf + ipr)
        # @constraint(pm.model, norm([2*ppr_fr; 2*qpr_fr; wf - ipr]) <= wf + ipr)
        # @constraint(pm.model, [2*ppr_fr, 2*qpr_fr, wf - ipr, wf + ipr] in JuMP.RotatedSecondOrderCone())
        @constraint(pm.model, [wf/sqrt(2), ipr/sqrt(2), ppr_fr, qpr_fr] in JuMP.RotatedSecondOrderCone())
        @constraint(pm.model, wc == wf -2*(rc*ppr_fr + xc*qpr_fr) + (rc^2 + xc^2)*ipr)

    else
        PowerModels.con(pm, n, cnd, :conv_pr_p)[i] = @constraint(pm.model, ppr_fr + ppr_to == 0)
        PowerModels.con(pm, n, cnd, :conv_pr_q)[i] = @constraint(pm.model, qpr_fr + qpr_to == 0)
        @constraint(pm.model, wc == wf)
    end
end
"""
Links converter power & current
```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, Umax, Imax) where {T <: PowerModels.AbstractBFQPForm}
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)
    iconv_sq = PowerModels.var(pm, n, cnd, :iconv_ac_sq, i)

    PowerModels.con(pm, n, cnd, :conv_i)[i] = @constraint(pm.model,      pconv_ac^2 + qconv_ac^2 <=  wc * iconv_sq)
    PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @constraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (Umax)^2 * iconv^2)
    @constraint(pm.model, iconv^2 <= iconv_sq)
    @constraint(pm.model, iconv_sq <= iconv*Imax)
end

function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, Umax, Imax) where {T <: PowerModels.AbstractBFConicForm}
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)
    iconv_sq = PowerModels.var(pm, n, cnd, :iconv_ac_sq, i)

    # Normal form
    # PowerModels.con(pm, n, cnd, :conv_i)[i] = @constraint(pm.model, [2*pconv_ac, 2*qconv_ac,  wc - iconv_sq, wc + iconv_sq] in JuMP.RotatedSecondOrderCone())
    PowerModels.con(pm, n, cnd, :conv_i)[i] = @constraint(pm.model, [wc/sqrt(2), iconv_sq/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @constraint(pm.model, [Umax * iconv/sqrt(2), Umax * iconv/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    # PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @constraint(pm.model, norm([2*pconv_ac; 2*qconv_ac; Umax^2 - iconv_sq]) <= (Umax)^2 + iconv_sq)
    # @constraint(pm.model, [2*iconv, 1 - iconv_sq, 1 + iconv_sq] in JuMP.RotatedSecondOrderCone())
    # @constraint(pm.model, [iconv_sq, iconv/sqrt(2), iconv/sqrt(2)] in JuMP.SecondOrderCone())
    @constraint(pm.model, iconv_sq <= iconv*Imax)
end
