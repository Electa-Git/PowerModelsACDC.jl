using Documenter, PowerModelsACDC

makedocs(
    modules = PowerModelsACDC,
    format = Documenter.HTML(analytics = "UA-367975-10", mathengine = Documenter.MathJax()),
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
            "File IO" => "parser.md",
        ],
    ]
)

deploydocs(
<<<<<<< Updated upstream
    repo = "github.com/hakanergun/PowerModelsACDC.jl.git",
=======
    repo = "github.com/hakanergun/PowerModelsACDC.jl.git"
>>>>>>> Stashed changes
)
