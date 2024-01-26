## Rule-based rewriting

Rewrite rules match and transform an expression. A rule is written using the `@rule` macro and creates a callable `Rule` object.

### Basics of Rule-based Term Rewriting in RewriteTools

Here is a simple rewrite rule, that uses the formula for the double angle of the sine function:

```julia:rewrite1
using RewriteTools
r1 = @rule :call(sin, :call(*, 2, ~x)) => :(2 * sin($x) * cos($x))
r1(:(sin(2 * z)))
```

The `@rule` macro pairs a matcher pattern with its consequent (`@rule matcher => consequent`). When an expression matches the matcher, it's rewritten to the consequent pattern. This rule signifies: if an expression fits the `sin(2x)` pattern, it's transformed to `2sin(x)cos(x)`.

Applying the rule to a non-matching expression results in `nothing`, indicating a mismatch:
```julia:rewrite2
r1(:(sin(3 * z))) === nothing
```

Slot variables can match complex expressions:
```julia:rewrite3
r1(:(sin(2 * (w - z))))
```

But they must represent a single, unified expression:
```julia:rewrite4
r1(:(sin(2 * (w + z) * (α + β)))) === nothing
```

Rules can incorporate multiple slot variables:
```julia:rewrite5
r2 = @rule :call(sin, :call(+, ~x, ~y)) => :(sin($x) * cos($y) + cos($x) * sin($y))
r2(:(sin(α + β)))
```

For matching a variable number of subexpressions, segment variables like `~~xs` are used:
```julia:rewrite6
r3 = @rule :call(+, ~~xs) => sum(~~xs)
r3(:(x + y + z))
```

Segment variables match vectors of subexpressions, useful for constructing complex transformations:
```julia:rewrite7
r4 = @rule :(~x * sum(~~ys)) => sum(map(y -> ~x * y, ~~ys))
r4(:(2 * sum([w, w, α, β])))
```

### Predicates for Matching

Matcher patterns may include slot variables with predicates (`~x::f`), where `f` is a function that evaluates the matched expression. Similarly, `~~x::g` attaches a predicate `g` to a segment variable.

Example with predicates:
```julia:pred1
r5 = @rule :call(+, ~x, ~~y::(ys -> iseven(length(ys)))) => "odd number of terms"
@show r5(:(a + b + c + d))
@show r5(:(b + c + d))
```

### Simplifying Expressions with Rules

To simplify expressions like `(sin(x) + cos(x))^2`, rules are applied:
```julia:rewrite9
using SymbolicUtils
sqexpand = @rule :call(^, :call(+, ~x, ~y), 2) => :((($x)^2 + ($y)^2 + 2 * $x * $y))
sqexpand(:(sin(x) + cos(x))^2)
```