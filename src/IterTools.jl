module IterTools

import Base.Iterators: drop, take

import Base: iterate, eltype, length, size, peek
import Base: tail
import Base: IteratorSize, IteratorEltype
import Base: SizeUnknown, IsInfinite, HasLength, HasShape
import Base: HasEltype, EltypeUnknown

import Base: OneTo

export
    firstrest,
    takestrict,
    repeatedly,
    chain,
    product,
    distinct,
    partition,
    groupby,
    imap,
    subsets,
    iterated,
    nth,
    takenth,
    peekiter,
    peek,
    ncycle,
    ivec,
    flagfirst,
    takewhile,
    properties,
    propertyvalues,
    fieldvalues,
    interleaveby,
    cache,
    zip_longest

function has_length(it)
    it_size = IteratorSize(it)

    return isa(it_size, HasLength) || isa(it_size, HasShape)
end

# return the size for methods depending on the longest iterator
longest(::T, ::T) where {T<:IteratorSize} = T()
function longest(::S, ::T) where {T<:IteratorSize, S<:IteratorSize}
    longest(T(), S())
end
longest(::HasShape, ::HasShape) = HasLength()
longest(::HasLength, ::HasShape) = HasLength()
longest(::SizeUnknown, ::HasShape) = SizeUnknown()
longest(::SizeUnknown, ::HasLength) = SizeUnknown()
longest(::IsInfinite, ::HasShape) = IsInfinite()
longest(::IsInfinite, ::HasLength) = IsInfinite()
longest(::IsInfinite, ::SizeUnknown) = IsInfinite()

# return the size for methods depending on the shortest iterator
shortest(::T, ::T) where {T<:IteratorSize} = T()
function shortest(::S, ::T) where {T<:IteratorSize, S<:IteratorSize}
    shortest(T(), S())
end
shortest(::HasShape, ::HasShape) = HasLength()
shortest(::HasLength, ::HasShape) = HasLength()
shortest(::IsInfinite, ::HasShape) = HasLength()
shortest(::IsInfinite, ::HasLength) = HasLength()
shortest(::SizeUnknown, ::HasShape) = SizeUnknown()
shortest(::SizeUnknown, ::HasLength) = SizeUnknown()
shortest(::SizeUnknown, ::IsInfinite) = SizeUnknown()

# returns the least-known eltype
least_known(::HasEltype, ::HasEltype) = HasEltype()
least_known(::EltypeUnknown, ::HasEltype) = EltypeUnknown()
least_known(::HasEltype, ::EltypeUnknown) = EltypeUnknown()
least_known(::EltypeUnknown, ::EltypeUnknown) = EltypeUnknown()

"""
    IterTools.@ifsomething expr

If `expr` evaluates to `nothing`, equivalent to `return nothing`, otherwise the macro
evaluates to the value of `expr`. Not exported, useful for implementing iterators.

```jldoctest
julia> IterTools.@ifsomething iterate(1:2)
(1, 1)

julia> let elt, state = IterTools.@ifsomething iterate(1:2, 2); println("not reached"); end
```
"""
macro ifsomething(ex)
    quote
        result = $(esc(ex))
        result === nothing && return nothing
        result
    end
end

"""
    firstrest(xs) -> (f, r)

Return the first element and an iterator of the rest as a tuple.

See also: `Base.Iterators.peel`.

```jldoctest
julia> f, r = firstrest(1:3);

julia> f
1

julia> collect(r)
2-element Vector{Int64}:
 2
 3
```
"""
function firstrest(xs)
    t = iterate(xs)
    t === nothing && throw(ArgumentError("collection must be non-empty"))
    f, s = t
    r = Iterators.rest(xs, s)
    return f, r
end

# Iterate through the first n elements, throwing an exception if
# fewer than n items ar encountered.

struct TakeStrict{I}
    xs::I
    n::Int
end
eltype(::Type{TakeStrict{I}}) where {I} = eltype(I)
IteratorEltype(::Type{TakeStrict{I}}) where {I} = IteratorEltype(I)
IteratorSize(::Type{<:TakeStrict}) = HasLength()


"""
    takestrict(xs, n::Int)

Like `take()`, an iterator that generates at most the first `n` elements of `xs`, but throws
an exception if fewer than `n` items are encountered in `xs`.

```jldoctest
julia> collect(takestrict(1:2:11, 3))
3-element Vector{Int64}:
 1
 3
 5
```
"""
takestrict(xs, n::Int) = TakeStrict(xs, n)

