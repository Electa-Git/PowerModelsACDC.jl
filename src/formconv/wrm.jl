function constraint_voltage_product_converter(pm::GenericPowerModel{T}, wr, wi, w_fr, w_to) where {T <: PowerModels.AbstractWRMForm}
    @constraint(pm.model, norm([ 2*wr;  2*wi; w_fr-w_to ]) <= w_fr+w_to )
end

"""
Links converter power & current

```
pconv_ac[i]^2 + pconv_dc[i]^2 <= wc[i] * iconv_ac_sq[i]
pconv_ac[i]^2 + pconv_dc[i]^2 <= (Umax)^2 * (iconv_ac[i])^2
```
"""
function constraint_converter_current(pm::GenericPowerModel{T}, n::Int, i::Int, Umax, Imax) where {T <: PowerModels.AbstractWRMForm}
    wc = pm.var[:nw][n][:wc_ac][i]
    pconv_ac = pm.var[:nw][n][:pconv_ac][i]
    qconv_ac = pm.var[:nw][n][:qconv_ac][i]
    iconv_sq = pm.var[:nw][n][:iconv_ac_sq][i]
    iconv = pm.var[:nw][n][:iconv_ac][i]
    pm.con[:nw][n][:conv_i][i] = @constraint(pm.model, norm([2pconv_ac;2qconv_ac; (wc-iconv_sq)]) <= (wc+iconv_sq))
    pm.con[:nw][n][:conv_i_sqrt][i] = @constraint(pm.model, norm([2*pconv_ac; 2*qconv_ac]) <= 2*Umax*iconv)
    #pm.con[:nw][n][:conv_i_sqrt][i] = @constraint(pm.model, norm([2*pconv_ac;2*qconv_ac; Umax*iconv-1]) <= Umax*iconv+1)
    @constraint(pm.model, norm([2*iconv; iconv_sq-1]) <= iconv_sq + 1)
    @constraint(pm.model, iconv_sq <= iconv*Imax)
end
