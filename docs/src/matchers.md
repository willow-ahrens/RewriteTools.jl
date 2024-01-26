## Rule-based rewriting

Rewrite rules match and transform an expression. A rule is written using the `@rule` macro and creates a callable `Rule` object.

### Basics of Rule-based Term Rewriting in RewriteTools

Here is a simple rewrite rule, that uses the formula for the double angle of the sine function:

```jldoctest rewrite1
julia> using RewriteTools

julia> r1 = @rule :call(sin, :call(*, 2, ~x)) => :(2 * sin($x) * cos($x))
Rule(...)

julia> r1(:(sin(2 * z)))
:(2 * sin(z) * cos(z))
```

The `@rule` macro pairs a matcher pattern with its consequent (`@rule matcher => consequent`). When an expression matches the matcher, it's rewritten to the consequent pattern. This rule signifies: if an expression fits the `sin(2x)` pattern, it's transformed to `2sin(x)cos(x)`.

Applying the rule to a non-matching expression results in `nothing`, indicating a mismatch:
```jldoctest rewrite2
julia> r1(:(sin(3 * z))) === nothing
true
```

Slot variables can match complex expressions:
```jldoctest rewrite3
julia> r1(:(sin(2 * (w - z))))
:(2 * sin(w - z) * cos(w - z))
```

But they must represent a single, unified expression:
```jldoctest rewrite4
julia> r1(:(sin(2 * (w + z) * (α + β)))) === nothing
true
```

Rules can incorporate multiple slot variables:
```jldoctest rewrite5
julia> r2 = @rule :call(sin, :call(+, ~x, ~y)) => :(sin($x) * cos($y) + cos($x) * sin($y))
Rule(...)

julia> r2(:(sin(α + β)))
:(sin(α) * cos(β) + cos(α) * sin(β))
```

For matching a variable number of subexpressions, segment variables like `~~xs` are used:
```jldoctest rewrite6
julia> r3 = @rule :call(+, ~~xs) => sum(~~xs)
Rule(...)

julia> r3(:(x + y + z))
:(x + y + z)
```

Segment variables match vectors of subexpressions, useful for constructing complex transformations:
```jldoctest rewrite7
julia> r4 = @rule :(~x * sum(~~ys)) => sum(map(y -> ~x * y, ~~ys))
Rule(...)

julia> r4(:(2 * sum([w, w, α, β])))
:(2 * w + 2 * w + 2 * α + 2 * β)
```

### Predicates for Matching

Matcher patterns may include slot variables with predicates (`~x::f`), where `f` is a function that evaluates the matched expression. Similarly, `~~x::g` attaches a predicate `g` to a segment variable.

Example with predicates:
```jldoctest pred1
julia> r5 = @rule :call(+, ~x, ~~y::(ys -> iseven(length(ys)))) => "odd number of terms"
Rule(...)

julia> @show r5(:(a + b + c + d))
r5(:(a + b + c + d)) = "odd number of terms"

julia> @show r5(:(b + c + d))
r5(:(b + c + d)) = nothing
```

### Simplifying Expressions with Rules

To simplify expressions like `(sin(x) + cos(x))^2`, rules are applied:
```jldoctest rewrite9
julia> using SymbolicUtils

julia> sqexpand = @rule :call(^, :call(+, ~x, ~y), 2) => :((($x)^2 + ($y)^2 + 2 * $x * $y))
Rule(...)

julia> sqexpand(:(sin(x) + cos(x))^2)
:((sin(x)^2 + cos(x)^2 + 2 * sin(x) * cos(x)))
```