function iterate(it::TakeStrict, state=(it.n,))
    n, xs_state = first(state), tail(state)
    n <= 0 && return nothing
    xs_iter = iterate(it.xs, xs_state...)

    if xs_iter === nothing
        throw(ArgumentError("In takestrict(xs, n), xs had fewer than n items to take."))
    end

    v, xs_state = xs_iter
    return v, (n - 1, xs_state)
end

length(it::TakeStrict) = it.n


# Repeat a function application n (or infinitely many) times.

struct RepeatCall{F<:Base.Callable}
    f::F
    n::Int
end
length(it::RepeatCall) = it.n
IteratorEltype(::Type{<:RepeatCall}) = EltypeUnknown()
IteratorSize(::Type{<:RepeatCall}) = HasLength()

"""
    repeatedly(f)
    repeatedly(f, n)

Call function `f` `n` times, or infinitely if `n` is omitted.

```julia
julia> t() = (sleep(0.1); Dates.millisecond(now()))
t (generic function with 1 method)

julia> collect(repeatedly(t, 5))
5-element Vector{Any}:
 993
  97
 200
 303
 408
```
"""
repeatedly(f, n) = RepeatCall(f, n)
iterate(it::RepeatCall, state=it.n) = state <= 0 ? nothing : (it.f(), state - 1)

struct RepeatCallForever{F<:Base.Callable}
    f::F
end
IteratorEltype(::Type{<:RepeatCallForever}) = EltypeUnknown()
IteratorSize(::Type{<:RepeatCallForever}) = IsInfinite()


repeatedly(f) = RepeatCallForever(f)
iterate(it::RepeatCallForever, state=nothing) = (it.f(), nothing)


@deprecate chain(xss...) Iterators.flatten(xss)
@deprecate product(xss...) Iterators.product(xss...)


# Filter out reccuring elements.

struct Distinct{I, J}
    xs::I

    # Map elements to the index at which it was first seen, so given an iterator
    # state (index) we can test if an element has previously been observed.
    seen::Dict{J, Int}
end
eltype(::Type{Distinct{I, J}}) where {I, J} = J
IteratorSize(::Type{<:Distinct}) = SizeUnknown()

"""
    distinct(xs)

Iterate through values skipping over those already encountered.

```jldoctest
julia> for i in distinct([1,1,2,1,2,4,1,2,3,4])
           @show i
       end
i = 1
i = 2
i = 4
i = 3
```
"""
distinct(xs::I) where {I} = Distinct{I, eltype(xs)}(xs, Dict{eltype(xs), Int}())

function iterate(it::Distinct, state=(1,))
    idx, xs_state = first(state), tail(state)
    xs_iter = iterate(it.xs, xs_state...)

    while xs_iter !== nothing
        val, xs_state = xs_iter
        get!(it.seen, val, idx) >= idx && return (val, (idx + 1, xs_state))

        xs_iter = iterate(it.xs, xs_state)
        idx += 1
    end

    return nothing
end


# Group output from at iterator into tuples.
# E.g.,
#   partition(count(1), 2) = (1,2), (3,4), (5,6) ...
#   partition(count(1), 2, 1) = (1,2), (2,3), (3,4) ...
#   partition(count(1), 2, 3) = (1,2), (4,5), (7,8) ...

struct Partition{I, N, K}
    xs::I
end
_length_partition(l, n, s) = ifelse(l - n ≥ 0, ((l - n) ÷ s) + 1, 0)
eltype(::Type{Partition{I, N, K}}) where {I, N, K} = NTuple{N, eltype(I)}
length(it::Partition{I, N, K}) where {I, N, K} = _length_partition(length(it.xs), N, K)
IteratorSize(::Type{Partition{I, N, K}}) where {I, N, K} = longest(HasLength(), IteratorSize(I))

"""
    partition(xs, n, [step])

Group values into `n`-tuples.

```jldoctest
julia> for i in partition(1:9, 3)
           @show i
       end
i = (1, 2, 3)
i = (4, 5, 6)
i = (7, 8, 9)
```

If the `step` parameter is set, each tuple is separated by `step` values.

```jldoctest
julia> for i in partition(1:9, 3, 2)
           @show i
       end
i = (1, 2, 3)
i = (3, 4, 5)
i = (5, 6, 7)
i = (7, 8, 9)

julia> for i in partition(1:9, 3, 3)
           @show i
       end
i = (1, 2, 3)
i = (4, 5, 6)
i = (7, 8, 9)

julia> for i in partition(1:9, 2, 3)
           @show i
       end
i = (1, 2)
i = (4, 5)
i = (7, 8)
```
"""
@inline partition(xs, n::Int) = partition(xs, n, n)

