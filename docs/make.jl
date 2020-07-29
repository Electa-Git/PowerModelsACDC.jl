using Documenter, PowerModelsACDC

Documenter.makedocs(
    modules = PowerModelsACDC,
    format = Documenter.HTML(),
    sitename = "PowerModelsACDC",
    authors = "Frederik Geth, Hakan Ergun",
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "quickguide.md",
            "Results" => "result-data.md",
        ],
        "Library" => [
            "Network Formulations" => "formulations.md",
            "Problem Specifications" => "specifications.md",
            "Problem Types" => "problems.md",
            "Modeling Components" => [
                "Objective" => "objective.md",
                "Variables" => "variables.md",
                "Constraints" => "constraints.md",
            ],
            "File IO" => "parser.md"
        ],
    ]
)

Documenter.deploydocs(
    repo = "github.com/hakanergun/PowerModelsACDC.jl.git"
)
