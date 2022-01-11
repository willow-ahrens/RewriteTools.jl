using RewriteTools: Term, operation, arguments
using RewriteTools
using Test

@testset "hashing" begin
    (f, a, b) = (:f, :a, :b)
    @test hash(a) == hash(a)
    @test hash(a) != hash(b)
    @test hash(term(+, a, 1)) == hash(term(+, a, 1))
    @test hash(term(f, a, 1)) == hash(term(f, a, 1))
    @test hash(term(f, a, 1)) != hash(term(+, a, 1))

    @test hash(term(+, a, b), UInt(0)) === hash(term(+, a, b)) === hash(term(+, a, b), UInt(0)) # test caching
    @test hash(term(+, a, b), UInt(2)) !== hash(term(+, a, b))
end