"constraint: `c^2 + d^2 <= a*b`"
function relaxation_complex_product_conic(m::JuMP.Model, a::JuMP.VariableRef, b::JuMP.VariableRef, c::JuMP.VariableRef)
    a_lb, a_ub = _IM.variable_domain(a)
    b_lb, b_ub = _IM.variable_domain(b)

    @assert (a_lb >= 0 && b_lb >= 0) || (a_ub <= 0 && b_ub <= 0)

    JuMP.@constraint(m, [a/sqrt(2), b/sqrt(2), c, 0] in JuMP.RotatedSecondOrderCone())
end



function relaxation_complex_product_conic_on_off(m::JuMP.Model, a::JuMP.VariableRef, b::JuMP.VariableRef, c::JuMP.VariableRef, d::JuMP.VariableRef, z::JuMP.VariableRef)
    a_lb, a_ub = _IM.variable_domain(a)
    b_lb, b_ub = _IM.variable_domain(b)
    c_lb, c_ub = _IM.variable_domain(c)
    d_lb, d_ub = _IM.variable_domain(d)
    z_lb, z_ub = _IM.variable_domain(z)

    @assert c_lb <= 0 && c_ub >= 0
    @assert d_lb <= 0 && d_ub >= 0

    JuMP.@constraint(m, [a/sqrt(2)*z_ub, b/sqrt(2), c, d] in JuMP.RotatedSecondOrderCone())
    JuMP.@constraint(m, [a_ub/sqrt(2)*z, b/sqrt(2), c, d] in JuMP.RotatedSecondOrderCone())
    JuMP.@constraint(m, [a/sqrt(2), b_ub/sqrt(2)*z, c, d] in JuMP.RotatedSecondOrderCone())
end

function relaxation_complex_product_on_off(m::JuMP.Model, a::JuMP.VariableRef, b::JuMP.VariableRef, c::JuMP.VariableRef, d::JuMP.VariableRef) #to be moved to _IM
    a_lb, a_ub = _IM.variable_domain(a)
    b_lb, b_ub = _IM.variable_domain(b)
    c_lb, c_ub = _IM.variable_domain(c)

    @assert c_lb <= 0 && c_ub >= 0

    JuMP.@constraint(m, c^2 <= a*b*z_ub)
    JuMP.@constraint(m, c^2 <= a_ub*b*z)
    JuMP.@constraint(m, c^2 <= a*b_ub*z)
end

"constraint: `c^2 + d^2 <= a*b`"
function relaxation_complex_product(m::JuMP.Model, a::JuMP.VariableRef, b::JuMP.VariableRef, c::JuMP.VariableRef)
    a_lb, a_ub = _IM.variable_domain(a)
    b_lb, b_ub = _IM.variable_domain(b)

    @assert (a_lb >= 0 && b_lb >= 0) || (a_ub <= 0 && b_ub <= 0)

    JuMP.@constraint(m, c^2 <= a*b)
end


function relaxation_semicont_variable_on_off(m::JuMP.Model, a::JuMP.VariableRef, z::JuMP.VariableRef)
    a_lb, a_ub = _IM.variable_domain(a)
    
    JuMP.@constraint(m, a <= a_ub*z)
    JuMP.@constraint(m, a >= a_lb*z)
end

function relaxation_variable_on_off(m::JuMP.Model, x::JuMP.VariableRef, y::JuMP.VariableRef, z::JuMP.VariableRef)
    x_lb, x_ub = _IM.variable_domain(x)

    JuMP.@constraint(m, y <= x_ub*z)
    JuMP.@constraint(m, y >= x_lb*z)
end
