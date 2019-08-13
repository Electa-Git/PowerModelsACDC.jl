"constraint: `c^2 + d^2 <= a*b`"
function relaxation_complex_product_conic(m::JuMP.Model, a::JuMP.VariableRef, b::JuMP.VariableRef, c::JuMP.VariableRef)
    a_lb, a_ub = InfrastructureModels.variable_domain(a)
    b_lb, b_ub = InfrastructureModels.variable_domain(b)

    @assert (a_lb >= 0 && b_lb >= 0) || (a_ub <= 0 && b_ub <= 0)

    JuMP.@constraint(m, [a/sqrt(2), b/sqrt(2), c, 0] in JuMP.RotatedSecondOrderCone())
end
