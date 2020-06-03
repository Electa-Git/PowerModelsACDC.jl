# Example code to print list of built HVDC branches and converters
function display_results_tnep(result)
    built_cv = []
    built_br = []
    for (c, conv) in result["solution"]["convdc_ne"]
        if isapprox(conv["isbuilt"] , 1; atol = 0.01)
            print("Conv: $c \n")
            push!(built_cv,c)
        end
    end
    for (b, branch) in result["solution"]["branchdc_ne"]
        if isapprox(branch["isbuilt"] , 1; atol = 0.01)
            print("Branch: $b \n")
            push!(built_br,b)
        end
    end
    return built_cv, built_br
end
