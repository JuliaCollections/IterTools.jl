using Iterators

function test_imap(expected, input...)
  result = collect(imap(+, input...))
  println("Testing ", repr(input), " -> ", repr(result), " == ", repr(expected))
  @assert result == expected
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
