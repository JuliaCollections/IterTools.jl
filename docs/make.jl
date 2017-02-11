using Documenter, Iterators

makedocs(
    modules = [Iterators],
    format = :html,
    sitename = "Iterators",
    pages = Any[
        "Introduction" => "index.md",
        "Function index" => "functionindex.md"
        ])

deploydocs(
    repo = "github.com/JuliaCollections/Iterators.jl.git",
    target = "build",
    julia  = "0.5",
    osname = "osx",
    deps = nothing,
    make = nothing
)
