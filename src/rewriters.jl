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
export Rewrite, NoRewrite, Fixpoint, Prewalk, Postwalk, Chain, Prestep
export Expand, NoExpand, Saturate, Presearch, Postsearch, Branch

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
struct Rewrite
    rw
end

defaultrewrite(y, x) = y === nothing ? x : y
(rw::Rewrite)(x) = defaultrewrite(rw.rw(x), x)

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
struct Fixpoint{C}
    rw::C
end

function (p::Fixpoint)(x)
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
struct Prewalk{C}
    rw::C
end

function (p::Prewalk{C})(x) where {C}
    y = p.rw(x)
    if y !== nothing
        if istree(y)
            args = arguments(y)
            new_args = map(p, args)
            return similarterm(y, operation(y), map(defaultrewrite, new_args, args))
        else 
            return y
        end
    elseif istree(x)
        args = arguments(x)
        new_args = map(p, args)
        if !all(isnothing, new_args)
            return similarterm(x, operation(x), map(defaultrewrite, new_args, args))
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
struct Postwalk{C}
    rw::C
end

function (p::Postwalk{C})(x) where {C}
    if istree(x)
        args = arguments(x)
        new_args = map(p, args)
        if all(isnothing, new_args)
            return p.rw(x)
        else
            y = similarterm(x, operation(x), map(defaultrewrite, new_args, args))
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
struct Chain{C}
    rws::C
end

function (p::Chain{C})(x) where {C}
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
struct Prestep{C}
    rw::C
end

function (p::Prestep{C})(x) where {C}
    y = p.rw(x)
    if y !== nothing
        if istree(y)
            y_args = arguments(y)
            return similarterm(y, operation(y), map(y_arg->defaultrewrite(p(y_arg), y_arg), y_args))
        else
            return y
        end
    else
        return nothing
    end
end

"""
    Expand(rw)

    An expander which returns the original argument even if `rw` returns nothing
"""
struct Expand
    rw
end

defaultexpand(y, x) = y === nothing ? [x] : y
(rw::Expand)(x) = defaultexpand(rw.rw(x), x)

"""
    NoExpand()

    An expansion which does not expand the term.
"""
struct NoExpand end

(rw::NoExpand)(x) = [x]

"""
    `Saturate(rw)`

    An expander which applies `rw` to `x` until no new terms are generated. If
    the expander first returns `nothing`, returns `nothing`.
"""
struct Saturate{C}
    rw::C
end

function (p::Saturate{C})(x) where {C}
    n = 1
    ys = p.rw(x)
    if ys === nothing
        return nothing
    end
    terms = Set(collect(x))
    result = collect(terms)
    while length(terms) > n #TODO this should be a better BFS with an actual frontier.
        n = length(terms)
        result = collect(terms)
        for x in result
            ys = p.rw(term) 
            if ys !== nothing
                union!(terms, ys)
            end
        end
    end
    return result
end

"""
    `Presearch(rw)`

    An expander which recursively expands each node using `rw`, then returns the
    product of expanding the arguments of each element in the expansion.  If all
    expanders return `nothing`, returns `nothing`.
"""
struct Presearch{C}
    rw::C
end

function (p::Presearch{C})(x) where {C}
    ys = p.rw(x)
    if ys === nothing
        if istree(x)
            x_args = arguments(x)
            y_argss = map(p, x_args)
            if all(isnothing, y_argss)
                return nothing
            else
                ys = []
                y_argss = map(defaultexpand, map(p, x_args), x_args)
                for y_args in map(collect, product(y_argss...))
                    push!(ys, similarterm(x, operation(x), y_args))
                end
                return ys
            end
        else
            return nothing
        end
    else
        zs = []
        for y in ys
            if istree(y)
                y_args = arguments(y)
                z_argss = map(defaultexpand, map(p, y_args), y_args)
                for z_args in map(collect, product(z_argss...))
                    push!(zs, similarterm(y, operation(x), z_args))
                end
            else
                push!(zs, y)
            end
        end
        return zs
    end
end

"""
    `Postsearch(rw)`

    An expander which recursively expands the arguments of each node using `rw`,
    then attempts to expand each element in the product of such expansions.  If
    all expanders return `nothing`, returns `nothing`.
"""
struct Postsearch{C}
    rw::C
end

function (p::Postsearch{C})(x) where {C}
    if istree(x)
        x_args = arguments(x)
        y_argss = map(p, x_args)
        if all(isnothing, y_argss)
            return p.rw(x)
        else
            y_argss = map(defaultexpand, y_argss, x_args)
            zs = []
            for y_args in map(collect, product(y_argss...))
                y = similarterm(x, operation(x), y_args)
                append!(zs, defaultexpand(p.rw(y), y))
            end
            return zs
        end
    else
        return p.rw(x)
    end
end

"""
    `Branch(itr)`

    An expander which tries to expand using each expansion in `itr`. If all
    expansions return `nothing`, return `nothing`, otherwise return a list of 
    successful expansions, including the identity.
"""
struct Branch{C}
    rws::C
end

function (p::Branch{C})(x) where {C}
    ys = Any[x]
    trigger = false
    for rw in p.rws
        y = rw(x)
        if y !== nothing
            trigger = true
            push!(ys, y)
        end
    end
    return trigger ? ys : nothing
end

end # module Rewriters