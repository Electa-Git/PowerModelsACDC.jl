"do nothing, this model does not have complex voltage constraints"
function constraint_voltage_dc(pm::_PM.AbstractPowerModel,  n::Int)
end

"""
```
sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == pd
```
"""
function constraint_kcl_shunt_dcgrid(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid, bus_convs_dc, pd)
    p_dcgrid = _PM.var(pm, n, :p_dcgrid)
    pconv_dc = _PM.var(pm, n, :pconv_dc)

    # _PM.con(pm, n, :kcl_dcgrid)[i] = JuMP.JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == (-pd))
    JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(pconv_dc[c] for c in bus_convs_dc) == (-pd))
end

"`pconv[i] == pconv`"
function constraint_active_conv_setpoint(pm::_PM.AbstractPowerModel, n::Int, i, pconv)
    pconv_var = _PM.var(pm, n, :pconv_tf_fr, i)
    # _PM.con(pm, n, :conv_pac)[i] = JuMP.JuMP.@constraint(pm.model, pconv_var == -pconv)
    JuMP.@constraint(pm.model, pconv_var == -pconv)
end

"`qconv[i] == qconv`"
function constraint_reactive_conv_setpoint(pm::_PM.AbstractPowerModel, n::Int, i, qconv)
    qconv_var = _PM.var(pm, n, :qconv_tf_fr, i)
    # _PM.con(pm, n, :conv_qac)[i] = JuMP.JuMP.@constraint(pm.model, qconv_var == -qconv)
    JuMP.@constraint(pm.model, qconv_var == -qconv)
end


###################### TNEP Constraints ############################
function constraint_voltage_dc_ne(pm::_PM.AbstractPowerModel,  n::Int)
end
# function constraint_voltage_dc_ne_bus(pm::_PM.AbstractPowerModel,  n::Int)
# end

function constraint_converter_limit_on_off(pm::_PM.AbstractDCPModel, n::Int, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
    #display(pm)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne)[i]
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne)[i]
    pconv_tf_fr = _PM.var(pm, n, :pconv_tf_fr_ne)[i]
    pconv_tf_to = _PM.var(pm, n, :pconv_tf_to_ne)[i]
    pconv_pr_fr = _PM.var(pm, n, :pconv_pr_fr_ne)[i]
    z = _PM.var(pm, n, :conv_ne)[i]
    #big M is ignored here
    JuMP.@constraint(pm.model,  pconv_ac <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_ac >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_dc <= pmaxdc * z)
    JuMP.@constraint(pm.model,  pconv_dc >= pmindc * z)
    JuMP.@constraint(pm.model,  pconv_tf_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_fr >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_tf_to <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_to >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_pr_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_pr_fr >= pmin * z)

end

function constraint_converter_limit_on_off(pm::_PM.AbstractACPModel, n::Int, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne)[i]
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne)[i]
    pconv_tf_fr = _PM.var(pm, n, :pconv_tf_fr_ne)[i]
    pconv_tf_to = _PM.var(pm, n, :pconv_tf_to_ne)[i]
    pconv_pr_fr = _PM.var(pm, n, :pconv_pr_fr_ne)[i]

    qconv_ac = _PM.var(pm, n, :qconv_ac_ne)[i]
    qconv_tf_fr = _PM.var(pm, n, :qconv_tf_fr_ne)[i]
    qconv_tf_to = _PM.var(pm, n, :qconv_tf_to_ne)[i]
    qconv_pr_fr = _PM.var(pm, n, :qconv_pr_fr_ne)[i]
    iconv_ac = _PM.var(pm, n, :iconv_ac_ne)[i]
    vmc = _PM.var(pm, n, :vmc_ne, i)
    vmf = _PM.var(pm, n, :vmf_ne, i)

    z = _PM.var(pm, n, :conv_ne)[i]

    JuMP.@constraint(pm.model,  pconv_ac <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_ac >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_dc <= pmaxdc * z)
    JuMP.@constraint(pm.model,  pconv_dc >= pmindc * z)
    JuMP.@constraint(pm.model,  pconv_tf_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_fr >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_tf_to <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_to >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_pr_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_pr_fr >= pmin * z)
    #
    JuMP.@constraint(pm.model,  qconv_ac <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_ac >= qmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr >= qmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_to <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_to >= qmin * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr >= qmin * z)
    JuMP.@constraint(pm.model,  iconv_ac <= imax * z )

