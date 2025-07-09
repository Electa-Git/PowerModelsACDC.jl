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
            "Problem and Network Formulations" => "problems_and_formulations.md"
            "Problem Specifications" => "specifications.md"
            "Problem Types" => "problems.md"
            "Component models" => [
                "Phase shifting transformers" => "comp/pst.md"
                "Static synchronous series compensation" => "comp/sssc.md"
                "DC branches" => "comp/dcbranch.md"
                "Generators" => "comp/gen.md"
            ]
            "File IO" => "parser.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/Electa-Git/PowerModelsACDC.jl.git"
)
