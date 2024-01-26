```@meta
CurrentModule = RewriteTools
```

## Rule-based rewriting

Rewrite rules match and transform an expression. A rule is written using the `@rule` macro and creates a callable `Rule` object.

### Basics of Rule-based Term Rewriting in RewriteTools

Here is a simple rewrite rule, that uses the formula for the double angle of the sine function:

```jldoctest rewrite
julia> using RewriteTools

julia> r1 = @rule :call(:sin, :call(:*, 2, ~x)) => :(2 * sin($x) * cos($x))
(:call)(:sin, (:call)(:*, 2, ~x)) => Core._expr(:call, :*, 2, Core._expr(:call, :sin, x), Core._expr(:call, :cos, x))

julia> r1(:(sin(2 * z)))
:(2 * sin(z) * cos(z))

```

The `@rule` macro pairs a matcher pattern with its consequent (`@rule matcher => consequent`). When an expression matches the matcher, it's rewritten to the consequent pattern. This rule signifies: if an expression fits the `sin(2x)` pattern, it's transformed to `2sin(x)cos(x)`.

Applying the rule to a non-matching expression results in `nothing`, indicating a mismatch:
```jldoctest rewrite
julia> r1(:(sin(3 * z))) === nothing
true
```

Slot variables can match complex expressions:
```jldoctest rewrite
julia> r1(:(sin(2 * (w - z))))
:(2 * sin(w - z) * cos(w - z))

```

But they must represent a single, unified expression:
```jldoctest rewrite
julia> r1(:(sin(2 * (w + z) * (α + β)))) === nothing
true
```

Rules can incorporate multiple slot variables:
```jldoctest rewrite
julia> r2 = @rule :call(:sin, :call(:+, ~x, ~y)) => :(sin($x) * cos($y) + cos($x) * sin($y))
(:call)(:sin, (:call)(:+, ~x, ~y)) => Core._expr(:call, :+, Core._expr(:call, :*, Core._expr(:call, :sin, x), Core._expr(:call, :cos, y)), Core._expr(:call, :*, Core._expr(:call, :cos, x), Core._expr(:call, :sin, y)))

julia> r2(:(sin(α + β)))
:(sin(α) * cos(β) + cos(α) * sin(β))

```

For matching a variable number of subexpressions, segment variables like `~~xs` are used:
```jldoctest rewrite
julia> r3 = @rule :call(:+, ~~xs) => :(sum($xs))
(:call)(:+, ~(~xs)) => Core._expr(:call, :sum, xs)

julia> r3(:(x + y + z))
:(sum(Any[:x, :y, :z]))

```

Segment variables match vectors of subexpressions, useful for constructing complex transformations:
```jldoctest rewrite
julia> r4 = @rule :call(:*, ~x, :call(:+, ~~ys)) => :(+($(map(y -> :($x * $y), ys)...)))
(:call)(:*, ~x, (:call)(:+, ~(~ys))) => Core._expr(:call, :+, map((y->begin
                    #= none:1 =#
                    Core._expr(:call, :*, x, y)
                end), ys)...)

julia> r4(:(2 * +(w, w, α, β)))
:(2w + 2w + 2α + 2β)

```

### Predicates for Matching

Matcher patterns may include slot variables with predicates (`~x::f`), where `f` is a function that evaluates the matched expression. Similarly, `~~x::g` attaches a predicate `g` to a segment variable.

Example with predicates:
```jldoctest rewrite
julia> r5 = @rule :call(:+, ~x, ~~y::(ys -> iseven(length(ys)))) => "odd number of terms"
(:call)(:+, ~x, ~(~(y::(ys->begin
                            #= none:1 =#
                            iseven(length(ys))
                        end)))) => "odd number of terms"

julia> @show r5(:(a + b + c + d))
r5($(Expr(:quote, :(a + b + c + d)))) = nothing

julia> @show r5(:(b + c + d))
r5($(Expr(:quote, :(b + c + d)))) = "odd number of terms"
"odd number of terms"

julia> @show r5(:(b + c + b))
r5($(Expr(:quote, :(b + c + b)))) = "odd number of terms"
"odd number of terms"

julia> @show r5(:(b + c))
r5($(Expr(:quote, :(b + c)))) = nothing
```

### Simplifying Expressions with Rules

To simplify expressions like `(sin(x) + cos(x))^2`, rules are applied:
```jldoctest rewrite
julia> sqexpand = @rule :call(:^, :call(:+, ~x, ~y), 2) => :((($x)^2 + ($y)^2 + 2 * $x * $y))
(:call)(:^, (:call)(:+, ~x, ~y), 2) => Core._expr(:call, :+, Core._expr(:call, :^, x, 2), Core._expr(:call, :^, y, 2), Core._expr(:call, :*, 2, x, y))

julia> sqexpand(:((sin(x) + cos(x))^2))
:(sin(x) ^ 2 + cos(x) ^ 2 + 2 * sin(x) * cos(x))

```

### Docs

```@docs
@rule
@capture
```