end


function constraint_converter_limit_on_off(pm::_PM.AbstractBFModel, n::Int, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
    #converter
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne)[i]
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne)[i]
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne)[i]
    iconv_ac = _PM.var(pm, n, :iconv_ac_ne)[i]
    iconv_sq = _PM.var(pm, n, :iconv_ac_sq_ne)[i]
    z = _PM.var(pm, n, :conv_ne)[i]
    JuMP.@constraint(pm.model,  pconv_ac <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_ac >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_dc <= pmaxdc * z)
    JuMP.@constraint(pm.model,  pconv_dc >= pmindc * z)
    JuMP.@constraint(pm.model,  qconv_ac <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_ac >= qmin * z)
    JuMP.@constraint(pm.model,  iconv_ac <= imax * z)
    JuMP.@constraint(pm.model,  iconv_sq <= imax^2 * z)
    #transformer
    conv = PowerModels.ref(pm, n, :convdc_ne, i)
    busac_conv = PowerModels.ref(pm, n, :bus, conv["busac_i"]) #can be passed through constriant_template
    w_du = _PM.var(pm, n, :w_du, i) #can be passed through constraint_template. see df.jl constraint for transformer

    pconv_tf_fr = _PM.var(pm, n, :pconv_tf_fr_ne)[i]
    pconv_tf_to = _PM.var(pm, n, :pconv_tf_to_ne)[i]
    qconv_tf_fr = _PM.var(pm, n, :qconv_tf_fr_ne)[i]
    qconv_tf_to = _PM.var(pm, n, :qconv_tf_to_ne)[i]
    itf = _PM.var(pm, n, :itf_sq_ne, i)
    JuMP.@constraint(pm.model,  pconv_tf_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_fr >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_tf_to <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_to >= pmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr >= qmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_to <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_to >= qmin * z)
    bigM = 2;
    JuMP.@constraint(pm.model,  itf <= (bigM*imax)^2 * z) #big M = 2

    #filter

    #reactor
    pconv_pr_fr = _PM.var(pm, n, :pconv_pr_fr_ne)[i]
    qconv_pr_fr = _PM.var(pm, n, :qconv_pr_fr_ne)[i]
    ipr = _PM.var(pm, n, :irc_sq_ne, i)
    wc = _PM.var(pm, n , :wc_ac_ne,i)
    JuMP.@constraint(pm.model,  pconv_pr_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_pr_fr >= pmin * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr >= qmin * z)
    bigM = 2;
    JuMP.@constraint(pm.model,  ipr <= (bigM * imax)^2 * z) #big M = 2
end


function constraint_converter_limit_on_off(pm::_PM.AbstractWModels, n::Int, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
    #converter
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne)[i]
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne)[i]
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne)[i]
    iconv_ac = _PM.var(pm, n, :iconv_ac_ne)[i]
    iconv_sq = _PM.var(pm, n, :iconv_ac_sq_ne)[i]
    z = _PM.var(pm, n, :conv_ne)[i]
    JuMP.@constraint(pm.model,  pconv_ac <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_ac >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_dc <= pmaxdc * z)
    JuMP.@constraint(pm.model,  pconv_dc >= pmindc * z)
    JuMP.@constraint(pm.model,  qconv_ac <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_ac >= qmin * z)
    JuMP.@constraint(pm.model,  iconv_ac <= imax * z)
    JuMP.@constraint(pm.model,  iconv_sq <= imax^2 * z)

    # transformer
    pconv_tf_fr = _PM.var(pm, n, :pconv_tf_fr_ne)[i]
    pconv_tf_to = _PM.var(pm, n, :pconv_tf_to_ne)[i]
    qconv_tf_fr = _PM.var(pm, n, :qconv_tf_fr_ne)[i]
    qconv_tf_to = _PM.var(pm, n, :qconv_tf_to_ne)[i]
    JuMP.@constraint(pm.model,  pconv_tf_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_fr >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_tf_to <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_to >= pmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr >= qmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_to <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_to >= qmin * z)
    #filter
    #reactor?
    pconv_pr_fr = _PM.var(pm, n, :pconv_pr_fr_ne)[i]
    qconv_pr_fr = _PM.var(pm, n, :qconv_pr_fr_ne)[i]
    JuMP.@constraint(pm.model,  pconv_pr_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_pr_fr >= pmin * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr >= qmin * z)