@inline function partition(xs::I, n::Int, step::Int) where I
    if step < 1
        throw(ArgumentError("Partition step must be at least 1."))
    end
    if n < 1
        throw(ArgumentError("Partition size n must be at least 1."))
    end

    Partition{I, n, step}(xs)
end

@generated function iterate(it::Partition{I, N, K}) where {I, N, K}
    res = Expr(:block)
    tup = Expr(:tuple)
    var = gensym()
    push!(res.args, :(($var, xs_state) = @ifsomething iterate(it.xs)))
    push!(tup.args, var)
    for i in 2:N
        var = gensym()
        push!(res.args, :(($var, xs_state) = @ifsomething iterate(it.xs, xs_state)))
        push!(tup.args, var)
    end
    quote
        $res
        newels = $tup
        (newels, (newels[$K+1:end], xs_state))
    end
end

@generated function iterate(it::Partition{I, N, K}, (els, xs_state)) where {I, N, K}
    res = Expr(:block)
    tup = Expr(:tuple, :(els...))
    for i in 1:K
        var = gensym()
        push!(res.args, :(($var, xs_state) = @ifsomething iterate(it.xs, xs_state)))
        if i > K-N
            push!(tup.args, var)
        end
    end
    quote
        $res
        newels = $tup
        (newels, (newels[$K+1:end], xs_state))
    end
end


# Group output from an iterator based on a key function.
# Consecutive entries from the iterator with the same
# key value will be returned in a single array.
# Inspired by itertools.groupby in python.
# E.g.,
#   x = ["face", "foo", "bar", "book", "baz", "zzz"]
#   groupby(z -> z[1], x) =
#       ["face", "foo"]
#       ["bar", "book", "baz"]
#       ["zzz"]
struct GroupBy{I, F<:Base.Callable}
    keyfunc::F
    xs::I
end
eltype(::Type{<:GroupBy{I}}) where {I} = Vector{eltype(I)}
IteratorSize(::Type{<:GroupBy}) = SizeUnknown()

"""
    groupby(f, xs)

Group consecutive values that share the same result of applying `f`.

```jldoctest
julia> for i in groupby(x -> x[1], ["face", "foo", "bar", "book", "baz", "zzz"])
           @show i
       end
i = ["face", "foo"]
i = ["bar", "book", "baz"]
i = ["zzz"]
```
"""
function groupby(keyfunc::F, xs::I) where {F<:Base.Callable, I}
    GroupBy{I, F}(keyfunc, xs)
end

function iterate(it::GroupBy{I, F}, state=nothing) where {I, F<:Base.Callable}
    if state === nothing
        prev_val, xs_state = @ifsomething iterate(it.xs)
        prev_key = it.keyfunc(prev_val)
        keep_going = true
    else
        keep_going, prev_key, prev_val, xs_state = state
        keep_going || return nothing
    end
    values = Vector{eltype(I)}()
    push!(values, prev_val)

    while true
        xs_iter = iterate(it.xs, xs_state)

        if xs_iter === nothing
            keep_going = false
            break
        end

        val, xs_state = xs_iter
        key = it.keyfunc(val)

        if key == prev_key
            push!(values, val)
        else
            prev_key = key
            prev_val = val
            break
        end
    end

    return (values, (keep_going, prev_key, prev_val, xs_state))
end


"""
    imap(f, xs1, [xs2, ...])

Iterate over values of a function applied to successive values from one or more iterators.
Like `Iterators.zip`, the iterator is done when any of the input iterators have been
exhausted.

```jldoctest
julia> for i in imap(+, [1,2,3], [4,5,6])
            @show i
       end
i = 5
i = 7
i = 9
```
"""
imap(mapfunc, it1, its...) = (mapfunc(xs...) for xs in zip(it1, its...))


# Iterate over all subsets of an indexable collection

struct Subsets{C}
    xs::C
end
eltype(::Type{Subsets{C}}) where {C} = Vector{eltype(C)}
length(it::Subsets) = 1 << length(it.xs)
IteratorSize(::Type{Subsets{C}}) where {C} = longest(HasLength(), IteratorSize(C))

