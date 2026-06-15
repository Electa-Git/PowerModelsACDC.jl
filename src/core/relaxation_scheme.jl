"constraint: `|c| <= z*b`"
function relaxation_semicont_variable_on_off(m::JuMP.Model, a::JuMP.VariableRef, z::JuMP.VariableRef)
    a_lb, a_ub = _IM.variable_domain(a)

    JuMP.@constraint(m, a <= a_ub*z)
    JuMP.@constraint(m, a >= a_lb*z)
end

"constraint: `|c| <= z*b`"
function relaxation_variable_on_off(m::JuMP.Model, x::JuMP.VariableRef, y::JuMP.VariableRef, z::JuMP.VariableRef)
    x_lb, x_ub = _IM.variable_domain(x)

    JuMP.@constraint(m, y <= x_ub*z)
    JuMP.@constraint(m, y >= x_lb*z)
end