end


function constraint_converter_limit_on_off(pm::_PM.AbstractWRMModel, n::Int, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
    #converter
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne)[i]
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne)[i]
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne)[i]
    iconv_ac = _PM.var(pm, n, :iconv_ac_ne)[i]
    iconv_sq = _PM.var(pm, n, :iconv_ac_sq_ne)[i]
    z = _PM.var(pm, n, :conv_ne)[i]
    JuMP.@constraint(pm.model,  pconv_ac <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_ac >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_dc <= pmaxdc * z)
    JuMP.@constraint(pm.model,  pconv_dc >= pmindc * z)
    JuMP.@constraint(pm.model,  qconv_ac <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_ac >= qmin * z)
    JuMP.@constraint(pm.model,  iconv_ac <= imax * z)
    JuMP.@constraint(pm.model,  iconv_sq <= imax^2 * z)

    # transformer
    pconv_tf_fr = _PM.var(pm, n, :pconv_tf_fr_ne)[i]
    pconv_tf_to = _PM.var(pm, n, :pconv_tf_to_ne)[i]
    qconv_tf_fr = _PM.var(pm, n, :qconv_tf_fr_ne)[i]
    qconv_tf_to = _PM.var(pm, n, :qconv_tf_to_ne)[i]
    JuMP.@constraint(pm.model,  pconv_tf_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_fr >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_tf_to <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_to >= pmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr >= qmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_to <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_to >= qmin * z)
    #filter
    #reactor?
    pconv_pr_fr = _PM.var(pm, n, :pconv_pr_fr_ne)[i]
    qconv_pr_fr = _PM.var(pm, n, :qconv_pr_fr_ne)[i]
    JuMP.@constraint(pm.model,  pconv_pr_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_pr_fr >= pmin * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr >= qmin * z)
end

function constraint_converter_limit_on_off(pm::_PM.AbstractLPACModel, n::Int, i, pmax, pmin, qmax, qmin, pmaxdc, pmindc, imax)
    #converter
    pconv_ac = _PM.var(pm, n, :pconv_ac_ne)[i]
    pconv_dc = _PM.var(pm, n, :pconv_dc_ne)[i]
    qconv_ac = _PM.var(pm, n, :qconv_ac_ne)[i]
    iconv_ac = _PM.var(pm, n, :iconv_ac_ne)[i]
    z = _PM.var(pm, n, :conv_ne)[i]
    JuMP.@constraint(pm.model,  pconv_ac <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_ac >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_dc <= pmaxdc * z)
    JuMP.@constraint(pm.model,  pconv_dc >= pmindc * z)
    JuMP.@constraint(pm.model,  qconv_ac <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_ac >= qmin * z)
    JuMP.@constraint(pm.model,  iconv_ac <= imax * z) #used

    # transformer
    pconv_tf_fr = _PM.var(pm, n, :pconv_tf_fr_ne)[i]
    pconv_tf_to = _PM.var(pm, n, :pconv_tf_to_ne)[i]
    qconv_tf_fr = _PM.var(pm, n, :qconv_tf_fr_ne)[i]
    qconv_tf_to = _PM.var(pm, n, :qconv_tf_to_ne)[i]
    JuMP.@constraint(pm.model,  pconv_tf_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_fr >= pmin * z)
    JuMP.@constraint(pm.model,  pconv_tf_to <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_tf_to >= pmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_fr >= qmin * z)
    JuMP.@constraint(pm.model,  qconv_tf_to <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_tf_to >= qmin * z)
    #filter
    #reactor?
    pconv_pr_fr = _PM.var(pm, n, :pconv_pr_fr_ne)[i]
    qconv_pr_fr = _PM.var(pm, n, :qconv_pr_fr_ne)[i]
    JuMP.@constraint(pm.model,  pconv_pr_fr <= pmax * z)
    JuMP.@constraint(pm.model,  pconv_pr_fr >= pmin * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr <= qmax * z)
    JuMP.@constraint(pm.model,  qconv_pr_fr >= qmin * z)
