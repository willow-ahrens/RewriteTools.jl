using SyntaxInterface: is_operation, istree, operation, similarterm, arguments, node_count

export No, IfElse, If, Chain, RestartedChain, Fixpoint, Postwalk, Prewalk, PassThrough


"""
    A rewriter is any function which takes an expression and returns an expression
or `nothing`. If `nothing` is returned that means there was no changes applicable
to the input expression. A saturator is a function which takes an expression and returns
a list of possible expansions.
"""
rewrite

"""
    NoRewrite()

    A rewriter which always returns `nothing`
"""
struct NoRewrite end

(rw::NoRewrite)(x) = nothing

"""
    NoExpand()

    An expansion which does not expand the term.
"""
struct NoSaturate end

(rw::NoSaturate)(x) = [x]

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
    `ChainExpand(itr)`

    An expander which tries to expand using each expansion in `itr`. If all
    expansions return `nothing`, return `nothing`, otherwise return a list of 
    successful expansions, including the identity.
"""
struct ChainExpand{C}
    rws::C
end

function (p::ChainExpand{C})(x) where {C}
    ys = Any[x]
    trigger = false
    for rw in p.rws
        y = rw(x)
        if y !== nothing
            trigger = true
            append!(ys, y)
        end
    end
    return trigger ? ys : nothing
end

"""
    `PostwalkExpand(rw)`

    An expander which recursively expands the arguments of each node using `rw`,
    then attempts to expand each element in the product of such expansions.  If
    all expanders return `nothing`, returns `nothing`
"""

struct PostwalkExpand{C}
    rw::C
end

defaultexpand(y, x) = y === nothing ? [x] : y

function (p::PostwalkExpand{C})(x) where {C}
    if istree(x)
        x_args = arguments(x)
        y_argss = map(p, x_args)
        if all(isnothing, y_argss)
            return p.rw(x)
        else
            y_argss = map(defaultexpand, y_argss, x_args)
            zs = []
            for y_args in map(collect, product(y_argss...))
                y = similarterm(x, operation(x), yargs)
                append!(zs, defaultexpand(p.rw(y), y))
            end
            return zs
        end
    else
        return p.rw(x)
    end
end

struct PrewalkExpand{C}
    rw::C
end

function (p::PrewalkExpand{C})(x) where {C}
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

struct PrewalkRewrite{C}
    rw::C
end

defaultrewrite(y, x) = y === nothing ? x : y

function (p::PrewalkRewrite{C})(x) where {C}
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
            return similarterm(y, operation(y), map(defaultrewrite, new_args, args))
        else
            return nothing
        end
    else
        return nothing
    end
end

struct PostwalkRewrite{C}
    rw::C
end

function (p::PostwalkRewrite{C})(x) where {C}
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



struct PrestepRewrite{C}
    rw::C
end

function (p::PrestepRewrite{C})(x) where {C}
    y = p.rw(x)
    if y !== nothing
        if istree(y)
            return similarterm(y, operation(y), map(p, arguments(y)))
        else
            return y
        end
    else
        return x
    end
end

struct ChainRewrite{C}
    rws::C
end

function (p::ChainRewrite{C})(x) where {C}
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

struct Saturate{C}
    rw::C
end

function (p::Saturate{C})(x) where {C}
    n = 1
    terms = Set(collect(p.rw(x)))
    result = collect(terms)
    while length(terms) > n
        n = length(terms)
        result = collect(terms)
        for term in result
            union!(terms, p.rw(term))
        end
    end
    return result
end

struct Fixpoint{C}
    rw::C
end

Fixpoint(rw) = Fixpoint(rw, true)

function (p::Fixpoint)(x)
    y = p.rw(x)
    if y !== nothing
        while y !== nothing && x !== y && rw.!isequal(x, y)
            x = y
            y = p.rw(x)
        end
        return x
    else
        return nothing
    end
end