# RewriteTools

[![Build Status](https://github.com/peterahrens/RewriteTools.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/peterahrens/RewriteTools.jl/actions/workflows/ci.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/peterahrens/RewriteTools.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/peterahrens/RewriteTools.jl)

RewriteTools.jl is a simplified utility for term rewriting. RewriteTools.jl is a
fork of [SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl)
version 1.17, preserving and simplifying only the functionality related to term
rewriting. The semantics of rewriter objects is different, and new ``expanders'' have been added which enable program enumeration. RewriteTools.jl is intended for use with custom ASTs that have syntax
which implements
[SyntaxInterface.jl](https://github.com/peterahrens/SyntaxInterface.jl).


## Overview

Functions are documented with docstrings; we give a few examples here.

```julia
julia> using RewriteTools

julia> r = @slots a b c @rule (a * b) + (a * c) => term(*, a, term(+, b, c))

julia> r(term(+, term(*, 1, 2), term(1, 3)))
1 * (2 + 3)
```