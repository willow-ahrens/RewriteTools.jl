#!/usr/bin/env julia
if abspath(PROGRAM_FILE) == @__FILE__
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.instantiate()
end

using Test
using Documenter
using RewriteTools

root = joinpath(@__DIR__, "..")

DocMeta.setdocmeta!(Finch, :DocTestSetup, :(using RewriteTools); recursive=true)

Literate.notebook(joinpath(@__DIR__, "src/interactive.jl"), joinpath(@__DIR__, "src"), credit = false)

doctest(RewriteTools, fix=true)