using Iterators, Base.Test

if VERSION >= v"0.5.0-dev+3305"
	import Base: IsInfinite, SizeUnknown, HasLength, iteratorsize, HasShape
end

# gets around deprecation warnings in v0.6
if isdefined(Base, :Iterators)
    import Base.Iterators: drop, countfrom, cycle, take, repeated
end

# count
# -----

i = 0
c0 = countfrom(0, 2)

@test eltype(c0) == Int

for j in c0
	@test j == i*2
	i += 1
	i <= 10 || break
end

# take
# ----

t = take(0:2:8, 10)

@test length(collect(t)) == 5
@test eltype(t) == Int

i = 0
for j = t
	@test j == i*2
	i += 1
end
@test i == 5

i = 0
for j = take(0:2:100, 10)
	@test j == i*2
	i += 1
end
@test i == 10

# drop
# ----

d0 = drop(0:2:10, 2)

@test eltype(d0) == Int

i = 0
for j in d0
	@test j == (i+2)*2
	i += 1
end
@test i == 4

# cycle
# -----

cy1 = cycle(0:3)

@test eltype(cy1) == Int

i = 0
for j in cy1
	@test j == i % 4
	i += 1
	i <= 10 || break
end

# ncycle
# ------

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

# repeated
# --------

r0 = repeated(1, 10)

@test eltype(r0) == Int

i = 0
for j in r0
	@test j == 1
	i += 1
end
@test i == 10

r1 = repeated(1)

@test eltype(r1) == Int

i = 0
for j in r1
	@test j == 1
	i += 1
	i <= 10 || break
end

# repeatedly
# ----------

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

# chain
# -----

ch1 = chain(1:2:5, 0.2:0.1:1.6)

@test eltype(ch1) == typejoin(Int, Float64)
@test collect(ch1) == [1:2:5; 0.2:0.1:1.6]

ch2 = chain(1:0, 1:2:5, 0.2:0.1:1.6)

@test eltype(ch2) == typejoin(Int, Float64)
@test collect(ch2) == [1:2:5; 0.2:0.1:1.6]
@test length(ch2) == length(collect(ch2))
if VERSION >= v"0.5.0-dev+3305"
	@test iteratorsize(ch2) == HasLength()
end

ch3 = chain(1:10, 1:10, 1:10)
@test length(ch3) == 30
if VERSION >= v"0.5.0-dev+3305"
	@test iteratorsize(ch3) == HasLength()
end

r = countfrom(1)
ch4 = chain(1:10, countfrom(1))
@test eltype(ch4) == Int
@test_throws MethodError length(ch4)
if VERSION >= v"0.5.0-dev+3305"
	@assert iteratorsize(r) == IsInfinite()
	@test iteratorsize(ch4) == IsInfinite()
end

ch5 = chain()
@test length(ch5) == 0
if VERSION >= v"0.5.0-dev+3305"
	@test iteratorsize(ch5) == HasLength()
end

c = chain(ch1, ch2, ch3)
@test length(c) == length(ch1) + length(ch2) + length(ch3)
@test collect(c) == [collect(ch1); collect(ch2); collect(ch3)]

r = rand(2,2)
c = chain(r, r)
@test length(c) == 8
@test collect(c) == [vec(r); vec(r)]
if VERSION >= v"0.5.0-dev+3305"
	@test iteratorsize(r) == HasShape()
	@test iteratorsize(c) == HasLength()
end

if VERSION >= v"0.5.0-dev+3305"
	r = distinct(collect(1:10))
	@test iteratorsize(r) == SizeUnknown() #lazy filtering
	c = chain(1:10, r)
	@test_throws MethodError length(c)
	@test length(collect(c)) == 20
	@test iteratorsize(c) == SizeUnknown()
end

# product
# -------

x1 = 1:2:10
x2 = 1:5

p0 = product(x1, x2)

@test eltype(p0) == Tuple{Int, Int}
@test collect(p0) == vec([(y1, y2) for y1 in x1, y2 in x2])

p1 = product()

@test eltype(p1) == Tuple{}
@test length(p1) == 1
@test collect(p1) == [()]

# distinct
# --------

