using RewriteTools
using Documenter

DocMeta.setdocmeta!(RewriteTools, :DocTestSetup, :(using RewriteTools); recursive=true)

makedocs(;
    modules=[RewriteTools],
    authors="Willow Ahrens",
    repo="https://github.com/willow-ahrens/RewriteTools.jl/blob/{commit}{path}#{line}",
    sitename="RewriteTools.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://willow-ahrens.github.io/RewriteTools.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/willow-ahrens/RewriteTools.jl",
    devbranch="main",
)
