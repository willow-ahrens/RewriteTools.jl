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

DocMeta.setdocmeta!(RewriteTools, :DocTestSetup, :(using RewriteTools); recursive=true)

doctest(RewriteTools, fix=true)