x = [5, 2, 2, 1, 2, 1, 1, 2, 4, 2]
di0 = distinct(x)
@test eltype(di0) == Int
@test collect(di0) == unique(x)

# partition
# ---------

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

# imap
# ----

function test_imap(expected, input...)
    result = collect(imap(+, input...))
    @test result == expected
end


# Empty arrays
test_imap(
    Any[],
    []
)

test_imap(
    Any[],
    Union{}[]
)

# Simple operation
test_imap(
    Any[1,2,3],
    [1,2,3]
)

# Multiple arguments
test_imap(
    Any[5,7,9],
    [1,2,3],
    [4,5,6]
)

# Different-length arguments
test_imap(
    Any[2,4,6],
    [1,2,3],
    countfrom(1)
)


# groupby
# -------

function test_groupby(input, expected)
    result = collect(groupby(x -> x[1], input))
    @test result == expected
end


# Empty arrays
test_groupby(
    [],
    Any[]
)

test_groupby(
    Union{}[],
    Any[]
)

# Singletons
test_groupby(
    ["xxx"],
    Any[["xxx"]]
)

# Typical operation
test_groupby(
    ["face", "foo", "bar", "book", "baz"],
    Any[["face", "foo"], ["bar", "book", "baz"]]
)

# Trailing singletons
test_groupby(
    ["face", "foo", "bar", "book", "baz", "xxx"],
    Any[["face", "foo"], ["bar", "book", "baz"], ["xxx"]]
)

# Leading singletons
test_groupby(
    ["xxx", "face", "foo", "bar", "book", "baz"],
    Any[["xxx"], ["face", "foo"], ["bar", "book", "baz"]]
)

# Middle singletons
test_groupby(
    ["face", "foo", "xxx", "bar", "book", "baz"],
    Any[["face", "foo"], ["xxx"], ["bar", "book", "baz"]]
)


# subsets
# -------

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


# subsets of size k
# -----------------

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

sk5 = subsets(collect(1:4), 1)
@test eltype(eltype(sk5)) == Int
@test length(collect(sk5)) == binomial(4,1)

sk6 = subsets(collect(1:4), 2)
@test eltype(eltype(sk6)) == Int
@test length(collect(sk6)) == binomial(4,2)

sk7 = subsets(collect(1:4), 3)
@test eltype(eltype(sk7)) == Int
@test length(collect(sk7)) == binomial(4,3)

sk8 = subsets(collect(1:4), 4)
@test eltype(eltype(sk8)) == Int
@test length(collect(sk8)) == binomial(4,4)

sk9 = subsets(collect(1:4), 5)
@test eltype(eltype(sk9)) == Int
@test length(collect(sk9)) == binomial(4,5)

# Implicit conversions
sk10 = subsets(1:4, 3)
@test eltype(eltype(sk10)) == Int
@test length(collect(sk10)) == binomial(4, 3)

sk11 = subsets(1:3, Int32(2))
@test eltype(eltype(sk11)) == Int
@test length(collect(sk11)) == binomial(3, 2)


# nth element
# -----------
for xs in Any[[1, 2, 3], 1:3, reshape(1:3, 3, 1)]
    @test nth(xs, 3) == 3
    @test_throws BoundsError nth(xs, 0)
    @test_throws BoundsError nth(xs, 4)
end

for xs in Any[take(1:3, 3), drop(-1:3, 2)]
    @test nth(xs, 3) == 3
    @test_throws BoundsError nth(xs, 0)
end

s = subsets([1, 2, 3])
@test_throws BoundsError nth(s, 0)
@test_throws BoundsError nth(s, length(s) + 1)

# #100
nth(drop(repeatedly(() -> 1), 1), 1)


# Every nth
# ---------

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


# peekiter
# --------
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


## @itr
## ====

# @zip
# ----

macro test_zip(input...)
    n = length(input)
    x = Expr(:tuple, ntuple(i->gensym(), n)...)
    v = Expr(:tuple, map(esc, input)...)
    w = :(zip($(map(esc, input)...)))
    quote
	br = Any[]
	for $x in zip($v...)
	    push!(br, $x)
	end
	mr = Any[]
	@itr for $x in $w
	    push!(mr, $x)
	end
	@test br == mr
    end
