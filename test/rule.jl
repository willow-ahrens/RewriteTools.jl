a, b, c = :a, :b, :c

@testset "Equality" begin
    @eqtest a == a
    @eqtest a != b
    @eqtest term(*, a, b) == term(*, a, b)
    @eqtest term(*, a, b) != a
    @eqtest a != term(*, a, b)
end

@testset "Literal Matcher" begin
    r = @rule 1 => 4
    @test r(1) === 4
    @test r(1.0) === 4
    @test r(2) === nothing

    r = @rule dollar(2) => 3
    @eqtest r(2) == 3
end

@testset "Slot matcher" begin
    @test @slots x @rule(x => true)("?") === true
    @test @slots x @rule(x => x)(2) === 2

    @test @rule(~x => true)("?") === true
    @test @rule( ~x => ~x)(2) === 2
end

@testset "Term matcher" begin
    @slots x begin
        @test @rule(sin(x) => x)(term(sin, a)) === a
        @eqtest @rule(sin(x) => x)(term(sin, term(^, a, 2))) == term(^, a, 2)
        @test @rule(sin(x) => x)(term(^, term(sin, a), 2)) === nothing
        @test @rule(sin(sin(x)) => x)(term(sin, term(^, a, 2))) === nothing
    end
    @test @slots x @rule(sin(sin(x)) => x)(term(sin, term(sin, a))) === a
    @test @slots x @rule(sin(x)^2 => x)(term(^, term(sin, a), 2)) === a

    @test @rule(sin(~x) => ~x)(term(sin, a)) === a
    @eqtest @rule(sin(~x) => ~x)(term(sin, term(^, a, 2))) == term(^, a, 2)
    @test @rule(sin(~x) => ~x)(term(^, term(sin, a), 2)) === nothing
    @test @rule(sin(sin(~x)) => ~x)(term(sin, term(^, a, 2))) === nothing
    @test @rule(sin(sin(~x)) => ~x)(term(sin, term(sin, a))) === a
    @test @rule(sin(~x)^2 => ~x)(term(^, term(sin, a), 2)) === a
end

@testset "Equality matching" begin
    @test @rule((~x)^(~x) => ~x)(term(^, a, a)) === a
    @test @rule((~x)^(~x) => ~x)(term(^, b, a)) === nothing
    @test @rule((~x)^(~x) => ~x)(term(+, a, a)) === nothing
    @eqtest @rule((~x)^(~x) => ~x)(term(^, term(sin, a), term(sin, a))) == term(sin, a)
    @eqtest @rule((~x*~y + ~x*~z)  => term(*, ~x, term(+, ~y, ~z)))(term(+, term(*, a, b), term(*, a, c))) == term(*, a, term(+, b, c))

    @eqtest @rule(+(~~x) => ~~x)(term(+, a, b)) == [a,b]
    @eqtest @rule(+(~~x) => ~~x)(term(+, a, b, c)) == [a,b,c]
    @eqtest @rule(+(~~x,~y, ~~x) => (~~x, ~y))(term(+,9,8,9,type=Any)) == ([9,],8)
    @eqtest @rule(+(~~x,~y, ~~x) => (~~x, ~y, ~~x))(term(+,9,8,9,9,8,type=Any)) == ([9,8], 9, [9,8])
    @eqtest @rule(+(~~x,~y,~~x) => (~~x, ~y, ~~x))(term(+,6,type=Any)) == ([], 6, [])

    @slots x y begin
        @eqtest @rule(+(x...) => x)(term(+, a, b)) == [a,b]
        @eqtest @rule(+(x...) => x)(term(+, a, b, c)) == [a,b,c]
        @eqtest @rule(+(x..., y, x...) => (x, y))(term(+,9,8,9,type=Any)) == ([9,],8)
    end
    @eqtest @rule(+(~x...,~y, ~x...) => (x, y, x))(term(+,9,8,9,9,8,type=Any)) == ([9,8], 9, [9,8])
    @eqtest @rule(+(~x...,~y, ~x...) => (~x, ~y, ~x))(term(+,6,type=Any)) == ([], 6, [])

    @eqtest (@slots x @rule x::iseven => x)(4) == 4
    @eqtest (@slots x @rule x::iseven => x)(5) == nothing
    alleven(x) = all(iseven.(x))
    @eqtest @rule(+(~x::alleven...) => (x...,))(term(+,9,8,type=Any)) == nothing
    @eqtest (@slots x @rule +(x::alleven...) => (x...,))(term(+,4,8,type=Any)) == (4, 8)
end

@testset "Capture form" begin
    ex = term(^, a, a)

    #note that @test inserts a soft local scope (try-catch) that would gobble
    #the matches from assignment statements in @capture macro, so we call it
    #outside the test macro 
    ret = @slots x @capture ex x^x
    @test ret
    @test @isdefined x
    @test x === a

    ex = term(^, b, a)
    ret = @capture ex (~y)^(~y)
    @test !ret
    @test !(@isdefined y)

    ret = @slots z @capture term(+, a, b) (+)(z...)
    @test ret
    @test @isdefined z
    @test all(z .=== arguments(term(+, a, b)))

    #a more typical way to use the @capture macro

    f(x) = if @capture x (~w)^(~w)
        w
    end

    @eqtest f(term(^, b, b)) == b
    @test f(term(+, b, b)) == nothing

    x = 1
    r = (@capture x x)
    @test r == true
end