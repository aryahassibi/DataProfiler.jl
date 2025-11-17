push!(LOAD_PATH, joinpath(@__DIR__, ".."))

using Documenter
using DataProfiler

makedocs(
    sitename = "DataProfiler.jl",
    modules = [DataProfiler],
    format = Documenter.HTML(; prettyurls = false, edit_link = nothing),
    repo = "https://github.com/aryahassibi/DataProfiler.jl.git",
    # remotes = nothing,
    pages = [
        "Home" => "index.md",
        "API"  => "api.md",
    ],
    doctest = true,
)



# For GitHub Pages
deploydocs(
    repo = "https://github.com/aryahassibi/DataProfiler.jl.git",
    devbranch = "develop",
)

