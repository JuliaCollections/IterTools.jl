using Iterators, Base.Test

# count
# -----

i = 0
for j = count(0, 2)
	@test j == i*2
	i += 1
	i <= 10 || break
end

# take
# ----

i = 0
for j = take(0:2:8, 10)
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

# chain
# -----

@test collect(chain(1:2:5, 0.2:0.1:1.6)) == [1:2:5, 0.2:0.1:1.6]

# product
# -------

x1 = 1:2:10
x2 = 1:5
@test collect(product(x1, x2)) == vec([(y1, y2) for y1 in x1, y2 in x2])

# distinct
# --------

x = [5, 2, 2, 1, 2, 1, 1, 2, 4, 2]
@test collect(distinct(x)) == unique(x)

# partition
# ---------

@test collect(partition(take(count(1), 6), 2)) == [(1,2), (3,4), (5,6)]
@test collect(partition(take(count(1), 4), 2, 1)) == [(1,2), (2,3), (3,4)]
@test collect(partition(take(count(1), 8), 2, 3)) == [(1,2), (4,5), (7,8)]

# imap
# ----

function test_imap(expected, input...)
  result = collect(imap(+, input...))
  @test result == expected
end


# Empty arrays
test_imap(
  {},
  []
)

# Simple operation
test_imap(
  {1,2,3},
  [1,2,3]
)

# Multiple arguments
test_imap(
  {5,7,9},
  [1,2,3],
  [4,5,6]
)

# Different-length arguments
test_imap(
  {2,4,6},
  [1,2,3],
  count(1)
)


# groupby
# -------

function test_groupby(input, expected)
  result = collect(groupby(input, x -> x[1]))
  @test result == expected
end


# Empty arrays
test_groupby(
  [],
  {}
)

# Singletons
test_groupby(
  ["xxx"],
  {["xxx"]}
)

# Typical operation
test_groupby(
  ["face", "foo", "bar", "book", "baz"],
  {["face", "foo"], ["bar", "book", "baz"]}
)

# Trailing singletons
test_groupby(
  ["face", "foo", "bar", "book", "baz", "xxx"],
  {["face", "foo"], ["bar", "book", "baz"], ["xxx"]}
)

# Leading singletons
test_groupby(
  ["xxx", "face", "foo", "bar", "book", "baz"],
  {["xxx"], ["face", "foo"], ["bar", "book", "baz"]}
)

# Middle singletons
test_groupby(
  ["face", "foo", "xxx", "bar", "book", "baz"],
  {["face", "foo"], ["xxx"], ["bar", "book", "baz"]}
)


# subsets

@test collect(subsets({})) == {{}}

@test collect(subsets([:a])) == {Symbol[], Symbol[:a]}

@test collect(subsets([:a, :b, :c])) ==
      {Symbol[], Symbol[:a], Symbol[:b], Symbol[:a, :b], Symbol[:c],
       Symbol[:a, :c], Symbol[:b, :c], Symbol[:a, :b, :c]}

# every n'th element
@test collect(everynth([], 10)) == []
@test_throws ArgumentError everynth([], 0)
@test collect(everynth(10:20, 3)) == [12,15,18]
@test collect(everynth(10:20, 1)) == [10:20]


