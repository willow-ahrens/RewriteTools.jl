a, b, c = :a, :b, :c

using RewriteTools.Rewriters

@testset "Rewrite" begin
    rw = Postwalk(Chain([
        (@rule (~a + (~b * ~c)) => term(fma, a, b, c)),
    ]))
    @eqtest rw(term(-, term(+, a, term(*, b, c)))) == term(-, term(fma, a, b, c))

    cache = Dict()
    rw = Postwalk(Memo(Chain([
        (@rule (~a + (~b * ~c)) => term(fma, a, b, c)),
    ]), cache))

    @eqtest rw(term(-, term(+, a, term(*, b, c)))) == term(-, term(fma, a, b, c))

    @test haskey(cache, term(+, a, term(*, b, c)))

    rw = Fixpoint(Chain([
        (@rule (-(-~a) => a)),
    ]))
    @eqtest rw(term(-, term(-, term(-, term(-, a))))) == a

end