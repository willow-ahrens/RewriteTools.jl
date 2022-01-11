# RewriteTools

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://peterahrens.github.io/RewriteTools.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://peterahrens.github.io/RewriteTools.jl/dev)
[![Build Status](https://github.com/peterahrens/RewriteTools.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/peterahrens/RewriteTools.jl/actions/workflows/ci.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/peterahrens/RewriteTools.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/peterahrens/RewriteTools.jl)

RewriteTools.jl is a simplified utility for term rewriting. RewriteTools.jl is a
fork of [SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl)
version 1.17, preserving and simplifying only the functionality related to term
rewriting. Some additional rewriters may be added and functionality may be
changed. RewriteTools.jl is intended for use with custom ASTs that have syntax
which implements
[SyntaxInterface.jl](https://github.com/peterahrens/SyntaxInterface.jl). I have
made a modest attempt to preserve compatibility with SymbolicUtils.jl.

## Overview

Functions are documented with docstrings; we give a few examples here.

```julia
julia> using RewriteTools

julia> r = @slots a b c @rule (a * b) + (a * c) => term(*, a, term(+, b, c))

julia> r(term(+, term(*, 1, 2), term(1, 3)))
1 * (2 + 3)
```