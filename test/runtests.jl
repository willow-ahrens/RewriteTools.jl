using Documenter
using Pkg
using Test
using RewriteTools

DocMeta.setdocmeta!(
    RewriteTools,
    :DocTestSetup,
    :(using RewriteTools);
    recursive=true
)

# Only test one Julia version to avoid differences due to changes in printing.
if v"1.6" ≤ VERSION < v"1.7-beta3.0"
    doctest(RewriteTools)
else
    @warn "Skipping doctests"
end

include("utils.jl")
include("basics.jl")
include("rule.jl")
include("rewrite.jl")