end

@test_zip [1,2,3] [:a, :b, :c] ['x', 'y', 'z']
@test_zip [1,2,3] [:a, :b] ['w', 'x', 'y', 'z']
@test_zip [1,2,3] Any[] ['w', 'x', 'y', 'z']
@test_zip [1,2,3] Union{}[] ['w', 'x', 'y', 'z']

# @enumerate
# ----------

macro test_enumerate(input)
    i = gensym()
    x = gensym()
    v = esc(input)
    quote
	br = Any[]
	for ($i,$x) in enumerate($v)
	    push!(br, ($i,$x))
	end
	mr = Any[]
	@itr for ($i,$x) in enumerate($v)
	    push!(mr, ($i,$x))
	end
	@test br == mr
    end
end

@test_enumerate [:a, :b, :c]
@test_enumerate Union{}[]
@test_enumerate Any[]

# @take
# -----

macro test_take(input, n)
    x = gensym()
    v = esc(input)
    quote
	br = Any[]
	for $x in take($v, $n)
	    push!(br, $x)
	end
	mr = Any[]
	@itr for $x in take($v, $n)
	    push!(mr, $x)
	end
	@test br == mr
    end
end

@test_take [:a, :b, :c] 2
@test_take [:a, :b, :c] 5
@test_take [:a, :b, :c] 0
@test_take Any[] 2
@test_take Union{}[] 2
@test_take Any[] 0
@test_take [(:a,1), (:b,2), (:c,3)] 2

# @takestrict
# -----

macro test_takestrict(input, n)
    x = gensym()
    v = esc(input)
    quote
	br = Any[]
	bfailed = false
	try
	    for $x in takestrict($v, $n)
		push!(br, $x)
	    end
	catch
	    bfailed = true
	end

	mr = Any[]
	mfailed = false
	try
	    @itr for $x in takestrict($v, $n)
		push!(mr, $x)
	    end
	catch
	    mfailed = true
	end
	@test br == mr
	@test bfailed == mfailed
    end
end

@test_takestrict [:a, :b, :c] 2
@test_takestrict [:a, :b, :c] 3
@test_takestrict [:a, :b, :c] 5
@test_takestrict [:a, :b, :c] 0
@test_takestrict Any[] 2
@test_takestrict Union{}[] 2
@test_takestrict Any[] 0
@test_takestrict [(:a,1), (:b,2), (:c,3)] 2
@test_takestrict [(:a,1), (:b,2), (:c,3)] 3
@test_takestrict [(:a,1), (:b,2), (:c,3)] 4

# @drop
# -----

macro test_drop(input, n)
    x = gensym()
    v = esc(input)
    quote
	br = Any[]
	for $x in drop($v, $n)
	    push!(br, $x)
	end
	mr = Any[]
	@itr for $x in drop($v, $n)
	    push!(mr, $x)
	end
	@test br == mr
    end
end

@test_drop [:a, :b, :c] 2
@test_drop [:a, :b, :c] 5
@test_drop [:a, :b, :c] 0
@test_drop Any[] 2
@test_drop Union{}[] 2
@test_drop Any[] 0
@test_drop [(:a,1), (:b,2), (:c,3)] 2

# @chain
# -----

macro test_chain(input...)
    x = gensym()
    v = Expr(:tuple, map(esc, input)...)
    w = :(chain($(map(esc, input)...)))
    quote
	br = Any[]
	for $x in chain($v...)
	    push!(br, $x)
	end
	mr = Any[]
	@itr for $x in $w
	    push!(mr, $x)
	end
	@test br == mr
    end
end

@test_chain [1,2,3] [:a, :b, :c] ['x', 'y', 'z']
@test_chain [1,2,3] [:a, :b] ['w', 'x', 'y', 'z']
@test_chain [1,2,3] Any[] ['w', 'x', 'y', 'z']
@test_chain [1,2,3] Union{}[] ['w', 'x', 'y', 'z']
@test_chain [1,2,3] 4 [('w',3), ('x',2), ('y',1), ('z',0)]
