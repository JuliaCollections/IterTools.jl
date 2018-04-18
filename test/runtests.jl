using IterTools, Base.Test

import Base: IsInfinite, SizeUnknown, HasLength, HasShape

import Base.Iterators: take, countfrom, drop

@static if VERSION < v"0.7.0-DEV.3309"
    import Base: iteratorsize
else
    const iteratorsize = Base.IteratorSize
end

include("testing_macros.jl")

@static if VERSION < v"0.7.0-DEV.3519"
    has_shape(n) = HasShape()
else
    has_shape(n) = HasShape{n}()
end


@testset "IterTools" begin
@testset "iterators" begin
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

    @testset "chain" begin
        ch1 = chain(1:2:5, 0.2:0.1:1.6)

        @test eltype(ch1) == typejoin(Int, Float64)
        @test collect(ch1) == [1:2:5; 0.2:0.1:1.6]

        ch2 = chain(1:0, 1:2:5, 0.2:0.1:1.6)

        @test eltype(ch2) == typejoin(Int, Float64)
        @test collect(ch2) == [1:2:5; 0.2:0.1:1.6]
        @test length(ch2) == length(collect(ch2))
        @test iteratorsize(ch2) == HasLength()

        ch3 = chain(1:10, 1:10, 1:10)
        @test length(ch3) == 30
        @test iteratorsize(ch3) == HasLength()

        r = countfrom(1)
        ch4 = chain(1:10, countfrom(1))
        @test eltype(ch4) == Int
        @test_throws MethodError length(ch4)
        @assert iteratorsize(r) == IsInfinite()
        @test iteratorsize(ch4) == IsInfinite()

        ch5 = chain()
        @test length(ch5) == 0
        @test iteratorsize(ch5) == HasLength()

        c = chain(ch1, ch2, ch3)
        @test length(c) == length(ch1) + length(ch2) + length(ch3)
        @test collect(c) == [collect(ch1); collect(ch2); collect(ch3)]

        r = rand(2,2)
        c = chain(r, r)
        @test length(c) == 8
        @test collect(c) == [vec(r); vec(r)]
        @test iteratorsize(r) == has_shape(2)
        @test iteratorsize(c) == HasLength()

        r = distinct(collect(1:10))
        @test iteratorsize(r) == SizeUnknown() #lazy filtering
        c = chain(1:10, r)
        @test_throws MethodError length(c)
        @test length(collect(c)) == 20
        @test iteratorsize(c) == SizeUnknown()
    end

    @testset "product" begin
        x1 = 1:2:10
        x2 = 1:5

        p0 = product(x1, x2)

        @test eltype(p0) == Tuple{Int, Int}
        @test collect(p0) == vec([(y1, y2) for y1 in x1, y2 in x2])

        p1 = product()

        @test eltype(p1) == Tuple{}
        @test length(p1) == 1
        @test collect(p1) == [()]
    end

    @testset "distinct" begin
        x = [5, 2, 2, 1, 2, 1, 1, 2, 4, 2]
        di0 = distinct(x)
        @test eltype(di0) == Int
        @test collect(di0) == unique(x)
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
                p = Vector{NTuple{2, eltype(x)}}(binomial(length(x), 2))
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
        @testset for xs in Any[[1, 2, 3], 1:3, reshape(1:3, 3, 1)]
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


    @testset "peekiter" begin
        pi0 = peekiter(1:10)
        @test eltype(pi0) == Int
        @test collect(pi0) == collect(1:10)

        pi1 = peekiter([])
        @test eltype(pi1) == eltype([])
        @test collect(pi1) == collect([])

        it = peekiter([:a, :b, :c])
        @test eltype(it) == Symbol
        s = start(it)
        @test get(peek(it, s)) == :a

        it = peekiter([])
        s = start(it)
        @test isnull(peek(it, s))

        it = peekiter(1:10)
        s = start(it)
        x, s = next(it, s)
        @test get(peek(it, s)) == 2
    end

    @testset "along_axis" begin
        arr3by3 = reshape(1:9, (3,3))
        @test [sum(row) for row ∈ along_axis(arr3by3, 2)] == [ 6, 15, 24]
        @test [sum(col) for col ∈ along_axis(arr3by3, 1)] == [12, 15, 18]
        @test collect(rows(arr3by3))    == Any[[1, 2, 3], [4, 5, 6], [7, 8, 9]]
        @test collect(columns(arr3by3)) == Any[[1, 4, 7], [2, 5, 8], [3, 6, 9]]

        @test_throws ArgumentError along_axis(arr3by3, -1)
        @test_throws ArgumentError along_axis(arr3by3, 80)

        two_by_four = reshape(map(i->i^2, 1:2*4), 2, 4)
        @test size(rows(two_by_four))    == (4,2)
        @test size(columns(two_by_four)) == (2,4)
    end
end

@testset "Deprecated @itr" begin
    @test_take [:a, :b, :c] 2
end
end
