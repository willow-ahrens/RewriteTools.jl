#--------------------
#--------------------
#### Terms
#--------------------
"""
    Term(f, args::AbstractArray)

Symbolic expression representing the result of calling `f(args...)`.

- `operation(t::Term)` returns `f`
- `arguments(t::Term)` returns `args`
"""
struct Term
    f::Any
    arguments::Any
end

SyntaxInterface.istree(t::Term) = true

SyntaxInterface.operation(x::Term) = x.f

SyntaxInterface.arguments(x::Term) = x.arguments

Base.isequal(::Term, x) = false
Base.isequal(x, ::Term) = false
function Base.isequal(t1::Term, t2::Term)
    t1 === t2 && return true

    a1 = arguments(t1)
    a2 = arguments(t2)

    isequal(operation(t1), operation(t2)) &&
        length(a1) == length(a2) &&
        all(isequal(l,r) for (l, r) in zip(a1,a2))
end

## This is much faster than hash of an array of Any
hashvec(xs, z) = foldr(hash, xs, init=z)

function Base.hash(t::Term, salt::UInt)
    hashvec(arguments(t), hash(operation(t), salt))
end

function term(f, args...; type = nothing)
    Term(f, [args...])
end

SyntaxInterface.similarterm(t::Type{<:Term}, f, args) = 
    Term(f, args)

#--------------------
#--------------------
####  Pretty printing
#--------------------
const show_simplified = Ref(false)

Base.show(io::IO, t::Term) = show_term(io, t)

print_arg(io, x::Union{Complex, Rational}; paren=true) = print(io, "(", x, ")")
isbinop(f) = istree(f) && !istree(operation(f)) && Base.isbinaryoperator(nameof(operation(f)))
function print_arg(io, x; paren=false)
    if paren && isbinop(x)
        print(io, "(", x, ")")
    else
        print(io, x)
    end
end
print_arg(io, s::String; paren=true) = show(io, s)
function print_arg(io, f, x)
    f !== (*) && return print_arg(io, x)
    if Base.isbinaryoperator(nameof(f))
        print_arg(io, x, paren=true)
    else
        print_arg(io, x)
    end
end

function show_call(io, f, args)
    fname = istree(f) ? Symbol(repr(f)) : nameof(f)
    binary = Base.isbinaryoperator(fname)
    if binary
        for (i, t) in enumerate(args)
            i != 1 && print(io, " $fname ")
            print_arg(io, t, paren=true)
        end
    else
        Base.show(io, f)
        print(io, "(")
        for i=1:length(args)
            print(io, args[i])
            i != length(args) && print(io, ", ")
        end
        print(io, ")")
    end
end

function show_term(io::IO, t)
    f = operation(t)
    args = arguments(t)

    show_call(io, f, args)

    return nothing
end


showraw(io, t) = Base.show(IOContext(io, :simplify=>false), t)
showraw(t) = showraw(stdout, t)

function copy_similar(d, others)
    K = promote_type(keytype(d), keytype.(others)...)
    V = promote_type(valtype(d), valtype.(others)...)
    Dict{K, V}(d)
end

_merge(f, d, others...; filter=x->false) = _merge!(f, copy_similar(d, others), others...; filter=filter)
function _merge!(f, d, others...; filter=x->false)
    acc = d
    for other in others
        for (k, v) in other
            v = f(v)
            if haskey(acc, k)
                v = acc[k] + v
            end
            if filter(v)
                delete!(acc, k)
            else
                acc[k] = v
            end
        end
    end
    acc
end

function mapvalues(f, d1::AbstractDict)
    d = copy(d1)
    for (k, v) in d
        d[k] = f(k, v)
    end
    d
end

import AbstractTrees

struct TreePrint
    op
    x
end
AbstractTrees.children(x::Term) = arguments(x)
AbstractTrees.children(x::TreePrint) = [x.x[1], x.x[2]]

print_tree(x; show_type=false, maxdepth=Inf, kw...) = print_tree(stdout, x; show_type=show_type, maxdepth=maxdepth, kw...)
function print_tree(_io::IO, x::Union{Term}; show_type=false, kw...)
    AbstractTrees.print_tree(_io, x; withinds=true, kw...) do io, y, inds
        if istree(y)
            print(io, operation(y))
        elseif y isa TreePrint
            print(io, "(", y.op, ")")
        else
            print(io, y)
        end
        if !(y isa TreePrint) && show_type
            print(io, " [", typeof(y), "]")
        end
    end
end