"""
    subsets(xs)
    subsets(xs, k)
    subsets(xs, Val{k}())

Iterate over every subset of the indexable collection `xs`. You can restrict the subsets to a
specific size `k`.

Giving the subset size in the form `Val{k}()` allows the compiler to produce code optimized
for the particular size requested. This leads to performance comparable to hand-written
loops if `k` is small and known at compile time, but may or may not improve performance
otherwise.

```jldoctest
julia> for i in subsets([1, 2, 3])
          @show i
       end
i = Int64[]
i = [1]
i = [2]
i = [1, 2]
i = [3]
i = [1, 3]
i = [2, 3]
i = [1, 2, 3]

julia> for i in subsets(1:4, 2)
          @show i
       end
i = [1, 2]
i = [1, 3]
i = [1, 4]
i = [2, 3]
i = [2, 4]
i = [3, 4]

julia> for i in subsets(1:4, Val{2}())
           @show i
       end
i = (1, 2)
i = (1, 3)
i = (1, 4)
i = (2, 3)
i = (2, 4)
i = (3, 4)
```
"""
function subsets(xs)
    Subsets(xs)
end

# state has one extra bit to indicate that we are at the end
function iterate(it::Subsets, state=fill(false, length(it.xs) + 1))
    state[end] && return nothing

    ss = it.xs[state[1:end-1]]

    state = copy(state)
    state[1] = !state[1]
    for i in 2:length(state)
        if !state[i-1]
            state[i] = !state[i]
        else
            break
        end
    end

    return (ss, state)
end


# Iterate over all subsets of an indexable collection with a given size

struct Binomial{Collection}
    xs::Collection
    n::Int64
    k::Int64
end
Binomial(xs::C, n::Integer, k::Integer) where {C} = Binomial{C}(xs, n, k)

eltype(::Type{Binomial{C}}) where {C} = Vector{eltype(C)}
length(it::Binomial) = binomial(it.n,it.k)
IteratorSize(::Type{<:Binomial}) = HasLength()
IteratorEltype(::Type{Binomial{C}}) where {C} = IteratorEltype(C)

subsets(xs, k) = Binomial(xs, length(xs), k)

struct BinomialIterState
    idx::Vector{Int64}
    done::Bool
end

function iterate(it::Binomial, state=BinomialIterState(collect(Int64, 1:it.k), it.k > it.n))
    state.done && return nothing

    idx = state.idx
    set = it.xs[idx]
    i = it.k
    while i > 0
        if idx[i] < it.n - it.k + i
            idx[i] += 1

            for j in 1:it.k-i
                idx[i+j] = idx[i] + j
            end

            break
        else
            i -= 1
        end
    end

    return set, BinomialIterState(idx, i == 0)
end


# Iterate over all subsets of an indexable collection with a given *statically* known size

struct StaticSizeBinomial{K, Container}
    xs::Container
end
eltype(::Type{StaticSizeBinomial{K, C}}) where {K, C} = NTuple{K, eltype(C)}
length(it::StaticSizeBinomial{K}) where {K} = binomial(length(it.xs), K)
IteratorEltype(::Type{StaticSizeBinomial{K, C}}) where {K, C} = IteratorEltype(C)
IteratorSize(::Type{StaticSizeBinomial{K, C}}) where {K, C} = HasLength()

subsets(xs::C, ::Val{K}) where {K, C} = StaticSizeBinomial{K, C}(xs)

# Special case for K == 0
iterate(it::StaticSizeBinomial{0}, state=false) = state ? nothing : ((), true)

# Generic case K >= 1
pop(t::NTuple) = Base.front(t), last(t)

function advance(it::StaticSizeBinomial{K}, idx) where {K}
    xs = it.xs
    lidx, i = pop(idx)
    i += 1
    if i > length(xs) - K + length(idx)
        lidx = advance(it, lidx)
        i = lidx[end] + 1
    end
    return (lidx..., i)
end
advance(it::StaticSizeBinomial, idx::NTuple{1}) = (idx[end]+1,)

function iterate(it::StaticSizeBinomial{K}, idx=ntuple(identity, Val{K}())) where K
    idx[end] > length(it.xs) && return nothing
    return (map(i -> it.xs[i], idx), advance(it, idx))
end


# nth : return the nth element in a collection

"""
    nth(xs, n)

Return the `n`th element of `xs`. This is mostly useful for non-indexable collections.

```jldoctest
julia> powers_of_two = iterated(x->2x,1);

julia> nth(powers_of_two, 4)
8
```
"""
function nth(xs, n::Integer)
    n > 0 || throw(BoundsError(xs, n))

    # catch, if possible
    has_length(xs) && (n ≤ length(xs) || throw(BoundsError(xs, n)))

    for (i, val) in enumerate(xs)
        i >= n && return val
    end

    # catch iterators with no length but actual finite size less then n
    throw(BoundsError(xs, n))
