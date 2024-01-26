#!/usr/bin/env julia
if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

using Documenter
using Documenter.Remotes
using RewriteTools

DocMeta.setdocmeta!(RewriteTools, :DocTestSetup, :(using RewriteTools); recursive=true)

makedocs(;
    modules=[RewriteTools],
    authors="Willow Ahrens",
    repo=Remotes.GitHub("willow-ahrens", "RewriteTools.jl"),
    sitename="RewriteTools.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://willow-ahrens.github.io/RewriteTools.jl",
        assets=["assets/favicon.ico"],
    ),
    pages=[
        "Home" => "index.md",
        "Matchers" => "matchers.md",
        "Rewriters" => "rewriters.md",
    ],
    warnonly=[:missing_docs],
)

deploydocs(;
    repo="github.com/willow-ahrens/RewriteTools.jl",
    devbranch="main",
)
