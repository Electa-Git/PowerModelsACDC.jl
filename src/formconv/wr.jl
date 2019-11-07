function constraint_voltage_product_converter(pm::AbstractWRModel, wr, wi, w_fr, w_to)
    InfrastructureModels.relaxation_complex_product(pm.model, w_fr, w_to, wr, wi)
#    @constraint(pm.model, (wrf)^2 + (wif)^2 <= w_fr*w_to)
end

function constraint_voltage_product_converter(pm::AbstractWRConicModel, wr, wi, w_fr, w_to)
    InfrastructureModels.relaxation_complex_product_conic(pm.model, w_fr, w_to, wr, wi)
#    @constraint(pm.model, (wrf)^2 + (wif)^2 <= w_fr*w_to)
end
"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::AbstractWRModel, n::Int, cnd::Int, i::Int, Umax, Imax)
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)
    iconv_sq = PowerModels.var(pm, n, cnd, :iconv_ac_sq, i)

    PowerModels.con(pm, n, cnd, :conv_i)[i] = @constraint(pm.model, pconv_ac^2 + qconv_ac^2 <= wc * iconv_sq)
    PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @constraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (Umax)^2 * iconv^2)
    @constraint(pm.model, iconv^2 <= iconv_sq)
    @constraint(pm.model, iconv_sq <= iconv*Imax)
end

function constraint_converter_current(pm::AbstractWRConicModel, n::Int, cnd::Int, i::Int, Umax, Imax)
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)
    iconv_sq = PowerModels.var(pm, n, cnd, :iconv_ac_sq, i)

    PowerModels.con(pm, n, cnd, :conv_i)[i]  = @constraint(pm.model, [wc/sqrt(2), iconv_sq/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @constraint(pm.model, [Umax * iconv/sqrt(2), Umax * iconv/sqrt(2), pconv_ac, qconv_ac] in JuMP.RotatedSecondOrderCone())
    # @constraint(pm.model, [iconv_sq/(2*sqrt(2)), iconv_sq/(2*sqrt(2)), iconv/sqrt(2), iconv/sqrt(2)] in JuMP.RotatedSecondOrderCone())
    @constraint(pm.model, iconv_sq <= iconv*Imax)
end
