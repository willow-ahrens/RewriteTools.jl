a, b, c = :a, :b, :c

using RewriteTools.Rewriters

@testset "Saturate" begin
    rw = @slots a b c Postsearch(Branch([
        (@rule a + b => term(+, b, a)),
        (@rule ((a + b) + c) => term(+, a, term(+, b, c)))
    ]))
    @eqtest Set(rw(term(+, a, b))) == Set([
        term(+, a, b),
        term(+, b, a)
    ])
end

@testset "Transform" begin
    rw = @slots a b c Postwalk(Chain([
        (@rule (a + (b * c)) => term(fma, a, b, c))
    ]))
    @eqtest rw(term(-, term(+, a, term(*, b, c)))) == term(-, term(fma, a, b, c))
end