end

nth(xs::Union{Tuple, Array}, n::Integer) = xs[n]

function nth(xs::AbstractArray, n::Integer)
    idx = eachindex(xs)[n]
    return @inbounds xs[idx]
end


# takenth(xs,n): take every n'th element from xs

struct TakeNth{I}
    xs::I
    interval::UInt
end
eltype(::Type{TakeNth{I}}) where {I} = eltype(I)
length(x::TakeNth) = div(length(x.xs), x.interval)
IteratorEltype(::Type{TakeNth{I}}) where {I} = IteratorEltype(I)
IteratorSize(::Type{TakeNth{I}}) where {I} = longest(HasLength(), IteratorSize(I))

"""
    takenth(xs, n)

Iterate through every `n`th element of `xs`.

```jldoctest
julia> collect(takenth(5:15,3))
3-element Vector{Int64}:
  7
 10
 13
```
"""
function takenth(xs, interval::Integer)
    if interval <= 0
        throw(ArgumentError(string("expected interval to be 1 or more, ",
                                   "got $interval")))
    end
    TakeNth(xs, convert(UInt, interval))
end


function iterate(it::TakeNth, state...)
    xs_iter = nothing

    for i = 1:it.interval
        xs_iter = @ifsomething iterate(it.xs, state...)
        state = tail(xs_iter)
    end

    return xs_iter
end


struct Iterated{T, F}
    f::F
    seed::T
end
IteratorEltype(::Type{<:Iterated}) = EltypeUnknown()
IteratorSize(::Type{<:Iterated}) = IsInfinite()


"""
    iterated(f, x)

Iterate over successive applications of `f`, as in `x`, `f(x)`, `f(f(x))`, `f(f(f(x)))`, ...

Use `Base.Iterators.take()` to obtain the required number of elements.

```jldoctest
julia> for i in Iterators.take(iterated(x -> 2x, 1), 5)
           @show i
       end
i = 1
i = 2
i = 4
i = 8
i = 16

julia> for i in Iterators.take(iterated(sqrt, 100), 6)
           @show i
       end
i = 100
i = 10.0
i = 3.1622776601683795
i = 1.7782794100389228
i = 1.333521432163324
i = 1.1547819846894583
```
"""
iterated(f, seed) = Iterated(f, seed)

iterate(it::Iterated) = (it.seed, it.seed)
function iterate(it::Iterated{T, F}, state) where {T, F}
    newval = it.f(state)
    return (newval, newval)
end

# peekiter(iter): possibility to peek the head of an iterator

struct PeekIter{I}
    it::I
end

"""
    peekiter(xs)

Lets you peek at the head element of an iterator without updating the state.

```jldoctest
julia> it = peekiter(["face", "foo", "bar", "book", "baz", "zzz"]);

julia> peek(it)
Some("face")

julia> peek(it)
Some("face")

julia> x, s = iterate(it)
("face", ("foo", 3))

julia> x
"face"

julia> peek(it, s)
Some("foo")
```
"""
peekiter(itr) = PeekIter(itr)

eltype(::Type{PeekIter{I}}) where {I} = eltype(I)
length(f::PeekIter) = length(f.it)
size(f::PeekIter) = size(f.it)
IteratorEltype(::Type{PeekIter{I}}) where {I} = IteratorEltype(I)
IteratorSize(::Type{PeekIter{I}}) where {I} = IteratorSize(I)

function iterate(pit::PeekIter, state=iterate(pit.it))
    val, it_state = @ifsomething state
    return (val, iterate(pit.it, it_state))
end

peek(pit::PeekIter, state=iterate(pit)) = Some{eltype(pit)}(first(@ifsomething state))

#NCycle - cycle through an object N times

struct NCycle{I}
    iter::I
    n::Int
end

"""
    ncycle(iter, n)

Cycle through `iter` `n` times.

```jldoctest
julia> for i in ncycle(1:3, 2)
           @show i
       end
i = 1
i = 2
i = 3
i = 1
i = 2
i = 3
```
"""
ncycle(iter, n::Int) = NCycle(iter, n)

