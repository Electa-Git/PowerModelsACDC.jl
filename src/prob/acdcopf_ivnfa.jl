# ============================================================================
# AC/DC OPF: IVR and hybrid AC-NFA / DC-IVR formulations
# ============================================================================
#
# Supported formulations:
#
# 1. Standard IVR:
#       AC network: IVR
#       DC network: IVR
#       Converter:  detailed IVR converter model
#
# 2. Hybrid AC-NFA / DC-IVR:
#       AC network: NFA
#       DC network: IVR
#       Converter:  hybrid AC-active-power / DC-IVR converter model
#
# The hybrid formulation can be selected in either of two ways:
#
#     solve_acdcopf_iv(
#         data,
#         ACNFAIVRPowerModel,
#         optimizer,
#     )
#
# or:
#
#     solve_acdcopf_iv(
#         data,
#         _PM.IVRPowerModel,
#         optimizer;
#         setting = Dict("ACNFA" => true),
#     )
#
# In the second case, the solve wrapper selects ACNFAIVRPowerModel before
# PowerModels constructs the internal `pm` object.
# ============================================================================


const _ACDCOPF_IV_REF_EXTENSIONS = [
    add_ref_dcgrid!,
    ref_add_pst!,
    ref_add_sssc!,
    ref_add_flex_load!,
    ref_add_gendc!,
]


# ============================================================================
# Formulation-selection helpers
# ============================================================================

"""
    _acnfa_requested(kwargs)

Return `true` when the settings supplied through `kwargs` request the hybrid
AC-NFA / DC-IVR formulation.

Both string and symbol setting keys are accepted:

    Dict("ACNFA" => true)

and:

    Dict(:ACNFA => true)
"""
function _acnfa_requested(kwargs)
    if !haskey(kwargs, :setting)
        return false
    end

    setting = kwargs[:setting]

    if setting === nothing
        return false
    end

    if haskey(setting, "ACNFA")
        return setting["ACNFA"] === true
    end

    if haskey(setting, :ACNFA)
        return setting[:ACNFA] === true
    end

    return false
end


"""
    _select_acdcopf_iv_model_type(model_type, kwargs)

Select the actual model type before `_PM.solve_model` constructs the internal
PowerModels model object.

When `"ACNFA" => true`, `ACNFAIVRPowerModel` is used irrespective of the
original IVR model type supplied by the caller.
"""
function _select_acdcopf_iv_model_type(model_type, kwargs)
    if _acnfa_requested(kwargs)
        return ACNFAIVRPowerModel
    end

    return model_type
end


"""
    _acdcopf_iv_solve_kwargs(kwargs)

Add the default PowerModelsACDC reference extensions unless the caller already
provided `ref_extensions`.

The resulting named tuple is splatted only once into `_PM.solve_model`, avoiding
duplicate `ref_extensions` keyword arguments between the file-based and
data-based entry points.
"""
function _acdcopf_iv_solve_kwargs(kwargs)
    user_kwargs = (; kwargs...)

    if haskey(user_kwargs, :ref_extensions)
        return user_kwargs
    end

    return merge(
        (
            ref_extensions = _ACDCOPF_IV_REF_EXTENSIONS,
        ),
        user_kwargs,
    )
end


# ============================================================================
# Solve entry points
# ============================================================================

"""
    solve_acdcopf_iv(file::String, model_type::Type, optimizer; kwargs...)

Solve an AC/DC Optimal Power Flow problem.

The formulation is selected as follows:

- Standard IVR formulation when an IVR model type is supplied and
  `"ACNFA"` is absent or false.
- Hybrid AC-NFA / DC-IVR formulation when
  `setting["ACNFA"] == true`.
- Hybrid formulation when `ACNFAIVRPowerModel` is supplied explicitly.

The input file is parsed and delegated to the data-based entry point.
"""
function solve_acdcopf_iv(
    file::String,
    model_type,
    optimizer;
    kwargs...,
)
    data = parse_file(file)

    return solve_acdcopf_iv(
        data,
        model_type,
        optimizer;
        kwargs...,
    )
end


