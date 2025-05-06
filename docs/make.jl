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
            "Component models" => [
                "Phase shifting transformers" => "pst.md"
                "Static synchronous series compensation" => "sssc.md"
            ]
            "File IO" => "parser.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/Electa-Git/PowerModelsACDC.jl.git"
)
