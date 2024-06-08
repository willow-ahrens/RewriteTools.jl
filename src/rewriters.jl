"""
    A rewriter is any function which takes an expression and returns an
    expression. A expander is any function which takes an expression and returns
    a list of possible rewrites. Either function can return `nothing` if there
    are no changes applicable to the input expression.
"""
module Rewriters

using SyntaxInterface: is_operation, istree, operation, similarterm, arguments, node_count
using Base.Iterators

export IfElse
export Rewrite, NoRewrite, Fixpoint, Prewalk, Postwalk, Chain, Prestep, Memo

"""
    `IfElse(cond, rw1, rw2)`
    
    Returns a function which runs the `cond` function on the input, applies
    `rw1` if cond returns true, `rw2` if it retuns false. For example, one
        might set `rw2` to `NoRewrite()` or `NoSaturate()`
"""
struct IfElse{F, A, B}
    cond::F
    yes::A
    no::B
end

"""
    Rewrite(rw)

    A rewriter which returns the original argument even if `rw` returns nothing
"""
struct Rewrite{R}
    rw::R
end

defaultrewrite(y, x) = y === nothing ? x : y
(rw::Rewrite{R})(x) where {R} = defaultrewrite(rw.rw(x), x)

function stable_map(::Type{T}, f::F, args...) where {T, F}
    stable_res = Vector{T}(undef, length(first(args)))
    unstable_res = Vector{Any}(undef, length(first(args)))
    is_stable = true
    for i in 1:length(first(args))
        res = f(ntuple(n -> args[n][i], length(args))...)
        if is_stable && res isa T
            stable_res[i] = res
        else
            is_stable = false
        end
        unstable_res[i] = res
    end
    if is_stable
        return stable_res
    else
        return unstable_res
    end
end

"""
    NoRewrite()

    A rewriter which always returns `nothing`
"""
struct NoRewrite end

(rw::NoRewrite)(x) = nothing

"""
    `Fixpoint(rw)`

    An rewriter which repeatedly applies `rw` to `x` until no changes are made. If
    the rewriter first returns `nothing`, returns `nothing`.
"""
struct Fixpoint{R}
    rw::R
end

function (p::Fixpoint{R})(x) where {R}
    y = p.rw(x)
    if y !== nothing
        while y !== nothing && x !== y && !isequal(x, y)
            x = y
            y = p.rw(x)
        end
        return x
    else
        return nothing
    end
end

"""
    `Prewalk(rw)`

    An rewriter which recursively rewrites each node using `rw`, then rewrites
    the arguments of the resulting node. If all rewriters return `nothing`,
    returns `nothing`.
"""
struct Prewalk{R}
    rw::R
end

function (p::Prewalk{R})(x::T) where {T, R}
    y = p.rw(x)
    if y !== nothing
        if istree(y)
            args = arguments(y)
            return similarterm(y, operation(y), stable_map(T, arg->defaultrewrite(p(arg), arg), args))
        else 
            return y
        end
    elseif istree(x)
        args = arguments(x)
        new_args = stable_map(Union{Nothing, T}, p, args)
        if !all(isnothing, new_args)
            return similarterm(x, operation(x), stable_map(T, defaultrewrite, new_args, args))
        else
            return nothing
        end
    else
        return nothing
    end
end

"""
    `Postwalk(rw)`

    An rewriter which recursively rewrites the arguments of each node using
    `rw`, then rewrites the resulting node. If all rewriters return `nothing`,
    returns `nothing`.
"""
struct Postwalk{R}
    rw::R
end

function (p::Postwalk{R})(x::T) where {R, T}
    if istree(x)
        args = arguments(x)
        new_args = stable_map(Union{Nothing, T}, p, args)
        if all(isnothing, new_args)
            return p.rw(x)
        else
            y = similarterm(x, operation(x), stable_map(T, defaultrewrite, new_args, args))
            defaultrewrite(p.rw(y), y)
        end
    else 
        return p.rw(x)
    end
end

"""
    `Chain(itr)`

    An rewriter which rewrites using each rewriter in `itr`. If all rewriters
    return `nothing`, return `nothing`.
"""
struct Chain{Rs}
    rws::Rs
end

function (p::Chain{Rs})(x) where {Rs}
    trigger = false
    for rw in p.rws
        y = rw(x)
        if y !== nothing
            trigger = true
            x = y
        end
    end
    if trigger
        return x
    end
end

"""
    `Prestep(rw)`

    An rewriter which recursively rewrites each node using `rw`. If `rw` is
    nothing, it returns `nothing`, otherwise it recurses to the arguments.
"""
struct Prestep{R}
    rw::R
end

function (p::Prestep{R})(x::T) where {T, R}
    y = p.rw(x)
    if y !== nothing
        if istree(y)
            y_args = arguments(y)
            return similarterm(y, operation(y), stable_map(T, y_arg->defaultrewrite(p(y_arg), y_arg), y_args))
        else
            return y
        end
    else
        return nothing
    end
end

"""
    `Memo(rw, cache=Dict())`

    An rewriter which caches the results of `rw` in `cache` and returns the
    result.
"""
struct Memo{R, C}
    rw::R
    cache::C
end

function (p::Memo{R, C})(x::T) where {R, C, T}
    get!(p.cache, x) do
        p.rw(x)
    end
end


end # module Rewriters