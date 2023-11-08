using Documenter, IterTools

DocMeta.setdocmeta!(IterTools, :DocTestSetup, :(using IterTools))
makedocs(
    modules = [IterTools],
    sitename = "IterTools",
    pages = [
        "Docs" => "index.md",
        ],
    doctest=true,
   )

deploydocs(
    repo = "github.com/JuliaCollections/IterTools.jl.git",
    push_preview = true,
)