"""
    solve_acdcopf_iv(
        data::Dict{String,Any},
        model_type::Type,
        optimizer;
        kwargs...,
    )

Data-based entry point for the IVR and hybrid AC-NFA / DC-IVR AC/DC OPF.

Dispatch is performed along two dimensions:

1. Formulation:
   - standard IVR;
   - hybrid AC-NFA / DC-IVR.

2. Network structure:
   - single-network;
   - multinetwork/multi-period.

The model type is selected before `_PM.solve_model` creates `pm`. Once `pm`
exists, Julia dispatches the selected builder method based on its concrete
formulation type.
"""
function solve_acdcopf_iv(
    data::Dict{String,Any},
    model_type::Type,
    optimizer;
    kwargs...,
)
    selected_model_type = _select_acdcopf_iv_model_type(
        model_type,
        kwargs,
    )

    solve_kwargs = _acdcopf_iv_solve_kwargs(kwargs)

    is_multinetwork =
        get(data, "multinetwork", false) === true

    if is_multinetwork
        return _PM.solve_model(
            data,
            selected_model_type,
            optimizer,
            mp_build_acdcopf_iv;
            solve_kwargs...,
        )
    end

    return _PM.solve_model(
        data,
        selected_model_type,
        optimizer,
        build_acdcopf_iv;
        solve_kwargs...,
    )
end


# ============================================================================
# Standard single-network AC-IVR / DC-IVR formulation
# ============================================================================

"""
    build_acdcopf_iv(pm::_PM.AbstractIVRModel)

Build a single-network AC/DC OPF using the IVR formulation for both the AC
and DC networks.

This is the existing detailed IVR formulation. Its behavior is intentionally
kept separate from the hybrid AC-NFA / DC-IVR formulation.
"""
function build_acdcopf_iv(pm::_PM.AbstractIVRModel)
    # ------------------------------------------------------------------------
    # Variables
    # ------------------------------------------------------------------------

    _PM.variable_bus_voltage(pm)
    _PM.variable_branch_current(pm)
    _PM.variable_storage_power(pm)
    _PM.variable_gen_current(pm)
    _PM.variable_dcline_current(pm)

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dcgrid_voltage_magnitude(pm)
    variable_dcgenerator_power(pm)
    variable_dc_converter(pm)

    variable_flexible_demand(pm)
    variable_load_current(pm)

    variable_pst(pm)
    variable_sssc(pm)

    # ------------------------------------------------------------------------
    # AC reference constraints
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    # ------------------------------------------------------------------------
    # AC current balance
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :bus)
        constraint_current_balance_ac(pm, i)
    end

    # ------------------------------------------------------------------------
    # AC branch constraints
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :branch)
        _PM.constraint_current_from(pm, i)
        _PM.constraint_current_to(pm, i)

        _PM.constraint_voltage_drop(pm, i)
        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    # ------------------------------------------------------------------------
    # Flexible and fixed demand
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :flex_load)
        constraint_total_flexible_demand(pm, i)
    end

    for i in _PM.ids(pm, :fixed_load)
        constraint_total_fixed_demand(pm, i)
    end

    # ------------------------------------------------------------------------
    # Unsupported special AC components
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :pst)
        @_warn("IVR formulation is not yet implemented for PSTs")
    end

    for i in _PM.ids(pm, :sssc)
        @_warn("IVR formulation is not yet implemented for SSSCs")
    end

    # ------------------------------------------------------------------------
    # DC network
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :busdc)
        constraint_current_balance_dc(pm, i)
    end

    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end

    # ------------------------------------------------------------------------
    # Detailed IVR converter formulation
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :convdc)
        constraint_converter_limits(pm, i)
        constraint_converter_losses(pm, i)
        constraint_converter_current(pm, i)

        constraint_conv_transformer(pm, i)
        constraint_conv_reactor(pm, i)
        constraint_conv_filter(pm, i)
    end

    # ------------------------------------------------------------------------
    # Optional fixed cross-border flows
    # ------------------------------------------------------------------------

    _add_fixed_cross_border_flow_constraints(pm)

    # ------------------------------------------------------------------------
    # Objective
    # ------------------------------------------------------------------------

    objective_min_operational_cost(pm)

    return nothing
end


# ============================================================================
# Hybrid single-network AC-NFA / DC-IVR formulation
# ============================================================================

