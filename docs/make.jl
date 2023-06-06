using Documenter, IterTools

makedocs(
    modules = [IterTools],
    sitename = "IterTools",
    pages = [
        "Docs" => "index.md",
        ],
    doctest=false,
   )

deploydocs(
    repo = "github.com/JuliaCollections/IterTools.jl.git",
    push_preview = true,
)
