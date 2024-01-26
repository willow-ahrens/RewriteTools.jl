# RewriteTools

[![Build Status](https://github.com/willow-ahrens/RewriteTools.jl/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/willow-ahrens/RewriteTools.jl/actions/workflows/ci.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/willow-ahrens/RewriteTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/willow-ahrens/RewriteTools.jl)

RewriteTools.jl is a utility for term rewriting. RewriteTools.jl is a
fork of [SymbolicUtils.jl](https://github.com/JuliaSymbolics/SymbolicUtils.jl)
version 1.17, preserving and simplifying only the functionality related to term
rewriting. The semantics of rewriter objects is different, and new ``expanders'' have been added which enable program enumeration. RewriteTools.jl is intended for use with custom ASTs that have syntax
which implements
[SyntaxInterface.jl](https://github.com/willow-ahrens/SyntaxInterface.jl).

## Rule-based rewriting

Rewrite rules match and transform an expression. A rule is written using the `@rule` macro and creates a callable `Rule` object.

### A Simple Example

Here is a simple rewrite rule, that uses the formula for the double angle of the sine function:

```julia:rewrite1
using RewriteTools
r1 = @rule :call(sin, :call(*, 2, ~x)) => :(2 * sin($x) * cos($x))
r1(:(sin(2 * z)))
```

The `@rule` macro pairs a matcher pattern with its consequent (`@rule matcher => consequent`). When an expression matches the matcher, it's rewritten to the consequent pattern. This rule signifies: if an expression fits the `sin(2x)` pattern, it's transformed to `2sin(x)cos(x)`.

### Rewriting

Rewriters are powerful tools in Julia for transforming expressions. They can be composed and chained together to create sophisticated transformations.

### Overview of Composing Rewriters

A rewriter is any callable object that takes an expression and returns either a new expression or `nothing`. `Nothing` indicates no applicable changes. The `RewriteTools.Rewriters` module provides several types of rewriters:

- `Empty()`: Always returns `nothing`.
- `Chain(itr)`: Chains an iterator of rewriters into a single rewriter. Each rewriter is applied in sequence. If a rewriter returns `nothing`, it's treated as a no-change.
- `RestartedChain(itr)`: Similar to `Chain(itr)` but restarts from the first rewriter after a successful application.
- `IfElse(cond, rw1, rw2)`: Applies `rw1` if `cond` returns true, otherwise `rw2`.
- `If(cond, rw)`: Equivalent to `IfElse(cond, rw, Empty())`.
- `Prewalk(rw; threaded=false, thread_cutoff=100)`: Performs a pre-order traversal of an expression, applying `rw` at each step. `threaded` enables multithreading.
- `Postwalk(rw; threaded=false, thread_cutoff=100)`: Post-order traversal, applying `rw`.
- `Fixpoint(rw)`: Repeatedly applies `rw` until no further changes occur.
- `PassThrough(rw)`: If `rw(x)` returns `nothing`, `PassThrough` returns `x` instead.