"""
    build_acdcopf_iv(pm::AbstractACNFAIVRModel)

Build a single-network hybrid AC/DC OPF with:

- NFA active-power formulation on the AC network;
- IVR voltage-current formulation on the DC network;
- an aggregated AC-NFA / DC-IVR converter coupling.

The AC variable and branch-constraint functions are reused directly from
PowerModels. The DC variable and constraint functions are reused from
PowerModelsACDC.

Formulation-specific behavior is selected through the concrete type of `pm`.
"""
function build_acdcopf_iv(pm::AbstractACNFAIVRModel)
    # ------------------------------------------------------------------------
    # AC NFA variables
    #
    # These are generic PowerModels entry points. Their implementations are
    # selected through dispatch on AbstractACNFAIVRModel and its parent
    # AbstractActivePowerModel.
    # ------------------------------------------------------------------------

    _PM.variable_bus_voltage(pm)
    _PM.variable_gen_power(pm)
    _PM.variable_branch_power(pm)
    _PM.variable_dcline_power(pm)
    _PM.variable_storage_power(pm)

    # ------------------------------------------------------------------------
    # DC IVR variables
    # ------------------------------------------------------------------------

    variable_active_dcbranch_flow(pm)
    variable_dcbranch_current(pm)
    variable_dcgrid_voltage_magnitude(pm)
    variable_dcgenerator_power(pm)

    # ------------------------------------------------------------------------
    # Hybrid converter variables
    #
    # variable_dc_converter must provide at least:
    #
    # - AC-side active converter power;
    # - DC-side converter power/current;
    # - converter losses;
    # - any converter rating variables needed by the hybrid constraints.
    #
    # It may be reused directly if it already accepts the hybrid model type.
    # Otherwise, add a method:
    #
    #     variable_dc_converter(pm::AbstractACNFAIVRModel; ...)
    #
    # in the hybrid formulation file.
    # ------------------------------------------------------------------------

    variable_dc_converter(pm)

    # ------------------------------------------------------------------------
    # Flexible/fixed demand and optional devices
    # ------------------------------------------------------------------------

    variable_flexible_demand(pm)

    # NFA uses powers, not IVR load-current variables. Therefore,
    # variable_load_current(pm) is intentionally not called here.

    variable_pst(pm)
    variable_sssc(pm)

    # ------------------------------------------------------------------------
    # AC NFA model-level constraints
    # ------------------------------------------------------------------------

    _PM.constraint_model_voltage(pm)

    # A pure NFA model normally has no voltage-angle reference variable.
    # If the inherited implementation is a no-op, this loop is harmless.
    # If PowerModels provides no applicable method, remove this loop.
    for i in _PM.ids(pm, :ref_buses)
        _PM.constraint_theta_ref(pm, i)
    end

    # ------------------------------------------------------------------------
    # AC NFA power balance
    #
    # This must include PowerModelsACDC converter injections. The custom
    # constraint should reproduce the native NFA active-power balance and add
    # the AC-side converter active-power term.
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :bus)
        constraint_power_balance(pm, i)
    end

    # ------------------------------------------------------------------------
    # AC NFA branch constraints
    #
    # These generic calls reuse PowerModels' existing NFA implementation when
    # the methods are defined for AbstractActivePowerModel.
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :branch)
        _PM.constraint_ohms_yt_from(pm, i)
        _PM.constraint_ohms_yt_to(pm, i)

        _PM.constraint_voltage_angle_difference(pm, i)

        _PM.constraint_thermal_limit_from(pm, i)
        _PM.constraint_thermal_limit_to(pm, i)
    end

    # ------------------------------------------------------------------------
    # Native PowerModels DC-line components, if present
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :dcline)
        _PM.constraint_dcline_power_losses(pm, i)
    end

    # ------------------------------------------------------------------------
    # Flexible and fixed demand
    #
    # These functions need active-power methods for AbstractACNFAIVRModel.
    # They must not expect IVR load-current variables.
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :flex_load)
        constraint_total_flexible_demand(pm, i)
    end

    for i in _PM.ids(pm, :fixed_load)
        constraint_total_fixed_demand(pm, i)
    end

    # ------------------------------------------------------------------------
    # PST and SSSC
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :pst)
        @_warn(
            "PSTs are not yet implemented for the hybrid " *
            "AC-NFA / DC-IVR formulation",
        )
    end

    for i in _PM.ids(pm, :sssc)
        @_warn(
            "SSSCs are not yet implemented for the hybrid " *
            "AC-NFA / DC-IVR formulation",
        )
    end

    # ------------------------------------------------------------------------
    # DC IVR network
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :branchdc)
        constraint_ohms_dc_branch(pm, i)
    end

    # ------------------------------------------------------------------------
    # Hybrid converter constraints
    #
    # This replaces the detailed AC-side IVR transformer/reactor/filter
    # constraints, because NFA has no AC voltage or AC current variables.
    # ------------------------------------------------------------------------

    for i in _PM.ids(pm, :convdc)
        constraint_converter_limits(pm, i)

        constraint_converter_acnfa_ivrdc(pm, i)
    end

    # DC-bus current balance is added after converter constraints so all
    # converter-current variables and expressions already exist.
    for i in _PM.ids(pm, :busdc)
        constraint_current_balance_dc(pm, i)
    end

    # ------------------------------------------------------------------------
    # Optional fixed cross-border flows
    # ------------------------------------------------------------------------

    _add_fixed_cross_border_flow_constraints(pm)

    # ------------------------------------------------------------------------
    # Objective
    # ------------------------------------------------------------------------

    objective_min_operational_cost(pm)

    return nothing