end


function constraint_branch_limit_on_off(pm::_PM.AbstractBFModel, n::Int, i, f_idx, t_idx, pmax, pmin, imax, imin)
    p_fr = _PM.var(pm, n, :p_dcgrid_ne)[f_idx]
    p_to = _PM.var(pm, n, :p_dcgrid_ne)[t_idx]
    z = _PM.var(pm, n, :branch_ne)[i]
    ccm_dcgrid = _PM.var(pm, n, :ccm_dcgrid_ne, i)
    # PowerModels.con(pm, n, :brdc_ne_pmaxfr)[i] = JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    # PowerModels.con(pm, n, :brdc_ne_pminfr)[i] = JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    # PowerModels.con(pm, n, :brdc_ne_pmaxto)[i] = JuMP.@constraint(pm.model,  p_to <= pmax * z)
    # PowerModels.con(pm, n, :brdc_ne_pminto)[i] = JuMP.@constraint(pm.model,  p_to >= pmin * z)
    JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    JuMP.@constraint(pm.model,  p_to <= pmax * z)
    JuMP.@constraint(pm.model,  p_to >= pmin * z)
    JuMP.@constraint(pm.model,  ccm_dcgrid <= imax^2 * z)
    JuMP.@constraint(pm.model,  ccm_dcgrid >= imin^2 * z)

    #wdc_ne_to, wdc_ne_fr, wdc_to, wdc_fr = votlage_old_or_new_bus(pm::_PM.AbstractPowerModel, n::Int, z, t_idx[2], f_idx[2], wdc_ne_to, wdc_ne_fr, wdc_to, wdc_fr)
end
function constraint_branch_limit_on_off(pm::_PM.AbstractWRModels, n::Int, i, f_idx, t_idx, pmax, pmin, imax, imin)
    p_fr = _PM.var(pm, n, :p_dcgrid_ne)[f_idx]
    p_to = _PM.var(pm, n, :p_dcgrid_ne)[t_idx]
    z = _PM.var(pm, n, :branch_ne)[i]
    # ccm_dcgrid = _PM.var(pm, n, :ccm_dcgrid_ne, i)
    # PowerModels.con(pm, n, :brdc_ne_pmaxfr)[i] = JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    # PowerModels.con(pm, n, :brdc_ne_pminfr)[i] = JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    # PowerModels.con(pm, n, :brdc_ne_pmaxto)[i] = JuMP.@constraint(pm.model,  p_to <= pmax * z)
    # PowerModels.con(pm, n, :brdc_ne_pminto)[i] = JuMP.@constraint(pm.model,  p_to >= pmin * z)
    # JuMP.@constraint(pm.model,  ccm_dcgrid <= imax^2 * z)
    # JuMP.@constraint(pm.model,  ccm_dcgrid >= imin^2 * z)

    #wdc_ne_to, wdc_ne_fr, wdc_to, wdc_fr = votlage_old_or_new_bus(pm::_PM.AbstractPowerModel, n::Int, z, t_idx[2], f_idx[2], wdc_ne_to, wdc_ne_fr, wdc_to, wdc_fr)
    JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    JuMP.@constraint(pm.model,  p_to <= pmax * z)
    JuMP.@constraint(pm.model,  p_to >= pmin * z)
end

function constraint_branch_limit_on_off(pm::_PM.AbstractPowerModel, n::Int, i, f_idx, t_idx, pmax, pmin, imax, imin)
    p_fr = _PM.var(pm, n, :p_dcgrid_ne)[f_idx]
    p_to = _PM.var(pm, n, :p_dcgrid_ne)[t_idx]
    z = _PM.var(pm, n, :branch_ne)[i]
    # PowerModels.con(pm, n, :brdc_ne_pmaxfr)[i] = JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    # PowerModels.con(pm, n, :brdc_ne_pminfr)[i] = JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    # PowerModels.con(pm, n, :brdc_ne_pmaxto)[i] = JuMP.@constraint(pm.model,  p_to <= pmax * z)
    # PowerModels.con(pm, n, :brdc_ne_pminto)[i] = JuMP.@constraint(pm.model,  p_to >= pmin * z)
    JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    JuMP.@constraint(pm.model,  p_to <= pmax * z)
    JuMP.@constraint(pm.model,  p_to >= pmin * z)
