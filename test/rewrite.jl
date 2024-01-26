a, b, c = :a, :b, :c

using RewriteTools.Rewriters

@testset "Rewrite" begin
    rw = Postwalk(Chain([
        (@rule (~a + (~b * ~c)) => term(fma, a, b, c)),
    ]))
    @eqtest rw(term(-, term(+, a, term(*, b, c)))) == term(-, term(fma, a, b, c))

    rw = Fixpoint(Chain([
        (@rule (-(-~a) => a)),
    ]))
    @eqtest rw(term(-, term(-, term(-, term(-, a))))) == a
end