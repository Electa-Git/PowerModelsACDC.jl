using Documenter, PowerModelsACDC

makedocs(
    modules = [PowerModelsACDC],
    format = :html,
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
            "Modeling Components" => [
                "Objective" => "objective.md",
                "Variables" => "variables.md",
                "Constraints" => "constraints.md"
                "Problem Types" => "problems.md"
            ],
            "File IO" => "parser.md"
        ],
    ]
)

deploydocs(
    # deps = nothing,
    # make = nothing,
    # target = "build",
    # julia = "1.1",
    repo = "github.com/hakanergun/PowerModelsACDC.jl.git"
)
