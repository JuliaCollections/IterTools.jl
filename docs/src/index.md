```@meta
DocTestSetup = quote
    using IterTools
end
```

# IterTools

## Installation

Install this package with `Pkg.add("IterTools")`

# Usage

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

## iterated(f, x)

Iterate over successive applications of `f`, as in `x, f(x), f(f(x)), f(f(f(x))), ...`.

```@docs
iterated
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

## ivec(xs)

Iterate over `xs` but do not preserve shape information.

```@docs
ivec
```

## peekiter(xs)

Peek at the head element of an iterator without updating the state.

```@docs
peekiter
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

## takewhile(cond, xs)

Iterates through values from the iterable `xs` as long as a given predicate `cond` is true.

```@docs
takewhile
```

## flagfirst(xs)

Provide a flag to check if this is the first element.

```@docs
flagfirst
```

## IterTools.@ifsomething

Helper macro for returning from the enclosing block when there are no more elements.

```@docs
IterTools.@ifsomething
```

## properties(x)

Iterate over struct or named tuple properties.

```@docs
properties
```

## propertyvalues(x)

Iterate over struct or named tuple property values.

```@docs
propertyvalues
```

## fieldvalues(x)

Like `(getfield(x, i) for i in 1:nfields(x))` but faster.

```@docs
fieldvalues
```