eltype(::Type{NCycle{I}}) where {I} = eltype(I)
length(nc::NCycle) = nc.n*length(nc.iter)
IteratorEltype(::Type{NCycle{I}}) where {I} = IteratorEltype(I)
IteratorSize(::Type{NCycle{I}}) where {I} = longest(HasLength(), IteratorSize(I))

function iterate(nc::NCycle, state=(nc.n,))
    nc.n <= 0 && return nothing  # don't do anything if we aren't iterating

    n, inner_state = first(state), tail(state)
    inner_iter = iterate(nc.iter, inner_state...)

    if inner_iter === nothing
        if n <= 1
            return nothing
        else
            inner_iter = @ifsomething iterate(nc.iter)

            n -= 1
        end
    end

    v, inner_state = inner_iter
    return v, (n, inner_state)
end

# IVec - lazy `vec`-like iterator that drops shape

struct IVec{I}
    iter::I
end

"""
    ivec(iter)

Drops all shape from `iter` while iterating.
Like a non-materializing version of [`vec`](https://docs.julialang.org/en/stable/base/arrays/#Base.vec).

```jldoctest
julia> m = collect(reshape(1:6, 2, 3))
2×3 Matrix{Int64}:
 1  3  5
 2  4  6

julia> collect(ivec(m))
6-element Vector{Int64}:
 1
 2
 3
 4
 5
 6
```
"""
ivec(iter) = IVec(iter)

eltype(::Type{IVec{I}}) where {I} = eltype(I)
length(iv::IVec) = length(iv.iter)
IteratorEltype(::Type{IVec{I}}) where {I} = IteratorEltype(I)
IteratorSize(::Type{IVec{I}}) where {I} = longest(HasLength(), IteratorSize(I))

iterate(iv::IVec, state...) = iterate(iv.iter, state...)

# FlagFirst: prepend a flag that is `true` iff this is the first element

struct FlagFirst{I}
    iter::I
end

"""
    flagfirst(iter)

An iterator that yields `(isfirst, x)` where `isfirst::Bool` is `true` for the first
element, and `false` after that, while the `x`s are elements from `iter`.

```jldoctest
julia> collect(flagfirst(1:3))
3-element Vector{Tuple{Bool, Int64}}:
 (1, 1)
 (0, 2)
 (0, 3)
```
"""
flagfirst(iter) = FlagFirst(iter)

eltype(::Type{FlagFirst{I}}) where I = Tuple{Bool, eltype(I)}
length(ff::FlagFirst) = length(ff.iter)
size(ff::FlagFirst) = size(ff.iter)
IteratorEltype(::Type{FlagFirst{I}}) where {I} = IteratorEltype(I)
IteratorSize(::Type{FlagFirst{I}}) where {I} = IteratorSize(I)


function iterate(ff::FlagFirst, state = (true, ))
    isfirst, rest = first(state), tail(state)
    elt, nextstate = @ifsomething iterate(ff.iter, rest...)
    (isfirst, elt), (false, nextstate)
end

# TakeWhile iterates through values from an iterable as long as a given predicate is true.

struct TakeWhile{I}
    cond::Function
    xs::I
end

"""
    takewhile(cond, xs)

An iterator that yields values from the iterator `xs` as long as the
predicate `cond` is true.

```jldoctest
julia> collect(takewhile(x-> x^2 < 10, 1:100))
3-element Vector{Int64}:
 1
 2
 3
```
"""
takewhile(cond, xs) = TakeWhile(cond, xs)

function Base.iterate(it::TakeWhile, state=nothing)
    (val, state) = @ifsomething (state === nothing ? iterate(it.xs) : iterate(it.xs, state))
    it.cond(val) || return nothing
    val, state
end

eltype(::Type{TakeWhile{I}}) where {I} = eltype(I)
IteratorEltype(::Type{TakeWhile{I}}) where {I} = IteratorEltype(I)
IteratorSize(::Type{<:TakeWhile}) = Base.SizeUnknown()

# Properties

struct Properties{T}
    x::T
    n::Int
    names
end

"""
    properties(x)

Iterate through the names and value of the properties of `x`.

```jldoctest
julia> collect(properties(1 + 2im))
2-element Vector{Any}:
 (:re, 1)
 (:im, 2)
```
"""
function properties(x::T) where T
    names = propertynames(x)
    return Properties{T}(x, length(names), names)
end

function iterate(p::Properties, state=1)
    state > length(p) && return nothing

    name = p.names[state]
    return ((name, getproperty(p.x, name)), state + 1)
end

# PropertyValues

