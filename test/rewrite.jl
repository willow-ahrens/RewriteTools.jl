a, b, c = :a, :b, :c

using RewriteTools.Rewriters

@testset "Expand" begin
    rw = @slots a b c Postsearch(Branch([
        (@rule a + b => term(+, b, a)),
    ]))
    @eqtest Set(rw(term(+, a, b))) == Set([
        term(+, a, b),
        term(+, b, a)
    ])
    @eqtest Set(rw(term(+, a, term(+, b, c)))) == Set([
        term(+, a, term(+, b, c)),
        term(+, a, term(+, c, b)),
        term(+, term(+, b, c), a),
        term(+, term(+, c, b), a),
    ])
end

@testset "Rewrite" begin
    rw = @slots a b c Postwalk(Chain([
        (@rule (a + (b * c)) => term(fma, a, b, c))
    ]))
    @eqtest rw(term(-, term(+, a, term(*, b, c)))) == term(-, term(fma, a, b, c))
end