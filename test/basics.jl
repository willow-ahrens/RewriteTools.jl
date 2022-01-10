using SymbolicUtils: Sym, FnType, Term, symtype, operation, arguments
using SymbolicUtils
using IfElse: ifelse
using Test

Base.:+(a::Sym, b::Number) = term(+, a, b)
Base.:+(a::Number, b::Sym) = term(+, a, b)
Base.:+(a::Sym, b::Sym) = term(+, a, b)
Base.:*(a::Sym, b::Number) = term(*, a, b)
Base.:*(a::Number, b::Sym) = term(*, a, b)
Base.:*(a::Sym, b::Sym) = term(*, a, b)
Base.:/(a::Sym, b::Number) = term(*, a, b)
Base.:/(a::Number, b::Sym) = term(*, a, b)
Base.:/(a::Sym, b::Sym) = term(*, a, b)

@testset "@syms" begin
    let
        @syms a b::Float64 f(::Real) g(p, h(q::Real))::Int

        @test a isa Sym{Number}
        @test a.name === :a

        @test b isa Sym{Float64}
        @test b.name === :b

        @test f isa Sym{FnType{Tuple{Real}, Number}}
        @test f.name === :f

        @test g isa Sym{FnType{Tuple{Number, FnType{Tuple{Real}, Number}}, Int}}
        @test g.name === :g

        @test f(b) isa Term
        @test symtype(f(b)) === Number
        @test_throws ErrorException f(a)

        @test g(b, f) isa Term
        @test_throws ErrorException g(b, a)

        @test symtype(g(b, f)) === Int

        # issue #91
        @syms h(a,b,c)
        @test isequal(h(1,2,3), h(1,2,3))
    end
end

@testset "hashing" begin
    @syms a b f(x, y)
    @test hash(a) == hash(a)
    @test hash(a) != hash(b)
    @test hash(term(+, a, 1)) == hash(term(+, a, 1))
    @test hash(term(f, a, 1)) == hash(term(f, a, 1))
    @test hash(term(f, a, 1)) != hash(term(+, a, 1))

    ex = term(*, term(+, a, 1), 2)
    h = hash(ex, UInt(0))
    @test ex.hash[] == h

    ex = term(-, term(*, b, a))
    h = hash(ex, UInt(0))
    @test ex.hash[] == h

    @syms a b
    @test hash(term(+, a, b), UInt(0)) === hash(term(+, a, b)) === hash(term(+, a, b), UInt(0)) # test caching
    @test hash(term(+, a, b), UInt(2)) !== hash(term(+, a, b))
end