struct PropertyValues{T}
    x::T
    n::Int
    names
end

"""
    propertyvalues(x)

Iterate through the values of the properties of `x`.

```jldoctest
julia> collect(propertyvalues(1 + 2im))
2-element Vector{Any}:
 1
 2
```
"""
function propertyvalues(x::T) where T
    names = propertynames(x)
    return PropertyValues{T}(x, length(names), names)
end

function iterate(p::PropertyValues, state=1)
    state > length(p) && return nothing

    name = p.names[state]
    return (getproperty(p.x, name), state + 1)
end

length(p::Union{Properties, PropertyValues}) = p.n
IteratorSize(::Type{<:Union{Properties, PropertyValues}}) = HasLength()

# FieldValues

struct FieldValues{T}
    x::T
end

"""
    fieldvalues(x)

Iterate through the values of the fields of `x`.

```jldoctest
julia> collect(fieldvalues(1 + 2im))
2-element Vector{Any}:
 1
 2
```
"""
fieldvalues(x::T) where {T} = FieldValues{T}(x)
length(fs::FieldValues{T}) where {T} = fieldcount(T)
IteratorSize(::Type{<:FieldValues}) = HasLength()

function iterate(fs::FieldValues, state=1)
    state > length(fs) && return nothing

    return (getfield(fs.x, state), state + 1)
end

# CachedIterator

mutable struct CachedIterator{IT, EL}
    const it::IT
    const cache::Vector{EL}
    state
end

"""
    cache(it)

Cache the elements of an iterator so that subsequent iterations are served from the cache.

```jldoctest
julia> c = cache(Iterators.map(println, 1:3));

julia> collect(c);
1
2
3

julia> collect(c);

```
Be aware that if iterating the original  has a side-effect it will not be repeated when iterating again,  -- indeed that is a key feature of the `CachedIterator`.
Be aware also that if the original iterator is nondeterminatistic in its order, when iterating again from the cache it will infact be determinatistic and will be the same order as before -- this also is a feature.
"""
function cache(it::IT) where IT
    EL = eltype(IT)
    CachedIterator{IT, EL}(it, Vector{EL}(), nothing)
end

IteratorSize(::Type{CachedIterator{IT, EL}}) where {IT, EL} = IteratorSize(IT)
IteratorEltype(::Type{CachedIterator{IT, EL}}) where {IT, EL} = IteratorEltype(IT)
length(itr::CachedIterator) = length(itr.it)
size(itr::CachedIterator) = size(itr.it)
eltype(::Type{CachedIterator{IT, EL}}) where {IT, EL} = EL

function iterate(itr::CachedIterator, state=1)
    if state > length(itr.cache)
        if itr.state === nothing
            x = iterate(itr.it)
        else
            x = iterate(itr.it, itr.state)
        end
        x === nothing && return nothing
        v, s = x
        push!(itr.cache, v)
        itr.state = s
        return v, state+1
    else
        return itr.cache[state], state+1
    end
end

# InterleaveBy

"""
    interleaveby(predicate=Base.isless, a, b)

Iterate over the an interleaving of `a` and `b` selected by the predicate (default less-than).

Input:
 - `predicate(ak,bk) -> Bool`:
    Whether to pick the next element of `a` (true) or `b` (false).
 - `fa(ak)`, `fb(bk)`: Functions to apply to the picked elements

```jldoctest
julia> collect(interleaveby(1:2:5, 2:2:6))
6-element Vector{Int64}:
 1
 2
 3
 4
 5
 6
```

If the predicate is `Base.isless` (the default) and both inputs are sorted, this produces the sorted output.
If the predicate is a stateful functor that alternates true-false-true-false... then this produces the classic interleave operation as described e.g. in the definition of microkanren.
"""
function interleaveby end
interleaveby(a, b) = interleaveby(Base.isless, a, b)
interleaveby(p, a, b) = InterleaveBy(p, a, b)

struct InterleaveBy{A,B,P}
    predicate::P
    a::A
    b::B
end

Base.IteratorSize(::Type{<:InterleaveBy{A,B}}) where {A,B} = longest(IteratorSize(A), IteratorSize(B))
Base.length(m::InterleaveBy) = length(m.a) + length(m.b)
Base.IteratorEltype(::Type{<:InterleaveBy{A,B}}) where {A,B} = least_known(IteratorEltype(A), IteratorEltype(B))
Base.eltype(::Type{<:InterleaveBy{A,B}}) where {A,B} = Union{eltype(A), eltype(B)}

