using RewriteTools
using Documenter

DocMeta.setdocmeta!(RewriteTools, :DocTestSetup, :(using RewriteTools); recursive=true)

makedocs(;
    modules=[RewriteTools],
    authors="Peter Ahrens",
    repo="https://github.com/peterahrens/RewriteTools.jl/blob/{commit}{path}#{line}",
    sitename="RewriteTools.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://peterahrens.github.io/RewriteTools.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/peterahrens/RewriteTools.jl",
    devbranch="main",
)
