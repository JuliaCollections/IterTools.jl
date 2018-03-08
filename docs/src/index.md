```@meta
DocTestSetup = quote
    using IterTools
end
```

# IterTools

## Installation

Install this package with `Pkg.add("IterTools")`

# Usage

## chain(xs...)

Iterate through any number of iterators in sequence.

```@docs
chain
```

## distinct(xs)

Iterate through values skipping over those already encountered.

```@docs
distinct
```

## groupby(f, xs)

Group consecutive values that share the same result of applying `f`.

```@docs
groupby
```

## imap(f, xs1, [xs2, ...])

Iterate over values of a function applied to successive values from one or more iterators.

```@docs
imap
```

## iterate(f, x)

Iterate over successive applications of `f`, as in `x, f(x), f(f(x)), f(f(f(x))), ...`.

```@docs
iterate
```

## ncycle(xs, n)

Cycles through an iterator `n` times.

```@docs
ncycle
```

## nth(xs, n)

Return the `n`th element of `xs`.

```@docs
nth
```

## partition(xs, n, [step])

Group values into `n`-tuples.

```@docs
partition
```

## peekiter(xs)

Peek at the head element of an iterator without updating the state.

```@docs
peekiter
```

## product(xs...)

Iterate over all combinations in the Cartesian product of the inputs.

```@docs
product
```

## repeatedly(f, [n])

Call a function `n` times, or infinitely if `n` is omitted.

```@docs
repeatedly
```

## takenth(xs, n)

Iterate through every n'th element of `xs`

```@docs
takenth
```

## subsets(xs, [k])

Iterate over every subset of an indexable collection `xs`, or iterate over every subset of size `k`
from an indexable collection `xs`.

```@docs
subsets
```

## takestrict(xs, n)

Equivalent to `take`, but will throw an exception if fewer than `n` items are encountered in `xs`.

```@docs
takestrict
```
