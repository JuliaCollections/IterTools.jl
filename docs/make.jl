using Documenter, IterTools

makedocs(
    modules = [IterTools],
    format = :html,
    sitename = "IterTools",
    pages = Any[
        "Introduction" => "index.md",
        "Function index" => "functionindex.md"
        ])

deploydocs(
    repo = "github.com/JuliaCollections/IterTools.jl.git",
    target = "build",
    julia  = "0.7",
    osname = "linux",
    deps = nothing,
    make = nothing
)
