# RewriteTools

[docs]:https://willow-ahrens.github.io/RewriteTools.jl/stable
[ddocs]:https://willow-ahrens.github.io/RewriteTools.jl/dev
[ci]:https://github.com/willow-ahrens/RewriteTools.jl/actions/workflows/CI.yml?query=branch%3Amain
[cov]:https://codecov.io/gh/willow-ahrens/RewriteTools.jl

[docs_ico]:https://img.shields.io/badge/docs-stable-blue.svg
[ddocs_ico]:https://img.shields.io/badge/docs-dev-blue.svg
[ci_ico]:https://github.com/willow-ahrens/RewriteTools.jl/actions/workflows/CI.yml/badge.svg?branch=main
[cov_ico]:https://codecov.io/gh/willow-ahrens/RewriteTools.jl/branch/main/graph/badge.svg

| **Documentation**                             | **Build Status**                      |
|:---------------------------------------------:|:-------------------------------------:|
| [![][docs_ico]][docs] [![][ddocs_ico]][ddocs] | [![][ci_ico]][ci] [![][cov_ico]][cov] |

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
- `Prewalk(rw)`: Performs a pre-order traversal of an expression, applying `rw` at each step. `threaded` enables multithreading.
- `Postwalk(rw)`: Post-order traversal, applying `rw`.
- `Fixpoint(rw)`: Repeatedly applies `rw` until no further changes occur.
- `Prestep(rw)`: Recursively rewrites each node using `rw`. Only recurses if `rw` is not nothing.
- `Rewrite(rw)`: If `rw(x)` returns `nothing`, `Rewrite` returns `x` instead.