function Base.iterate(m::InterleaveBy, (vsa,vsb) = (iterate(m.a),iterate(m.b)))
    if isnothing(vsa) && isnothing(vsb)
        return nothing
    end
    if isnothing(vsb)
        return vsa[1], (iterate(m.a,vsa[2]),vsb)
    end
    if isnothing(vsa)
        return vsb[1], (vsa,iterate(m.b,vsb[2]))
    end
    if m.predicate(vsa[1],vsb[1])
        return vsa[1], (iterate(m.a,vsa[2]),vsb)
    else
        return vsb[1], (vsa,iterate(m.b,vsb[2]))
    end
end

# Implementation detail of zip_longest
# A bit of a hack to simplify reusing code from Base.
# This always actually returns the same as `I` but holds on the default
# and according to `eltype` might return it, but actually doesn't
# the decision to return it is done in the code for ZipLongest
struct _Padded{I, D}
    it::I
    default::D
end
IteratorSize(::Type{<:_Padded{I}}) where I = IteratorSize(I)
IteratorEltype(::Type{<:_Padded{I}}) where I = IteratorEltype(I)
eltype(::Type{_Padded{I, D}}) where {I,D} = Union{eltype(I), D}
length(i::_Padded) = length(i.it)
size(i::_Padded,dim...) = size(i.it,dim...)
axes(i::_Padded,dim...) = axes(i.it,dim...)

function iterate(it::_Padded,state...)
    isnothing(state) && return nothing
    ~isempty(state) && isnothing(last(state)) && return nothing
    return iterate(it.it,state...)
end

struct ZipLongest{IS<:Tuple}
    is::IS
end
IteratorSize(::Type{ZipLongest{Is}}) where {Is<:Tuple} = Base.Iterators.zip_iteratorsize(ntuple(n -> IteratorSize(fieldtype(Is, n)), Base.Iterators._counttuple(Is)::Int)...)
IteratorEltype(::Type{ZipLongest{Is}}) where {Is<:Tuple} = Base.Iterators.zip_iteratoreltype(ntuple(n -> IteratorEltype(fieldtype(Is, n)), Base.Iterators._counttuple(Is)::Int)...)
eltype(::Type{ZipLongest{Is}}) where {Is<:Tuple} = TupleOrBottom(map(eltype, fieldtypes(Is))...)
length(it::ZipLongest) = maximum(length.(it.is))
size(it::ZipLongest) = mapreduce(size, _zip_longest_promote_shape, it.is)
axes(it::ZipLongest) = mapreduce(axes, _zip_longest_promote_shape, it.is)
function iterate(it::ZipLongest,state...)
    cur = iterate.(it.is,state...)
    if all(isnothing.(cur))
        return nothing
    end
    outval = Vector{Any}(nothing,length(cur))
    outstate = Vector{Any}(nothing,length(cur))
    for (i,c) in enumerate(cur)
        if isnothing(c)
            outval[i] = it.is[i].default
            outstate[i] = nothing
            continue
        end
        outval[i] = c[1]
        outstate[i] = c[2]
    end
    return (Tuple(outval), Tuple(outstate))
end

# Copied from julia 1.10
function TupleOrBottom(tt...)
    any(p -> p === Union{}, tt) && return Union{}
    return Tuple{tt...}
end

_zip_longest_promote_shape((a,)::Tuple{OneTo}, (b,)::Tuple{OneTo}) = (union(a, b),)
_zip_longest_promote_shape((m,)::Tuple{Integer},(n,)::Tuple{Integer}) = (max(m,n),)
_zip_longest_promote_shape(a, b) = promote_shape(a, b)

"""
    zip_longest(iters...; default=nothing)

For one or more iterable objects, return an iterable of tuples, where the `i`th tuple
contains the `i`th component of each input iterable if it is not finished, and `default`
otherwise. `default` can be a scalar, or a tuple with one default per iterable.

```jldoctest
julia> for t in zip_longest(1:2, 5:8)
         @show t
       end
t = (1, 5)
t = (2, 6)
t = (nothing, 7)
t = (nothing, 8)

julia> for t in zip_longest('a':'e', ['m', 'n']; default='x')
         @show t
       end
t = ('a', 'm')
t = ('b', 'n')
t = ('c', 'x')
t = ('d', 'x')
t = ('e', 'x')
```
"""
zip_longest(its...; default=nothing) = ZipLongest(Tuple(_Padded.(its, default)))

end # module IterTools
