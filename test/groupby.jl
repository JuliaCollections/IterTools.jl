using Iterators

function test_groupby(input, expected)
  result = collect(groupby(input, x -> x[1]))
  println("Testing ", repr(input), " -> ", repr(result), " == ", repr(expected))
  @assert result == expected
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
