function constraint_voltage_product_converter(pm::GenericPowerModel{T}, wr, wi, w_fr, w_to) where {T <: PowerModels.AbstractWRForm}
    InfrastructureModels.relaxation_complex_product(pm.model, w_fr, w_to, wr, wi)
#    @constraint(pm.model, (wrf)^2 + (wif)^2 <= w_fr*w_to)
end


"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, cnd::Int, i::Int, Umax, Imax) where {T <: PowerModels.AbstractWRForm}
    wc = PowerModels.var(pm, n, cnd, :wc_ac, i)
    pconv_ac = PowerModels.var(pm, n, cnd, :pconv_ac, i)
    qconv_ac = PowerModels.var(pm, n, cnd, :qconv_ac, i)
    iconv = PowerModels.var(pm, n, cnd, :iconv_ac, i)
    iconv_sq = PowerModels.var(pm, n, cnd, :iconv_ac_sq, i)

    PowerModels.con(pm, n, cnd, :conv_i)[i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= wc * iconv_sq)
    PowerModels.con(pm, n, cnd, :conv_i_sqrt)[i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (Umax)^2 * iconv^2)
    @NLconstraint(pm.model, iconv^2 <= iconv_sq)
    @constraint(pm.model, iconv_sq <= iconv*Imax)
end
