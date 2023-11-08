using Documenter, IterTools

makedocs(
    modules = [IterTools],
    sitename = "IterTools",
    pages = [
        "Home" => "index.md",
        "API Reference" => "reference.md"
        ],
    doctest=false,
   )

deploydocs(
    repo = "github.com/JuliaCollections/IterTools.jl.git",
    push_preview = true,
)