end


# ============================================================================
# Standard multinetwork AC-IVR / DC-IVR formulation
# ============================================================================

"""
    mp_build_acdcopf_iv(pm::_PM.AbstractIVRModel)

Build a multinetwork/multi-period AC/DC OPF using IVR on both the AC and DC
networks.
"""
function mp_build_acdcopf_iv(pm::_PM.AbstractIVRModel)
    # ------------------------------------------------------------------------
    # Variables
    # ------------------------------------------------------------------------

    for n in _PM.nw_ids(pm)
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_branch_current(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)
        _PM.variable_gen_current(pm; nw = n)
        _PM.variable_dcline_current(pm; nw = n)

        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_dcgenerator_power(pm; nw = n)
        variable_dc_converter(pm; nw = n)

        variable_flexible_demand(pm; nw = n)
        variable_load_current(pm; nw = n)

        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)

        add_additional_variables(pm; nw = n)
    end

    # ------------------------------------------------------------------------
    # Per-network constraints
    # ------------------------------------------------------------------------

    for n in _PM.nw_ids(pm)
        _PM.constraint_model_voltage(pm; nw = n)

        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :bus)
            constraint_current_balance_ac(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branch)
            _PM.constraint_current_from(pm, i; nw = n)
            _PM.constraint_current_to(pm, i; nw = n)

            _PM.constraint_voltage_drop(pm, i; nw = n)
            _PM.constraint_voltage_angle_difference(pm, i; nw = n)

            _PM.constraint_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_thermal_limit_to(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :flex_load)
            constraint_total_flexible_demand(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :fixed_load)
            constraint_total_fixed_demand(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :pst)
            @_warn(
                "IVR formulation is not yet implemented for PSTs " *
                "(nw = $n)",
            )
        end

        for i in _PM.ids(pm, n, :sssc)
            @_warn(
                "IVR formulation is not yet implemented for SSSCs " *
                "(nw = $n)",
            )
        end

        for i in _PM.ids(pm, n, :busdc)
            constraint_current_balance_dc(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :branchdc)
            constraint_ohms_dc_branch(pm, i; nw = n)

            branchdc = _PM.ref(pm, n, :branchdc, i)

            if get(branchdc, "dcr", 0) == 1
                constraint_dynamic_cable_rating(pm, i; nw = n)
            end
        end

        for i in _PM.ids(pm, n, :convdc)
            constraint_converter_limits(pm, i; nw = n)
            constraint_converter_losses(pm, i; nw = n)
            constraint_converter_current(pm, i; nw = n)

            constraint_conv_transformer(pm, i; nw = n)
            constraint_conv_reactor(pm, i; nw = n)
            constraint_conv_filter(pm, i; nw = n)
        end

        _add_fixed_cross_border_flow_constraints(pm; nw = n)
    end

    # ------------------------------------------------------------------------
    # Global multi-period objective
    # ------------------------------------------------------------------------

    objective_min_operational_cost(pm)

    return nothing
end


# ============================================================================
# Hybrid multinetwork AC-NFA / DC-IVR formulation
# ============================================================================

