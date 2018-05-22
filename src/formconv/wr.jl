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
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, Umax) where {T <: PowerModels.AbstractWRForm}
    wc = pm.var[:nw][n][:wc_ac][i]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]
    pm.con[:nw][n][:conv_i][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= wc * iconv_sq)
    pm.con[:nw][n][:conv_i_sqrt][i] = @NLconstraint(pm.model, pconv_ac^2 + qconv_ac^2 <= (Umax)^2 * iconv^2)
    @NLconstraint(pm.model, iconv^2 <= iconv_sq)
end
