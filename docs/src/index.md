```@meta
DocTestSetup = quote
    using Iterators
end
```

# Iterators

## Installation

Install this package with `Pkg.add("Iterators")`

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

Iterate over successive applications of `f`, as in `f(x), f(f(x)), f(f(f(x))), ...`.

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

Iterate over every subset of a collection `xs`, or iterate over every subset of size `k` from a collection `xs`.

```@docs
subsets
```

## takestrict(xs, n)

Equivalent to `take`, but will throw an exception if fewer than `n` items are encountered in `xs`.

```@docs
takestrict
```

# The `@itr` macro for automatic inlining in `for` loops

Using functional iterators is powerful and concise, but may incur in some overhead, and manually inlining the operations can typically improve performance in critical parts of the code. The `@itr` macro is provided to do that automatically in some cases. 

Its usage is trivial: for example, given this code:

```
for (x,y) in zip(a,b)
    @show x,y
end
```

the automatically inlined version can be obtained by simply doing:

```
@itr for (x,y) in zip(a,b)
    @show x,y
end
```

This typically results in faster code, but its applicability has limitations:

* it only works with `for` loops;
* if multiple nested iterators are used, only the outermost is affected by the transformation;
* explicit expressions are required (i.e. when a `Tuple` is expected, an explicit tuple must be provided, a tuple variable won't be accepted);
* splicing is not supported;
* multidimensional loops (i.e. expressions such as `for x in a, y in b`) are not supported

The `@itr` macro can be used with the following supported iterators:

* zip
* enumerate
* take
* takestrict
* drop
* chain

```@docs
@itr
```
