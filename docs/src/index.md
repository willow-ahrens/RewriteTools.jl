```@meta
CurrentModule = RewriteTools
```

# RewriteTools

Documentation for [RewriteTools](https://github.com/willow-ahrens/RewriteTools.jl).

RewriteTools.jl is a utility for term rewriting. RewriteTools.jl is a fork of
[SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl) version
1.17, preserving and simplifying only the functionality related to term
rewriting. The semantics of matcher and rewriter objects is simplified and more
uniform.  RewriteTools.jl is intended for use with custom ASTs that have syntax
which implements
[SyntaxInterface.jl](https://github.com/willow-ahrens/SyntaxInterface.jl).

# Installation

```julia
julia> using Pkg; Pkg.add("RewriteTools")
```