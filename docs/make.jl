using Documenter, PowerModelsACDC

makedocs(
    modules = [PowerModelsACDC],
    sitename = "PowerModelsACDC",
    warnonly = :missing_docs,
    pages = [
        "Home" => "index.md"
        "Manual" => [
            "Getting Started" => "quickguide.md"
            "Results" => "result-data.md"
        ]
        "Library" => [
            "Network Formulations" => "formulations.md"
            "Problem Specifications" => "specifications.md"
            "Problem Types" => "problems.md"
            "Modeling Components" => [
                "Objective" => "objective.md"
                "Variables" => "variables.md"
                "Constraints" => "constraints.md"
            ]
            "File IO" => "parser.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/Electa-Git/PowerModelsACDC.jl.git"
)
