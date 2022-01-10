#--------------------
#--------------------
#### Symbolic
#--------------------
abstract type Symbolic{T} end


Base.isequal(::Symbolic, x) = false
Base.isequal(x, ::Symbolic) = false
Base.isequal(::Symbolic, ::Symbolic) = false

#--------------------
#--------------------
#### Terms
#--------------------
"""
    Term{T}(f, args::AbstractArray)

or
    Term(f, args::AbstractArray)

Symbolic expression representing the result of calling `f(args...)`.

- `operation(t::Term)` returns `f`
- `arguments(t::Term)` returns `args`
- `symtype(t::Term)` returns `T`

If `T` is not provided during construction, it is queried by calling
`SymbolicUtils.promote_symtype(f, map(symtype, args)...)`.

See [promote_symtype](#promote_symtype)
"""
struct Term
    f::Any
    arguments::Any
end

function ConstructionBase.constructorof(s::Type{Term})
    function (f, args, meta, hash)
        Term{T, typeof(meta)}(f, args, meta, hash)
    end
end

function (::Type{Term})(f, args)
    Term(f, args, Ref{UInt}(0))
end

TermInterface.istree(t::Type{<:Term}) = true

function Term(f, args)
    Term{_promote_symtype(f, args)}(f, args)
end

TermInterface.operation(x::Term) = getfield(x, :f)

unsorted_arguments(x) = TermInterface.arguments(x)
TermInterface.arguments(x::Term) = getfield(x, :arguments)

function Base.isequal(t1::Term, t2::Term)
    t1 === t2 && return true
    symtype(t1) !== symtype(t2) && return false

    a1 = arguments(t1)
    a2 = arguments(t2)

    isequal(operation(t1), operation(t2)) &&
        length(a1) == length(a2) &&
        all(isequal(l,r) for (l, r) in zip(a1,a2))
end

## This is much faster than hash of an array of Any
hashvec(xs, z) = foldr(hash, xs, init=z)

function Base.hash(t::Term, salt::UInt)
    !iszero(salt) && return hash(hash(t, zero(UInt)), salt)
    h = t.hash[]
    !iszero(h) && return h
    h′ = hashvec(arguments(t), hash(operation(t), salt))
    t.hash[] = h′
    return h′
end

function term(f, args...; type = nothing)
    Term(f, [args...])
end

"""
    similarterm(t, f, args, symtype; metadata=nothing)

Create a term that is similar in type to `t`. Extending this function allows packages
using their own expression types with SymbolicUtils to define how new terms should
be created. Note that `similarterm` may return an object that has a
different type than `t`, because `f` also influences the result.

## Arguments

- `t` the reference term to use to create similar terms
- `f` is the operation of the term
- `args` is the arguments
- The `symtype` of the resulting term. Best effort will be made to set the symtype of the
  resulting similar term to this type.
"""
TermInterface.similarterm(t::Type{Term}, f, args, symtype; metadata=nothing) = 
    Term(f, args)

#--------------------
#--------------------
####  Pretty printing
#--------------------
const show_simplified = Ref(false)

Base.show(io::IO, t::Term) = show_term(io, t)

isnegative(t::Real) = t < 0
function isnegative(t)
    if istree(t) && operation(t) === (*)
        coeff = first(arguments(t))
        return isnegative(coeff)
    end
    return false
end

setargs(t, args) = Term{symtype(t)}(operation(t), args)
cdrargs(args) = setargs(t, cdr(args))

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

function remove_minus(t)
    !istree(t) && return -t
    @assert operation(t) == (*)
    args = arguments(t)
    @assert args[1] < 0
    [-args[1], args[2:end]...]
end

function show_add(io, args)
    negs = filter(isnegative, args)
    nnegs = filter(!isnegative, args)
    for (i, t) in enumerate(nnegs)
        i != 1 && print(io, " + ")
        print_arg(io, +,  t)
    end

    for (i, t) in enumerate(negs)
        if i==1 && isempty(nnegs)
            print_arg(io, -, t)
        else
            print(io, " - ")
            show_mul(io, remove_minus(t))
        end
    end
end

function show_pow(io, args)
    base, ex = args

    if base isa Real && base < 0
        print(io, "(")
        print_arg(io, base)
        print(io, ")")
    else
        print_arg(io, base, paren=true)
    end
    print(io, "^")
    print_arg(io, ex, paren=true)
end

function show_mul(io, args)
    length(args) == 1 && return print_arg(io, *, args[1])

    minus = args[1] isa Number && args[1] == -1
    unit = args[1] isa Number && args[1] == 1

    paren_scalar = (args[1] isa Complex && !_iszero(imag(args[1]))) ||
                   args[1] isa Rational ||
                   (args[1] isa Number && !isfinite(args[1]))

    nostar = minus || unit ||
            (!paren_scalar && args[1] isa Number && !(args[2] isa Number))

    for (i, t) in enumerate(args)
        if i != 1
            if i==2 && nostar
            else
                print(io, "*")
            end
        end
        if i == 1 && minus
            print(io, "-")
        elseif i == 1 && unit
        else
            print_arg(io, *, t)
        end
    end
end

function show_ref(io, f, args)
    x = args[1]
    idx = args[2:end]

    istree(x) && print(io, "(")
    print(io, x)
    istree(x) && print(io, ")")
    print(io, "[")
    for i=1:length(idx)
        print_arg(io, idx[i])
        i != length(idx) && print(io, ", ")
    end
    print(io, "]")
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
        if f isa Sym
            Base.show_unquoted(io, nameof(f))
        else
            Base.show(io, f)
        end
        print(io, "(")
        for i=1:length(args)
            print(io, args[i])
            i != length(args) && print(io, ", ")
        end
        print(io, ")")
    end
end

function show_term(io::IO, t)
    if get(io, :simplify, show_simplified[])
        return print(IOContext(io, :simplify=>false), simplify(t))
    end

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

TermInterface.istree(t::Type{<:Symbolic}) = true
