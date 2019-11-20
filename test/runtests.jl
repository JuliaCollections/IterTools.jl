using IterTools, SparseArrays, Test

import Base: IteratorSize, IteratorEltype
import Base: IsInfinite, SizeUnknown, HasLength, HasShape, HasEltype, EltypeUnknown

import Base.Iterators: take, countfrom, drop, peek

include("testing_macros.jl")


@testset "IterTools" begin
@testset "iterators" begin
    @testset "firstrest" begin
        # Ranges/generators have different rest states vs array/tuples
        test_base_cases = [
            (1:1, 1),
            (1:3, 1),
            ([1], 2),
            ([1, 2, 3], 2),
            ((1,), 2),
            ((1, 2, 3), 2),
            ((i for i in 1:1), 1),
            ((i for i in 1:3), 1),
        ]
        @testset "$xs" for (xs, s) in test_base_cases
            f, r = firstrest(xs)
            @test f == first(xs)
            @test collect(r) == collect(Iterators.rest(xs, s))
        end

        test_empty_cases = [
            (1:0, 1),
            (Int[], 2),
            ((), 2),
            ((i for i in 1:0), 1),
        ]

        @testset "$xs" for (xs, s) in test_empty_cases
            @test_throws ArgumentError firstrest(xs)
        end
    end

    @testset "takestrict" begin
        itr = 1:10
        take_itr = takestrict(itr, 5)
        @test eltype(take_itr) == Int
        @test IteratorEltype(take_itr) isa HasEltype
        @test IteratorSize(take_itr) isa HasLength
        @test length(take_itr) == 5
        @test collect(take_itr) == collect(1:5)

    end

    @testset "ncycle" begin
        ncy1 = ncycle(0:3,3)

        i = 0
        for j in ncy1
            @test j == i % 4
            i += 1
        end

        @test eltype(ncy1) == Int
        i = 0
        for j in collect(ncy1)
            @test j == i % 4
            i += 1
        end
    end

    @testset "repeatedly" begin
        i = 0
        for j = repeatedly(() -> 1, 10)
            @test j == 1
            i += 1
        end
        @test i == 10
        for j = repeatedly(() -> 1)
            @test j == 1
            i += 1
            i <= 10 || break
        end
    end

    @testset "distinct" begin
        x = [5, 2, 2, 1, 2, 1, 1, 2, 4, 2]
        unique_x = unique(x)
        di0 = distinct(x)
        @test eltype(di0) == Int
        @test collect(di0) == unique_x

        # repeated operations on the same Distinct iterator should function identically
        @test collect(di0) == unique_x
    end

    @testset "partition" begin
        pa0 = partition(take(countfrom(1), 6), 2)
        @test eltype(pa0) == Tuple{Int, Int}
        @test collect(pa0) == [(1,2), (3,4), (5,6)]

        pa1 = partition(take(countfrom(1), 4), 2, 1)
        @test eltype(pa1) == Tuple{Int, Int}
        @test collect(pa1) == [(1,2), (2,3), (3,4)]

        pa2 = partition(take(countfrom(1), 8), 2, 3)
        @test eltype(pa2) == Tuple{Int, Int}
        @test collect(pa2) == [(1,2), (4,5), (7,8)]

        pa3 = partition(take(countfrom(1), 0), 2, 1)
        @test eltype(pa3) == Tuple{Int, Int}
        @test collect(pa3) == []

        pa4 = partition(1:8, 1)
        @test eltype(pa4) == Tuple{Int}
        @test collect(pa4) == [(1,), (2,), (3,), (4,), (5,), (6,), (7,), (8,)]

        @test_throws ArgumentError partition(take(countfrom(1), 8), 2, 0)
    end

    @testset "imap" begin
        function test_imap(expected, input...)
            result = collect(imap(+, input...))
            @test result == expected
        end

        @testset "empty arrays" begin
            test_imap(
                Any[],
                []
            )

            test_imap(
                Any[],
                Union{}[]
            )
        end

        @testset "simple operation" begin
            test_imap(
                Any[1,2,3],
                [1,2,3]
            )
        end

        @testset "multiple arguments" begin
            test_imap(
                Any[5,7,9],
                [1,2,3],
                [4,5,6]
            )
        end

        @testset "different-length arguments" begin
            test_imap(
                Any[2,4,6],
                [1,2,3],
                countfrom(1)
            )
        end
    end


    @testset "groupby" begin
        function test_groupby(input, expected)
            result = collect(groupby(x -> x[1], input))
            @test result == expected
        end

        @testset "empty arrays" begin
            test_groupby(
                [],
                Any[]
            )

            test_groupby(
                Union{}[],
                Any[]
            )
        end

        @testset "singletons" begin
            test_groupby(
                ["xxx"],
                Any[["xxx"]]
            )
        end

        @testset "typical operation" begin
            test_groupby(
                ["face", "foo", "bar", "book", "baz"],
                Any[["face", "foo"], ["bar", "book", "baz"]]
            )
        end

        @testset "trailing singletons" begin
            test_groupby(
                ["face", "foo", "bar", "book", "baz", "xxx"],
                Any[["face", "foo"], ["bar", "book", "baz"], ["xxx"]]
            )
        end

        @testset "leading singletons" begin
            test_groupby(
                ["xxx", "face", "foo", "bar", "book", "baz"],
                Any[["xxx"], ["face", "foo"], ["bar", "book", "baz"]]
            )
        end

        @testset "middle singletons" begin
            test_groupby(
                ["face", "foo", "xxx", "bar", "book", "baz"],
                Any[["face", "foo"], ["xxx"], ["bar", "book", "baz"]]
            )
        end
    end

    @testset "subsets" begin
        @testset "all lengths" begin
            s0 = subsets(Any[])
            @test eltype(eltype(s0)) == Any
            @test collect(s0) == Vector{Any}[Any[]]

            s1 = subsets([:a])
            @test eltype(eltype(s1)) == Symbol
            @test collect(s1) == Vector{Symbol}[Symbol[], Symbol[:a]]

            s2 = subsets([:a, :b, :c])
            @test eltype(eltype(s2)) == Symbol
            @test collect(s2) == Vector{Symbol}[
                Symbol[], Symbol[:a], Symbol[:b], Symbol[:a, :b], Symbol[:c],
                Symbol[:a, :c], Symbol[:b, :c], Symbol[:a, :b, :c],
            ]
        end

        @testset "specific length" begin
            sk0 = subsets(Any[],0)
            @test eltype(eltype(sk0)) == Any
            @test collect(sk0) == Vector{Any}[Any[]]

            sk1 = subsets([:a, :b, :c], 1)
            @test eltype(eltype(sk1)) == Symbol
            @test collect(sk1) == Vector{Symbol}[Symbol[:a], Symbol[:b], Symbol[:c]]

            sk2 = subsets([:a, :b, :c], 2)
            @test eltype(eltype(sk2)) == Symbol
            @test collect(sk2) == Vector{Symbol}[Symbol[:a,:b], Symbol[:a,:c], Symbol[:b,:c]]

            sk3 = subsets([:a, :b, :c], 3)
            @test eltype(eltype(sk3)) == Symbol
            @test collect(sk3) == Vector{Symbol}[Symbol[:a,:b,:c]]

            sk4 = subsets([:a, :b, :c], 4)
            @test eltype(eltype(sk4)) == Symbol
            @test collect(sk4) == Vector{Symbol}[]

            @testset for i in 1:5
                sk5 = subsets(collect(1:4), i)
                @test eltype(eltype(sk5)) == Int
                @test length(collect(sk5)) == binomial(4, i)
            end

            @testset "implicit conversions" begin
                sk10 = subsets(1:4, 3)
                @test eltype(eltype(sk10)) == Int
                @test length(collect(sk10)) == binomial(4, 3)

                sk11 = subsets(1:3, Int32(2))
                @test eltype(eltype(sk11)) == Int
                @test length(collect(sk11)) == binomial(3, 2)
            end
        end

        @testset "specific static length" begin
            sk0 = subsets([:a, :b, :c], Val{0}())
            @test collect(sk0) == [()]

            sk1 = subsets([:a, :b, :c], Val{1}())
            @test eltype(eltype(sk1)) == Symbol
            @test collect(sk1) == [(:a,), (:b,), (:c,)]

            sk2 = subsets([:a, :b, :c], Val{2}())
            @test eltype(eltype(sk2)) == Symbol
            @test collect(sk2) == [(:a, :b), (:a, :c), (:b, :c)]

            sk3 = subsets([:a, :b, :c], Val{3}())
            @test eltype(eltype(sk3)) == Symbol
            @test collect(sk3) == [(:a, :b, :c)]

            sk4 = subsets([:a, :b, :c], Val{4}())
            @test eltype(eltype(sk4)) == Symbol
            @test collect(sk4) == []

            sk5 = subsets([:a, :b, :c], Val{5}())
            @test eltype(eltype(sk5)) == Symbol
            @test collect(sk5) == []

            @testset for i in 1:6
                sk5 = subsets(collect(1:4), Val{i}())
                @test eltype(eltype(sk5)) == Int
                @test length(collect(sk5)) == binomial(4, i)
            end

            function collect_pairs(x)
                p = Vector{NTuple{2, eltype(x)}}(undef, binomial(length(x), 2))
                idx = 1
                for i = 1:length(x)
                    for j = i+1:length(x)
                        p[idx] = (x[i], x[j])
                        idx += 1
                    end
                end
                return p
            end
            @testset for n = 1:10
                @test collect(subsets(1:n, Val{2}())) == collect_pairs(1:n)
            end
        end
    end

    @testset "nth" begin
        @testset for xs in Any[
            [1, 2, 3],
            1:3,
            reshape(1:3, 3, 1),
            sparse(reshape(1:3, 1, 3)),
        ]
            @test nth(xs, 3) == 3
            @test_throws BoundsError nth(xs, 0)
            @test_throws BoundsError nth(xs, 4)
        end

        @testset for xs in Any[take(1:3, 3), drop(-1:3, 2)]
            @test nth(xs, 3) == 3
            @test_throws BoundsError nth(xs, 0)
        end

        s = subsets([1, 2, 3])
        @test_throws BoundsError nth(s, 0)
        @test_throws BoundsError nth(s, length(s) + 1)

        # #100
        @test nth(drop(repeatedly(() -> 1), 1), 1) == 1
    end


    @testset "takenth" begin
        tn0 = takenth(Any[], 10)
        @test eltype(tn0) == Any
        @test collect(tn0) == Any[]

        tn1 = takenth(Int[], 10)
        @test eltype(tn1) == Int
        @test collect(tn1) == Int[]

        @test_throws ArgumentError takenth([], 0)

        tn2 = takenth(10:20, 3)
        @test eltype(tn2) == Int
        @test collect(tn2) == [12,15,18]

        tn3 = takenth(10:20, 1)
        @test eltype(tn3) == Int
        @test collect(tn3) == collect(10:20)
    end


    @testset "iterated" begin
        times_called = Ref(0)

        function iter_func(x)
            times_called[] += 1
            x + 1
        end

        itd = iterated(iter_func, 3)
        @test IteratorSize(itd) isa IsInfinite
        @test collect(take(itd, 4)) == 3:6
        # the first item is just the seed so iter_func isn't called
        @test times_called[] == 3
    end


    @testset "peekiter" begin
        pi0 = peekiter(1:10)
        @test IteratorEltype(pi0) isa HasEltype
        @test eltype(pi0) == Int
        @test collect(pi0) == collect(1:10)

        pi1 = peekiter([])
        @test IteratorEltype(pi1) isa HasEltype
        @test eltype(pi1) == eltype([])
        @test collect(pi1) == collect([])

        it = peekiter([:a, :b, :c])
        @test IteratorEltype(it) isa HasEltype
        @test eltype(it) == Symbol
        x, s = iterate(it)
        @test x == :a
        @test peek(it, s) == Some(:b)

        @test iterate(peekiter([])) === nothing

        it = peekiter(1:10)
        x, s = iterate(it)
        @test x == 1
        @test peek(it, s) == Some(2)

        it = peekiter(1:1)
        x, s = iterate(it)
        @test x == 1
        @test peek(it, s) === nothing
        @test iterate(it, s) === nothing
    end

    @testset "ivec" begin
        irange = 1:12
        vector = collect(irange)
        @test collect(ivec(irange)) == vector
        @test collect(ivec(vector)) == vector

        matrix = reshape(vector, 3, 4)
        @test collect(ivec(matrix)) == vector

        ndarray = reshape(vector, 2, 2, 3)
        @test collect(ivec(ndarray)) == vector
    end

    @testset "flagfirst" begin
        v = rand(1:10, 20)
        Tv = typeof(v)
        ff = flagfirst(v)
        Tff = typeof(ff)
        @test IteratorEltype(Tff) ≡ IteratorEltype(v)
        @test eltype(Tff) ≡ Tuple{Bool, eltype(v)}
        @test collect(flagfirst(v)) ==
            collect(zip(vcat([true], fill(false, length(v) - 1)), v))

        @test collect(flagfirst(Int[])) == Tuple{Bool,Int}[]
    end

    @testset "takewhile" begin
        @test collect(takewhile(x -> x^2 < 10, 1:10)) == Any[1, 2, 3]
        @test collect(takewhile(x -> x^2 < 10, Iterators.countfrom(1))) == Any[1, 2, 3]
        @test collect(takewhile(x -> x^2 < 10, 5:10)) == Any[]
        @test collect(takewhile(x -> true, 5:10)) == collect(5:10)
    end

    @testset "properties" begin
        p1 = properties(1 + 2im)
        @test IteratorEltype(p1) isa HasEltype
        @test eltype(p1) == Any
        @test IteratorSize(p1) isa HasLength
        @test length(p1) == 2
        @test collect(p1) == Any[(:re, 1), (:im, 2)]

        ntp = (a = "", b = 1, c = 2.0)
        p2 = properties(ntp)
        @test collect(p2) == Tuple.(collect(pairs(ntp)))

         # HasLength used as an example no-field struct
        p3 = properties(HasLength())
        @test collect(p3) == Any[]
    end

    @testset "propertyvalues" begin
        pv1 = propertyvalues(1 + 2im)
        @test IteratorEltype(pv1) isa HasEltype
        @test eltype(pv1) == Any
        @test IteratorSize(pv1) isa HasLength
        @test length(pv1) == 2
        @test collect(pv1) == Any[1, 2]

        tp = ("", 1, 2.0)
        pv2 = propertyvalues(tp)

        # getproperty for tuples wasn't introduced until 1.2
        # https://github.com/JuliaLang/julia/pull/31324
        @static if VERSION < v"1.2.0-DEV.460"
            @test_broken collect(pv2) == collect(tp)
        else
            @test collect(pv2) == collect(tp)
        end

        # HasLength used as an example no-field struct
        pv3 = propertyvalues(HasLength())
        @test collect(pv3) == Any[]
    end

    @testset "fieldvalues" begin
        fv1 = fieldvalues(1 + 2im)
        @test IteratorEltype(fv1) isa HasEltype
        @test eltype(fv1) == Any
        @test IteratorSize(fv1) isa HasLength
        @test length(fv1) == 2
        @test collect(fv1) == Any[1, 2]

        tp = ("", 1, 2.0)
        fv2 = fieldvalues(tp)
        @test collect(fv2) == collect(tp)

        # HasLength used as an example no-field struct
        fv3 = fieldvalues(HasLength())
        @test collect(fv3) == Any[]
    end
end
end
