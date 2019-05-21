function constraint_voltage_product_converter(pm::GenericPowerModel{T}, wr, wi, w_fr, w_to) where {T <: PowerModels.AbstractWRMForm}
    # # @constraint(pm.model, norm([ 2*wr;  2*wi; w_fr-w_to ]) <= w_fr+w_to )
    # @constraint(pm.model, [ 2*wr,  2*wi, w_fr-w_to, w_fr+w_to] in JuMP.RotatedSecondOrderCone())
    @constraint(pm.model, [w_fr/sqrt(2), w_to/sqrt(2), wr, wi] in JuMP.RotatedSecondOrderCone())
end

"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, Umax, Imax) where {T <: PowerModels.AbstractWRMForm}
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)
    iconv_sq = PowerModels.var(pm, n, cnd, :iconv_ac_sq, i)

    # PowerModels.con(pm, n, cnd, :conv_i)[i]  = @constraint(pm.model, norm([2pconv_ac;2qconv_ac; (wc-iconv_sq)]) <= (wc+iconv_sq))
    # PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @constraint(pm.model, norm([2*pconv_ac; 2*qconv_ac]) <= 2*Umax*iconv)
    # @constraint(pm.model, norm([2*iconv; iconv_sq-1]) <= iconv_sq + 1)

    PowerModels.con(pm, n, cnd, :conv_i)[i]  = @constraint(pm.model, [wc/sqrt(2), iconv_sq/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @constraint(pm.model, [Umax * iconv/sqrt(2), Umax * iconv/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    # @constraint(pm.model, [iconv_sq/(2*sqrt(2)), iconv_sq/(2*sqrt(2)), iconv/sqrt(2), iconv/sqrt(2)] in JuMP.RotatedSecondOrderCone())
    @constraint(pm.model, iconv_sq <= iconv*Imax)
end
