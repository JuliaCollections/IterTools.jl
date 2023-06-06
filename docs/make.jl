using Documenter, IterTools

makedocs(
    modules = [IterTools],
    sitename = "IterTools",
    pages = [
        "Introduction" => "index.md",
        "Function index" => "functionindex.md"
        ],
    doctest=false,
   )

deploydocs(
    repo = "github.com/JuliaCollections/IterTools.jl.git",
    push_preview = true,
)
