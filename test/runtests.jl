using Iterators, Base.Test
using Compat

# count
# -----

i = 0
for j = countfrom(0, 2)
	@test j == i*2
	i += 1
	i <= 10 || break
end

# take
# ----

t = take(0:2:8, 10)

@test length(collect(t)) == 5

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

i = 0
for j = drop(0:2:10, 2)
	@test j == (i+2)*2
	i += 1
end
@test i == 4

# cycle
# -----

i = 0
for j = cycle(0:3)
	@test j == i % 4
	i += 1
	i <= 10 || break
end

# repeated
# --------

i = 0
for j = repeated(1, 10)
	@test j == 1
	i += 1
end
@test i == 10
i = 0
for j = repeated(1)
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

@test collect(chain(1:2:5, 0.2:0.1:1.6)) == [1:2:5; 0.2:0.1:1.6]

# product
# -------

x1 = 1:2:10
x2 = 1:5
@test collect(product(x1, x2)) == vec([(y1, y2) for y1 in x1, y2 in x2])

@test length(product()) == 1
@test collect(product()) == [()]

# distinct
# --------

x = [5, 2, 2, 1, 2, 1, 1, 2, 4, 2]
@test collect(distinct(x)) == unique(x)

# partition
# ---------

@test collect(partition(take(countfrom(1), 6), 2)) == [(1,2), (3,4), (5,6)]
@test collect(partition(take(countfrom(1), 4), 2, 1)) == [(1,2), (2,3), (3,4)]
@test collect(partition(take(countfrom(1), 8), 2, 3)) == [(1,2), (4,5), (7,8)]

# imap
# ----

function test_imap(expected, input...)
  result = collect(imap(+, input...))
  @test result == expected
end


# Empty arrays
test_imap(
  Any[],
  @compat(Union{})[]
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
  @compat(Union{})[],
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

@test collect(subsets(Any[])) == Any[Any[]]

@test collect(subsets([:a])) == Any[Symbol[], Symbol[:a]]

@test collect(subsets([:a, :b, :c])) ==
      Any[Symbol[], Symbol[:a], Symbol[:b], Symbol[:a, :b], Symbol[:c],
          Symbol[:a, :c], Symbol[:b, :c], Symbol[:a, :b, :c]]


# subsets of size k
# -----------------

@test collect(subsets(Any[],0)) == Any[Any[]]
@test collect(subsets([:a, :b, :c],1)) == Any[Symbol[:a], Symbol[:b], Symbol[:c]]
@test collect(subsets([:a, :b, :c],2)) == Any[Symbol[:a,:b], Symbol[:a,:c], Symbol[:b,:c]]
@test collect(subsets([:a, :b, :c],3)) == Any[Symbol[:a,:b,:c]]
@test length(collect(subsets(collect(1:4),1))) == binomial(4,1)
@test length(collect(subsets(collect(1:4),2))) == binomial(4,2)
@test length(collect(subsets(collect(1:4),3))) == binomial(4,3)
@test length(collect(subsets(collect(1:4),4))) == binomial(4,4)


# Every nth
# ---------

@test collect(takenth([], 10)) == []
@test_throws ArgumentError takenth([], 0)
@test collect(takenth(10:20, 3)) == [12,15,18]
@test collect(takenth(10:20, 1)) == collect(10:20)


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
@test_zip [1,2,3] @compat(Union{})[] ['w', 'x', 'y', 'z']

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
@test_enumerate @compat(Union{})[]

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
@test_take @compat(Union{})[] 2
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
@test_takestrict @compat(Union{})[] 2
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
@test_drop @compat(Union{})[] 2
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
@test_chain [1,2,3] @compat(Union{})[] ['w', 'x', 'y', 'z']
@test_chain [1,2,3] 4 [('w',3), ('x',2), ('y',1), ('z',0)]

