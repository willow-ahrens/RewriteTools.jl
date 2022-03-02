a, b, c = :a, :b, :c

using RewriteTools.Rewriters

@testset "Expand" begin
    rw = @slots a b c Postsearch(Branch([
        (@rule a + b => [term(+, b, a)]),
        (@rule a + (b + c) => [term(+, term(+, a, b), c)]),
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
        term(+, term(+, a, b), c),
        term(+, term(+, a, c), b),
    ])
    rw = Saturate(rw)
    @eqtest Set(rw(term(+, a, term(+, b, c)))) == Set([
        term(+, a, term(+, b, c)),
        term(+, a, term(+, c, b)),
        term(+, b, term(+, a, c)),
        term(+, b, term(+, c, a)),
        term(+, c, term(+, a, b)),
        term(+, c, term(+, b, a)),
        term(+, term(+, b, c), a),
        term(+, term(+, c, b), a),
        term(+, term(+, a, c), b),
        term(+, term(+, c, a), b),
        term(+, term(+, a, b), c),
        term(+, term(+, b, a), c),
    ])

    rw = @slots a b c Presearch(Branch([
        (@rule a + b => [term(+, b, a)]),
    ]))
    @eqtest Set(rw(term(-, term(+, a, b)))) == Set([
        term(-, term(+, a, b)),
        term(-, term(+, b, a)),
    ])

    @eqtest Set(rw(term(+, a, term(+, b, c)))) == Set([
        term(+, a, term(+, b, c)),
        term(+, a, term(+, c, b)),
        term(+, term(+, b, c), a),
        term(+, term(+, c, b), a),
    ])

    rw = @slots a b c Presearch(Branch([
        (@rule a + b => [term(+, b, a)]),
        (@rule a + (b + c) => [term(+, term(+, a, b), c)]),
    ]))

    @eqtest Set(rw(term(+, a, term(+, b, c)))) == Set([
        term(+, a, term(+, b, c)),
        term(+, a, term(+, c, b)),
        term(+, term(+, b, c), a),
        term(+, term(+, c, b), a),
        term(+, term(+, a, b), c),
        term(+, term(+, b, a), c),
    ])

end

@testset "Rewrite" begin
    rw = @slots a b c Postwalk(Chain([
        (@rule (a + (b * c)) => term(fma, a, b, c)),
    ]))
    @eqtest rw(term(-, term(+, a, term(*, b, c)))) == term(-, term(fma, a, b, c))

    rw = @slots a b c Fixpoint(Chain([
        (@rule (-(-a) => a)),
    ]))
    @eqtest rw(term(-, term(-, term(-, term(-, a))))) == a
end