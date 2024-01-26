```@meta
CurrentModule = RewriteTools.Rewriters
```

## Composing Rewriters

Rewriters are powerful tools for transforming expressions. They can be composed and chained together to create sophisticated transformations.

### Overview of Composing Rewriters

A rewriter is any callable object that takes an expression and returns either a new expression or `nothing`. `Nothing` indicates no applicable changes. The `RewriteTools.Rewriters` module provides several types of rewriters:

- `Empty()`: Always returns `nothing`.
- `Chain(itr)`: Chains an iterator of rewriters into a single rewriter. Each rewriter is applied in sequence.
- `RestartedChain(itr)`: Similar to `Chain(itr)` but restarts from the first rewriter after a successful application.
- `IfElse(cond, rw1, rw2)`: Applies `rw1` if `cond` returns true, otherwise `rw2`.
- `If(cond, rw)`: Equivalent to `IfElse(cond, rw, Empty())`.
- `Prewalk(rw)`: Performs a pre-order traversal of an expression, applying `rw` at each step.
- `Postwalk(rw)`: Post-order traversal, applying `rw`.
- `Fixpoint(rw)`: Repeatedly applies `rw` until no further changes occur.
- `Prestep(rw)`: Recursively rewrites each node using `rw`. Only recurses if `rw` is not nothing.
- `Rewrite(rw)`: If `rw(x)` returns `nothing`, `Rewrite` returns `x` instead.

### Chaining Rewriters

Rewriters can be combined into a chain, allowing multiple rules to be applied sequentially:

```jldoctest composing
julia> using RewriteTools

julia> using RewriteTools.Rewriters

julia> powexpand = @rule :call(:^, ~x, ~n) => :($x * $x^$(n - 1))
(:call)(:^, ~x, ~n) => Core._expr(:call, :*, x, Core._expr(:call, :^, x, n - 1))

julia> powid = @rule :call(:^, ~x, 1) => :($x)
(:call)(:^, ~x, 1) => x

julia> cas = Chain([powexpand, powid])
Chain{Vector{RewriteTools.Rule{RewriteTools.Term}}}(RewriteTools.Rule{RewriteTools.Term}[(:call)(:^, ~x, ~n) => Core._expr(:call, :*, x, Core._expr(:call, :^, x, n - 1)), (:call)(:^, ~x, 1) => x])

julia> cas(:((sin(x) + cos(x))^2))
:((sin(x) + cos(x)) * (sin(x) + cos(x)) ^ 1)
```

An important feature of `Chain` is that it returns `nothing` if there are no changes:

```jldoctest composing
julia> Chain([powid, powexpand])(:(x + y))

```

`Postwalk` allows us to further rewrite subterms of our expressions.

```jldoctest composing
julia> cas2 = Postwalk(Chain([powid, powexpand]))
Postwalk{Chain{Vector{RewriteTools.Rule{RewriteTools.Term}}}}(Chain{Vector{RewriteTools.Rule{RewriteTools.Term}}}(RewriteTools.Rule{RewriteTools.Term}[(:call)(:^, ~x, 1) => x, (:call)(:^, ~x, ~n) => Core._expr(:call, :*, x, Core._expr(:call, :^, x, n - 1))]))

julia> cas2(:((sin(x) + cos(x)) * (sin(x) + cos(x)) ^ 1))
:((sin(x) + cos(x)) * (sin(x) + cos(x)))
```

`Fixpoint` allows us to rewrite until no changes can be made

```jldoctest composing
julia> cas3 = Fixpoint(Postwalk(Chain([powid, powexpand])))
Fixpoint{Postwalk{Chain{Vector{RewriteTools.Rule{RewriteTools.Term}}}}}(Postwalk{Chain{Vector{RewriteTools.Rule{RewriteTools.Term}}}}(Chain{Vector{RewriteTools.Rule{RewriteTools.Term}}}(RewriteTools.Rule{RewriteTools.Term}[(:call)(:^, ~x, 1) => x, (:call)(:^, ~x, ~n) => Core._expr(:call, :*, x, Core._expr(:call, :^, x, n - 1))])))

julia> cas3(:((sin(x) + cos(x))^4))
:((sin(x) + cos(x)) * ((sin(x) + cos(x)) * ((sin(x) + cos(x)) * (sin(x) + cos(x)))))
```

```@docs
IfElse{F, A, B}
Rewrite
NoRewrite
Fixpoint{C}
Prewalk{C}
Postwalk{C}
Chain{C}
Prestep{C}
```