end

function constraint_branch_limit_on_off(pm::_PM.AbstractACPModel, n::Int, i, f_idx, t_idx, pmax, pmin, imax, imin)
    p_fr = _PM.var(pm, n, :p_dcgrid_ne)[f_idx]
    p_to = _PM.var(pm, n, :p_dcgrid_ne)[t_idx]
    z = _PM.var(pm, n, :branch_ne)[i]
    # PowerModels.con(pm, n, :brdc_ne_pmaxfr)[i] = JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    # PowerModels.con(pm, n, :brdc_ne_pminfr)[i] = JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    # PowerModels.con(pm, n, :brdc_ne_pmaxto)[i] = JuMP.@constraint(pm.model,  p_to <= pmax * z)
    # PowerModels.con(pm, n, :brdc_ne_pminto)[i] = JuMP.@constraint(pm.model,  p_to >= pmin * z)
    JuMP.@constraint(pm.model,  p_fr <= pmax * z)
    JuMP.@constraint(pm.model,  p_fr >= pmin * z)
    JuMP.@constraint(pm.model,  p_to <= pmax * z)
    JuMP.@constraint(pm.model,  p_to >= pmin * z)
end


function constraint_candidate_converters_mp(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    z = _PM.var(pm, n, :conv_ne, i)
    z_1 = _PM.var(pm, n-1, :conv_ne, i)

    JuMP.@constraint(pm.model,  z == z_1)
end

function constraint_candidate_branches_mp(pm::_PM.AbstractPowerModel, n::Int, i::Int)
    z = _PM.var(pm, n, :branch_ne, i)
    z_1 = _PM.var(pm, n-1, :branch_ne, i)

    JuMP.@constraint(pm.model,  z == z_1)
end

function constraint_kcl_shunt_dcgrid_ne(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid, bus_arcs_dcgrid_ne, bus_convs_dc, bus_convs_dc_ne, pd)
    p_dcgrid = _PM.var(pm, n, :p_dcgrid)
    p_dcgrid_ne = _PM.var(pm, n, :p_dcgrid_ne)
    pconv_dc = _PM.var(pm, n, :pconv_dc)
    pconv_dc_ne = _PM.var(pm, n, :pconv_dc_ne)

#     PowerModels.con(pm, n, :kcl_dcgrid)[i] = JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc[c] for c in bus_convs_dc) + sum(pconv_dc_ne[c] for c in bus_convs_dc_ne)  == (-pd))
    JuMP.@constraint(pm.model, sum(p_dcgrid[a] for a in bus_arcs_dcgrid) + sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc[c] for c in bus_convs_dc) + sum(pconv_dc_ne[c] for c in bus_convs_dc_ne)  == (-pd))
end


function constraint_kcl_shunt_dcgrid_ne_bus(pm::_PM.AbstractPowerModel, n::Int, i::Int, bus_arcs_dcgrid_ne, bus_ne_convs_dc_ne, pd_ne)
    p_dcgrid_ne = _PM.var(pm, n, :p_dcgrid_ne)
    pconv_dc_ne = _PM.var(pm, n, :pconv_dc_ne)
    xb = _PM.var(pm, n, :branch_ne)
    xc = _PM.var(pm, n, :conv_ne)
    # JuMP.@constraint(pm.model, sum(xb[i] for (i,j,k) in bus_arcs_dcgrid_ne) >= sum(xc[c] for c in bus_ne_convs_dc_ne) )
    # display(bus_ne_convs_dc_ne)
    # PowerModels.con(pm, n, :kcl_dcgrid_ne)[i] = JuMP.@constraint(pm.model, sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc_ne[c] for c in bus_ne_convs_dc_ne)  == (-pd_ne))
    # if DC bus is built, there is no existing dc branch (p_dcgrid) or dc conv (p_conv_dc) present, just new converter and new dc branch power connected to new dc bus
    JuMP.@constraint(pm.model, sum(p_dcgrid_ne[a] for a in bus_arcs_dcgrid_ne) + sum(pconv_dc_ne[c] for c in bus_ne_convs_dc_ne)  == (-pd_ne))
end