"""
    mp_build_acdcopf_iv(pm::AbstractACNFAIVRModel)

Build a multinetwork/multi-period AC/DC OPF with:

- NFA for each AC network/time period;
- IVR for each DC network/time period;
- hybrid converter coupling in every network/time period.

All variables and constraints are created with an explicit `nw` argument.
"""
function mp_build_acdcopf_iv(pm::AbstractACNFAIVRModel)
    # ------------------------------------------------------------------------
    # Per-network variables
    # ------------------------------------------------------------------------

    for n in _PM.nw_ids(pm)
        # AC NFA variables
        _PM.variable_bus_voltage(pm; nw = n)
        _PM.variable_gen_power(pm; nw = n)
        _PM.variable_branch_power(pm; nw = n)
        _PM.variable_dcline_power(pm; nw = n)
        _PM.variable_storage_power(pm; nw = n)

        # DC IVR variables
        variable_active_dcbranch_flow(pm; nw = n)
        variable_dcbranch_current(pm; nw = n)
        variable_dcgrid_voltage_magnitude(pm; nw = n)
        variable_dcgenerator_power(pm; nw = n)

        # Hybrid converter variables
        variable_dc_converter(pm; nw = n)

        # Flexible demand and special components
        variable_flexible_demand(pm; nw = n)

        # No variable_load_current call: NFA uses active powers.
        variable_pst(pm; nw = n)
        variable_sssc(pm; nw = n)

        # DCR temperature variables
        add_additional_variables(pm; nw = n)
    end

    # ------------------------------------------------------------------------
    # Per-network constraints
    # ------------------------------------------------------------------------

    for n in _PM.nw_ids(pm)
        # AC NFA model-level setup
        _PM.constraint_model_voltage(pm; nw = n)

        for i in _PM.ids(pm, n, :ref_buses)
            _PM.constraint_theta_ref(pm, i; nw = n)
        end

        # AC NFA power balance including converters
        for i in _PM.ids(pm, n, :bus)
            constraint_power_balance(pm, i; nw = n)
        end

        # AC NFA branch constraints
        for i in _PM.ids(pm, n, :branch)
            _PM.constraint_ohms_yt_from(pm, i; nw = n)
            _PM.constraint_ohms_yt_to(pm, i; nw = n)

            _PM.constraint_voltage_angle_difference(pm, i; nw = n)

            _PM.constraint_thermal_limit_from(pm, i; nw = n)
            _PM.constraint_thermal_limit_to(pm, i; nw = n)
        end

        # Native PowerModels dcline constraints
        for i in _PM.ids(pm, n, :dcline)
            _PM.constraint_dcline_power_losses(pm, i; nw = n)
        end

        # Flexible and fixed demand
        for i in _PM.ids(pm, n, :flex_load)
            constraint_total_flexible_demand(pm, i; nw = n)
        end

        for i in _PM.ids(pm, n, :fixed_load)
            constraint_total_fixed_demand(pm, i; nw = n)
        end

        # Unsupported special AC devices
        for i in _PM.ids(pm, n, :pst)
            @_warn(
                "PSTs are not yet implemented for the hybrid " *
                "AC-NFA / DC-IVR formulation (nw = $n)",
            )
        end

        for i in _PM.ids(pm, n, :sssc)
            @_warn(
                "SSSCs are not yet implemented for the hybrid " *
                "AC-NFA / DC-IVR formulation (nw = $n)",
            )
        end

        # DC IVR branch constraints
        for i in _PM.ids(pm, n, :branchdc)
            constraint_ohms_dc_branch(pm, i; nw = n)

            branchdc = _PM.ref(pm, n, :branchdc, i)

            if get(branchdc, "dcr", 0) == 1
                constraint_dynamic_cable_rating(pm, i; nw = n)
            end
        end

        # Hybrid converter constraints
        for i in _PM.ids(pm, n, :convdc)
            constraint_converter_limits(pm, i; nw = n)

            constraint_converter_acnfa_ivrdc(pm, i; nw = n,
            )
        end

        # DC nodal current balance
        for i in _PM.ids(pm, n, :busdc)
            constraint_current_balance_dc(pm, i; nw = n)
        end

        # Optional fixed cross-border flows
        _add_fixed_cross_border_flow_constraints(pm; nw = n)
    end

    # ------------------------------------------------------------------------
    # Global multi-period objective
    # ------------------------------------------------------------------------

    objective_min_operational_cost(pm)

    return nothing
end


# ============================================================================
# Shared cross-border-flow helper
# ============================================================================

"""
    _add_fixed_cross_border_flow_constraints(
        pm;
        nw = _PM.nw_id_default,
    )

Add fixed cross-border-flow constraints for one network when requested.

This helper also fixes the scope issue in the original multinetwork builder,
where `n` was referenced outside the network loop.
"""
function _add_fixed_cross_border_flow_constraints(
    pm;
    nw::Int = _PM.nw_id_default,
)
    if !get(pm.setting, "fix_cross_border_flows", false)
        return nothing
    end

    borders = if haskey(pm.setting, "borders")
        collect(pm.setting["borders"])
    else
        collect(_PM.ids(pm, nw, :borders))
    end

    for i in borders
        constraint_fixed_xb_flows(pm, i; nw = nw)
    end

    return nothing
end


# ============================================================================
# Dynamic cable-rating variables
# ============================================================================

"""
    add_additional_variables(
        pm;
        nw = _PM.nw_id_default,
    )

Create temperature variables for DC branches with dynamic cable rating enabled.
"""
function add_additional_variables(
    pm;
    nw::Int = _PM.nw_id_default,
)
    dc_branch_ids = Int[]

    for i in _PM.ids(pm, nw, :branchdc)
        branchdc = _PM.ref(pm, nw, :branchdc, i)

        if get(branchdc, "dcr", 0) == 1
            push!(dc_branch_ids, i)
        end
    end

    if !isempty(dc_branch_ids)
        variable_dcbranch_temperature(
            pm,
            dc_branch_ids;
            nw = nw,
        )
    end

    return nothing
end