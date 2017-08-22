__precompile__()

module IterTools

# gets around deprecation warnings in v0.6
if isdefined(Base, :Iterators)
    import Base.Iterators: drop, countfrom, cycle, take, repeated
end

import Base: start, next, done, eltype, length, size
import Base: iteratorsize, IteratorSize, SizeUnknown, IsInfinite, HasLength, HasShape
import Base: iteratoreltype, IteratorEltype, HasEltype, EltypeUnknown

export
    takestrict,
    repeatedly,
    chain,
    product,
    distinct,
    partition,
    groupby,
    imap,
    subsets,
    iterate,
    nth,
    takenth,
    peekiter,
    peek,
    ncycle,
    @itr

function has_length(it)
    it_size = iteratorsize(it)

    return isa(it_size, HasLength) || isa(it_size, HasShape)
end

promote_iteratoreltype(::HasEltype, ::HasEltype) = HasEltype()
promote_iteratoreltype(::IteratorEltype, ::IteratorEltype) = EltypeUnknown()

# return the size for methods depending on the longest iterator
longest{T<:IteratorSize}(::T, ::T) = T()
function longest{T<:IteratorSize, S<:IteratorSize}(::S, ::T)
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
shortest{T<:IteratorSize}(::T, ::T) = T()
function shortest{T<:IteratorSize, S<:IteratorSize}(::S, ::T)
    shortest(T(), S())
end
shortest(::HasShape, ::HasShape) = HasLength()
shortest(::HasLength, ::HasShape) = HasLength()
shortest(::IsInfinite, ::HasShape) = HasLength()
shortest(::IsInfinite, ::HasLength) = HasLength()
shortest(::SizeUnknown, ::HasShape) = SizeUnknown()
shortest(::SizeUnknown, ::HasLength) = SizeUnknown()
shortest(::SizeUnknown, ::IsInfinite) = SizeUnknown()

include("tuple_types.jl")

# Iterate through the first n elements, throwing an exception if
# fewer than n items ar encountered.

immutable TakeStrict{I}
    xs::I
    n::Int
end
iteratorsize{T<:TakeStrict}(::Type{T}) = HasLength()
iteratoreltype{I}(::Type{TakeStrict{I}}) = iteratoreltype(I)
eltype{I}(::Type{TakeStrict{I}}) = eltype(I)

"""
    takestrict(xs, n::Int)

Like `take()`, an iterator that generates at most the first `n` elements of `xs`, but throws
an exception if fewer than `n` items are encountered in `xs`.

```jldoctest
julia> a = :1:2:11
1:2:11

julia> collect(takestrict(a, 3))
3-element Array{Int64,1}:
 1
 3
 5
```
"""
takestrict(xs, n::Int) = TakeStrict(xs, n)

start(it::TakeStrict) = (it.n, start(it.xs))

function next(it::TakeStrict, state)
    n, xs_state = state
    v, xs_state = next(it.xs, xs_state)
    return v, (n - 1, xs_state)
end

function done(it::TakeStrict, state)
    n, xs_state = state
    if n <= 0
        return true
    elseif done(it.xs, xs_state)
        throw(ArgumentError("In takestrict(xs, n), xs had fewer than n items to take."))
    else
        return false
    end
end

function length(it::TakeStrict)
    return it.n
end


# Repeat a function application n (or infinitely many) times.

immutable RepeatCall{F<:Base.Callable}
    f::F
    n::Int
end
iteratorsize{T<:RepeatCall}(::Type{T}) = HasLength()

length(it::RepeatCall) = it.n

"""
    repeatedly(f, n)

Call function `f` `n` times, or infinitely if `n` is omitted.

```julia
julia> t() = (sleep(0.1); Dates.millisecond(now()))
t (generic function with 1 method)

julia> collect(repeatedly(t, 5))
5-element Array{Any,1}:
 993
  97
 200
 303
 408
```
"""
repeatedly(f, n) = RepeatCall(f, n)

start(it::RepeatCall) = it.n
next(it::RepeatCall, state) = (it.f(), state - 1)
done(it::RepeatCall, state) = state <= 0

immutable RepeatCallForever{F<:Base.Callable}
    f::F
end
iteratorsize{T<:RepeatCallForever}(::Type{T}) = IsInfinite()

repeatedly(f) = RepeatCallForever(f)

start(it::RepeatCallForever) = nothing
next(it::RepeatCallForever, state) = (it.f(), nothing)
done(it::RepeatCallForever, state) = false


# Concatenate the output of n iterators
immutable Chain{T<:Tuple}
    xss::T
end

# iteratorsize method defined at bottom because of how @generated functions work in 0.6 now

"""
    chain(xs...)

Iterate through any number of iterators in sequence.

```jldoctest
julia> for i in chain(1:3, ['a', 'b', 'c'])
           @show i
       end
i = 1
i = 2
i = 3
i = 'a'
i = 'b'
i = 'c'
```
"""
chain(xss...) = Chain(xss)

length(it::Chain{Tuple{}}) = 0
length(it::Chain) = sum(length, it.xss)
function iteratoreltype{T}(::Type{Chain{T}})
    mapreduce_tt(iteratoreltype, promote_iteratoreltype, HasEltype(), T)
end
iteratorsize{T}(::Type{Chain{T}}) = mapreduce_tt(iteratorsize, longest, HasLength(), T)
eltype{T}(::Type{Chain{T}}) = mapreduce_tt(eltype, typejoin, Union{}, T)

function start(it::Chain)
    i = 1
    xs_state = nothing
    while i <= length(it.xss)
        xs_state = start(it.xss[i])
        if !done(it.xss[i], xs_state)
            break
        end
        i += 1
    end
    return i, xs_state
end

function next(it::Chain, state)
    i, xs_state = state
    v, xs_state = next(it.xss[i], xs_state)
    while done(it.xss[i], xs_state)
        i += 1
        if i > length(it.xss)
            break
        end
        xs_state = start(it.xss[i])
    end
    return v, (i, xs_state)
end

done(it::Chain, state) = state[1] > length(it.xss)


# Cartesian product as a sequence of tuples

immutable Product{T<:Tuple}
    xss::T
end

iteratorsize{T}(::Type{Product{T}}) = mapreduce_tt(iteratorsize, longest, HasLength(), T)
eltype{T}(::Type{Product{T}}) = map_tt_t(eltype, T)
length(p::Product) = mapreduce(length, *, 1, p.xss)

"""
    product(xs...)

Iterate over all combinations in the Cartesian product of the inputs.

```jldoctest
julia> for p in product(1:3,4:5)
           @show p
       end
p = (1,4)
p = (2,4)
p = (3,4)
p = (1,5)
p = (2,5)
p = (3,5)
```
"""
product(xss...) = Product(xss)

function start(it::Product)
    n = length(it.xss)
    js = Any[start(xs) for xs in it.xss]
    for i = 1:n
        if done(it.xss[i], js[i])
            return js, nothing
        end
    end
    vs = Vector{Any}(n)
    for i = 1:n
        vs[i], js[i] = next(it.xss[i], js[i])
    end
    return js, vs
end

function next(it::Product, state)
    js = copy(state[1])
    vs = copy(state[2])
    ans = tuple(vs...)

    n = length(it.xss)
    for i in 1:n
        if !done(it.xss[i], js[i])
            vs[i], js[i] = next(it.xss[i], js[i])
            return ans, (js, vs)
        end

        js[i] = start(it.xss[i])
        vs[i], js[i] = next(it.xss[i], js[i])
    end
    ans, (js, nothing)
end

done(it::Product, state) = state[2] === nothing


# Filter out reccuring elements.

immutable Distinct{I, J}
    xs::I

    # Map elements to the index at which it was first seen, so given an iterator
    # state (index) we can test if an element has previously been observed.
    seen::Dict{J, Int}
end

iteratorsize{T<:Distinct}(::Type{T}) = SizeUnknown()

eltype{I, J}(::Type{Distinct{I, J}}) = J

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
distinct{I}(xs::I) = Distinct{I, eltype(xs)}(xs, Dict{eltype(xs), Int}())
# TODO: only use eltype when I has iteratoreltype?
function start(it::Distinct)
    start(it.xs), 1
end

function next(it::Distinct, state)
    s, i = state
    x, s = next(it.xs, s)
    it.seen[x] = i
    i += 1

    while !done(it.xs, s)
        y, t = next(it.xs, s)
        if !haskey(it.seen, y) || it.seen[y] >= i
            break
        end
        s = t
        i += 1
    end

    x, (s, i)
end

done(it::Distinct, state) = done(it.xs, state[1])


# Group output from at iterator into tuples.
# E.g.,
#   partition(count(1), 2) = (1,2), (3,4), (5,6) ...
#   partition(count(1), 2, 1) = (1,2), (2,3), (3,4) ...
#   partition(count(1), 2, 3) = (1,2), (4,5), (7,8) ...

immutable Partition{I, N}
    xs::I
    step::Int
end
iteratorsize{T<:Partition}(::Type{T}) = SizeUnknown()

eltype{I, N}(::Type{Partition{I, N}}) = NTuple{N, eltype(I)}

"""
    partition(xs, n, [step])

Group values into `n`-tuples.

```jldoctest
julia> for i in partition(1:9, 3)
           @show i
       end
i = (1,2,3)
i = (4,5,6)
i = (7,8,9)
```

If the `step` parameter is set, each tuple is separated by `step` values.

```jldoctest
julia> for i in partition(1:9, 3, 2)
           @show i
       end
i = (1,2,3)
i = (3,4,5)
i = (5,6,7)
i = (7,8,9)

julia> for i in partition(1:9, 3, 3)
           @show i
       end
i = (1,2,3)
i = (4,5,6)
i = (7,8,9)

julia> for i in partition(1:9, 2, 3)
           @show i
       end
i = (1,2)
i = (4,5)
i = (7,8)
```
"""
function partition{I}(xs::I, n::Int)
    Partition{I, n}(xs, n)
end

function partition{I}(xs::I, n::Int, step::Int)
    if step < 1
        throw(ArgumentError("Partition step must be at least 1."))
    end

    Partition{I, n}(xs, step)
end

function start{I, N}(it::Partition{I, N})
    p = Vector{eltype(I)}(N)
    s = start(it.xs)
    for i in 1:(N - 1)
        if done(it.xs, s)
            break
        end
        (p[i], s) = next(it.xs, s)
    end
    (s, p)
end

function next{I, N}(it::Partition{I, N}, state)
    (s, p0) = state
    (x, s) = next(it.xs, s)
    ans = p0; ans[end] = x

    p = similar(p0)
    overlap = max(0, N - it.step)
    for i in 1:overlap
        p[i] = ans[it.step + i]
    end

    # when step > n, skip over some elements
    for i in 1:max(0, it.step - N)
        if done(it.xs, s)
            break
        end
        (x, s) = next(it.xs, s)
    end

    for i in (overlap + 1):(N - 1)
        if done(it.xs, s)
            break
        end

        (x, s) = next(it.xs, s)
        p[i] = x
    end

    (tuple(ans...), (s, p))
end

done(it::Partition, state) = done(it.xs, state[1])

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
immutable GroupBy{I, F<:Base.Callable}
    keyfunc::F
    xs::I
end
iteratorsize{T<:GroupBy}(::Type{T}) = SizeUnknown()

# eltype{I}(it::GroupBy{I}) = I
eltype{I, F}(::Type{GroupBy{I, F}}) = Vector{eltype(I)}

"""
    groupby(f, xs)

Group consecutive values that share the same result of applying `f`.

```jldoctest
julia> for i in groupby(x -> x[1], ["face", "foo", "bar", "book", "baz", "zzz"])
           @show i
       end
i = String["face","foo"]
i = String["bar","book","baz"]
i = String["zzz"]
```
"""
function groupby(keyfunc::Base.Callable, xs)
    GroupBy(keyfunc, xs)
end

function start(it::GroupBy)
    s = start(it.xs)
    prev_value = nothing
    prev_key = nothing
    return (s, (prev_key, prev_value))
end

function next{I}(it::GroupBy{I}, state)
    (s, (prev_key, prev_value)) = state
    values = Vector{eltype(I)}(0)
    # We had a left over value from the last time the key changed.
    if prev_value != nothing || prev_key != nothing
        push!(values, prev_value)
    end
    prev_value = nothing
    while !done(it.xs, s)
        (x, s) = next(it.xs, s)
        key = it.keyfunc(x)
        # Did the key change?
        if prev_key != nothing && key != prev_key
            prev_key = key
            prev_value = x
            break
        else
            push!(values, x)
        end
        prev_key = key
    end
    # We either reached the end of the input or the key changed,
    # either way emit what we have so far.
    return (values, (s, (prev_key, prev_value)))
end

function done(it::GroupBy, state)
    return state[2][2] == nothing && done(it.xs, state[1])
end

# Like map, except returns the output as an iterator.  The iterator
# is done when any of the input iterators have been exhausted.
# E.g.,
#   imap(+, count(), [1, 2, 3]) = 1, 3, 5 ...
immutable IMap{F<:Base.Callable, T<:Tuple}
    mapfunc::F
    xs::T
end

iteratorsize{F, T}(::Type{IMap{F, T}}) = mapreduce_tt(iteratorsize, shortest, HasLength(), T)
iteratoreltype{I<:IMap}(::Type{I}) = EltypeUnknown()
length(it::IMap) = minimum(length(x) for x in it.xs if has_length(x))

"""
    imap(f, xs1, [xs2, ...])

Iterate over values of a function applied to successive values from one or more iterators.

```jldoctest
julia> for i in imap(+, [1,2,3], [4,5,6])
            @show i
       end
i = 5
i = 7
i = 9
```
"""
function imap(mapfunc, it1, its...)
    IMap(mapfunc, (it1, its...))
end

function start(it::IMap)
    map(start, it.xs)
end

function next(it::IMap, state)
    next_result = map(next, it.xs, state)
    return (
        it.mapfunc(map(first, next_result)...),
        map(last, next_result)
    )
end

function done(it::IMap, state)
    any(map(done, it.xs, state))
end


# Iterate over all subsets of a collection

immutable Subsets{C}
    xs::C
end
iteratorsize{C}(::Type{Subsets{C}}) = longest(HasLength(), iteratorsize(C))

eltype{C}(::Type{Subsets{C}}) = Vector{eltype(C)}
length(it::Subsets) = 1 << length(it.xs)

"""
    subsets(xs)
    subsets(xs, k)

Iterate over every subset of the collection `xs`. You can restrict the subsets to a specific
size `k`.

```jldoctest
julia> for i in subsets([1, 2, 3])
          @show i
       end
i = Int64[]
i = [1]
i = [2]
i = [1,2]
i = [3]
i = [1,3]
i = [2,3]
i = [1,2,3]

julia> for i in subsets(1:4, 2)
          @show i
       end
i = [1,2]
i = [1,3]
i = [1,4]
i = [2,3]
i = [2,4]
i = [3,4]
```
"""
function subsets(xs)
    Subsets(xs)
end

function start(it::Subsets)
    # one extra bit to indicated that we are at the end
    fill(false, length(it.xs) + 1)
end

function next(it::Subsets, state)
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

    (ss, state)
end

function done(it::Subsets, state)
    state[end]
end


# Iterate over all subsets of a collection with a given size

immutable Binomial{T}
    xs::Vector{T}
    n::Int64
    k::Int64
end
Binomial{T}(xs::AbstractVector{T}, n::Integer, k::Integer) = Binomial{T}(xs, n, k)

iteratorsize{T<:Binomial}(::Type{T}) = HasLength()

eltype{T}(::Type{Binomial{T}}) = Vector{T}
length(it::Binomial) = binomial(it.n,it.k)

subsets(xs,k) = Binomial(xs,length(xs),k)

type BinomialIterState
    idx::Vector{Int64}
    done::Bool
end

start(it::Binomial) = BinomialIterState(collect(Int64, 1:it.k), (it.k > it.n) ? true : false)

function next(it::Binomial, state::BinomialIterState)
    idx = state.idx
    set = it.xs[idx]
    i = it.k
    while(i>0)
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

    state.done = i==0

    return set, state
end

done(it::Binomial, state::BinomialIterState) = state.done


# nth : return the nth element in a collection

"""
    nth(xs, n)

Return the `n`th element of `xs`. This is mostly useful for non-indexable collections.

```jldoctest
julia> mersenne = Set([3, 7, 31, 127])
Set([7,31,3,127])

julia> nth(mersenne, 3)
3
```
"""
function nth(xs, n::Integer)
    n > 0 || throw(BoundsError(xs, n))
    # catch, if possible
    has_length(xs) && (n ≤ length(xs) || throw(BoundsError(xs, n)))
    s = start(xs)
    i = 0
    while !done(xs, s)
        (val, s) = next(xs, s)
        i += 1
        i == n && return val
    end
    # catch iterators with no length but actual finite size less then n
    throw(BoundsError(xs, n))
end

nth(xs::Union{Tuple, AbstractArray}, n::Integer) = xs[n]


# takenth(xs,n): take every n'th element from xs

immutable TakeNth{I}
    xs::I
    interval::UInt
end
iteratorsize{I}(::Type{TakeNth{I}}) = longest(HasLength(), iteratorsize(I))
iteratoreltype{I}(::Type{TakeNth{I}}) = iteratoreltype(I)
eltype{I}(::Type{TakeNth{I}}) = eltype(I)
length(x::TakeNth) = div(length(x.xs), x.interval)
size(x::TakeNth) = (length(x),)

"""
    takenth(xs, n)

Iterate through every `n`th element of `xs`.

```jldoctest
julia> collect(takenth(5:15,3))
3-element Array{Int64,1}:
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


function start(it::TakeNth)
    i = 1
    state = start(it.xs)
    while i < it.interval && !done(it.xs, state)
        _, state = next(it.xs, state)
        i += 1
    end
    return state
end


function next(it::TakeNth, state)
    value, state = next(it.xs, state)
    i = 1
    while i < it.interval && !done(it.xs, state)
        _, state = next(it.xs, state)
        i += 1
    end
    return value, state
end


done(it::TakeNth, state) = done(it.xs, state)

immutable Iterate{T}
    f::Function
    seed::T
end
iteratorsize{T<:Iterate}(::Type{T}) = IsInfinite()

"""
    iterate(f, x)

Iterate over successive applications of `f`, as in `f(x)`, `f(f(x))`, `f(f(f(x)))`, ....

Use `Base.take()` to obtain the required number of elements.

```jldoctest
julia> for i in take(iterate(x -> 2x, 1), 5)
           @show i
       end
i = 1
i = 2
i = 4
i = 8
i = 16

julia> for i in take(iterate(sqrt, 100), 6)
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
iterate(f, seed) = Iterate(f, seed)
start(it::Iterate) = it.seed
next(it::Iterate, state) = (state, it.f(state))
done(it::Iterate, state) = (state==Union{})

# peekiter(iter): possibility to peek the head of an iterator

immutable PeekIter{I}
    it::I
end

"""
    peekiter(xs)

Lets you peek at the head element of an iterator without updating the state.

```jldoctest
julia> it = peekiter(["face", "foo", "bar", "book", "baz", "zzz"])
IterTools.PeekIter{Array{String,1}}(String["face","foo","bar","book","baz","zzz"])

julia> s = start(it)
(2,Nullable{String}("face"))

julia> @show peek(it, s)
peek(it,s) = Nullable{String}("face")
Nullable{String}("face")

julia> @show peek(it, s)
peek(it,s) = Nullable{String}("face")
Nullable{String}("face")

julia> x, s = next(it, s)
("face",(3,Nullable{String}("foo"),false))

julia> @show x
x = "face"
"face"

julia> @show peek(it, s)
peek(it,s) = Nullable{String}("foo")
Nullable{String}("foo")
```
"""
peekiter(itr) = PeekIter(itr)

eltype{I}(::Type{PeekIter{I}}) = eltype(I)
iteratorsize{I}(::Type{PeekIter{I}}) = iteratorsize(I)
iteratoreltype{I}(::Type{PeekIter{I}}) = iteratoreltype(I)
length(f::PeekIter) = length(f.it)
size(f::PeekIter) = size(f.it)

function start{I}(f::PeekIter{I})
    s = start(f.it)
    if done(f.it, s)
        val = Nullable{eltype(I)}()
    else
        el, s = next(f.it, s)
        val = Nullable{eltype(I)}(el)
    end
    return s, val
end

function next(f::PeekIter, state)
    s, val = state
    # done() should prevent condition `isnull(val) && done(state)`
    !isnull(val) && done(f.it, s) && return get(val), (s, Nullable{typeof(val)}())
    el, s = next(f.it, s)
    return get(val), (s, Nullable(el), done(f.it, s))
end

@inline function done(f::PeekIter, state)
    s, val = state
    return done(f.it, s) && isnull(val)
end

peek{I}(f::PeekIter{I}, state) = done(f, state) ? Nullable{eltype(I)}() : state[2]


start{T}(r::PeekIter{UnitRange{T}}) = start(r.it)
next{T}(r::PeekIter{UnitRange{T}}, i) = next(r.it, i)
done{T}(r::PeekIter{UnitRange{T}}, i) = done(r.it, i)
peek{T}(r::PeekIter{UnitRange{T}}, i) = done(r.it, i) ? Nullable{T}() : Nullable{T}(next(r.it, i)[1])

#NCycle - cycle through an object N times

immutable NCycle{I}
    iter::I
    n::Int
end

"""
    ncycle(xs, n)

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

eltype{I}(nc::NCycle{I}) = eltype(I)
length(nc::NCycle) = nc.n*length(nc.iter)
iteratorsize{I}(::Type{NCycle{I}}) = longest(HasLength(), iteratorsize(I))
iteratoreltype{I}(::Type{NCycle{I}}) = iteratoreltype(I)

start(nc::NCycle) = (start(nc.iter), 0)
function next(nc::NCycle, state)
    nv, ns = next(nc.iter,state[1])
    if done(nc.iter, ns)
        return (nv, (start(nc.iter), state[2]+1))
    else
        return (nv, (ns, state[2]))
    end
end
done(nc::NCycle, state) = state[2] == nc.n

using Base.Meta

## @itr macro for auto-inlining in for loops
#
# it dispatches on macros defined below

"""
    @itr(ex)

The `@itr` macro automaticaly inlines some iterators in `for` loops, to produce faster code.

The macro can be used with the following supported iterators: `zip()`, `enumerate()`,
`take()`, `takestrict()`, `drop()`, and `chain()`.

```jldoctest
julia> for (x,y) in zip(1:3, 4:6)
           @show x,y
       end
(x,y) = (1,4)
(x,y) = (2,5)
(x,y) = (3,6)

julia> @itr for (x,y) in zip(1:3, 4:6)
           @show x,y
       end
(x,y) = (1,4)
(x,y) = (2,5)
(x,y) = (3,6)
```
"""
macro itr(ex)
    isexpr(ex, :for) || throw(ArgumentError("@itr macro expects a for loop"))
    isexpr(ex.args[1], :(=)) || throw(ArgumentError("malformed or unsupported for loop in @itr macro"))
    isexpr(ex.args[1].args[2], :call) || throw(ArgumentError("@itr macro expects an iterator call, e.g. @itr for (x,y) = zip(a,b)"))

    iterator = ex.args[1].args[2].args[1]

    # fix for Julia v0.6
    if isa(iterator, Expr) && iterator.head === :globalref
        iterator = iterator.args[2]
    end

    ex.args[1].args[2] = Expr(:tuple, ex.args[1].args[2].args[2:end]...)

    if iterator == :zip
        rex = :(@zip($(esc(ex))))
    elseif iterator == :enumerate
        rex = :(@enumerate($(esc(ex))))
    elseif iterator == :take
        rex = :(@take($(esc(ex))))
    elseif iterator == :takestrict
        rex = :(@takestrict($(esc(ex))))
    elseif iterator == :drop
        rex = :(@drop($(esc(ex))))
    elseif iterator == :chain
        rex = :(@chain($(esc(ex))))
    else
        throw(ArgumentError("unknown or unsupported iterator $iterator in @itr macro"))
    end
    return rex
end

macro zip(ex)
    @assert ex.head == :for
    @assert ex.args[1].head == :(=)
    isexpr(ex.args[1].args[1], :tuple) || throw(ArgumentError("@zip macro needs explicit tuple arguments"))
    isexpr(ex.args[1].args[2], :tuple) || throw(ArgumentError("@zip macro needs explicit tuple arguments"))
    n = length(ex.args[1].args[1].args)
    length(ex.args[1].args[2].args) == n || throw(ArgumentError("unequal tuple sizes in @zip macro"))
    body = esc(ex.args[2])
    vars = map(esc, ex.args[1].args[1].args)
    iters = map(esc, ex.args[1].args[2].args)
    states = [gensym("s") for i=1:n]
    as = Any[Expr(:call, :(Base.start), iters[i]) for i=1:n]
    startex = Expr(:(=), Expr(:tuple, states...), Expr(:tuple, as...))
    ad = Any[Expr(:call, :(Base.done), iters[i], states[i]) for i = 1:n]
    notdoneex = Expr(:call, :(!), Expr(:||, ad...))
    nextex = Expr(:(=), Expr(:tuple, Any[Expr(:tuple, vars[i], states[i]) for i=1:n]...),
                        Expr(:tuple, Any[Expr(:call, :(Base.next), iters[i], states[i]) for i=1:n]...))
    Expr(:let, Expr(:block,
        startex,
        Expr(:while, notdoneex, Expr(:block,
            nextex,
            body))),
        states...)
end

macro enumerate(ex)
    @assert ex.head == :for
    @assert ex.args[1].head == :(=)
    isexpr(ex.args[1].args[1], :tuple) || throw(ArgumentError("@enumerate macro needs an explicit tuple argument"))
    length(ex.args[1].args[1].args) == 2 || throw(ArgumentError("lentgh of tuple must be 2 in @enumerate macro"))
    body = esc(ex.args[2])
    vars = map(esc, ex.args[1].args[1].args)
    if isexpr(ex.args[1].args[2], :tuple) && length(ex.args[1].args[2].args) == 1
        ex.args[1].args[2] = ex.args[1].args[2].args[1]
    end
    iter = esc(ex.args[1].args[2])
    ind = gensym("i")
    startex = Expr(:(=), ind, 0)
    forex = Expr(:(=), vars[2], iter)
    index = Expr(:(=), vars[1], ind)
    increx = Expr(:(=), ind, Expr(:call, :(+), ind, 1))
    Expr(:let, Expr(:block,
        startex,
        Expr(:for, forex, Expr(:block,
            increx,
            index,
            body))),
        ind)
end

# both @take and @takestrict use @_take

macro _take(ex, strict)
    mname = strict ? "takestrict" : "take"
    @assert ex.head == :for
    @assert ex.args[1].head == :(=)
    isexpr(ex.args[1].args[2], :tuple) || throw(ArgumentError("@$(mname) macro needs an explicit tuple argument"))
    length(ex.args[1].args[2].args) == 2 || throw(ArgumentError("length of tuple must be 2 in @$(mname) macro"))
    body = esc(ex.args[2])
    var = esc(ex.args[1].args[1])
    iter = esc(ex.args[1].args[2].args[1])
    n = esc(ex.args[1].args[2].args[2])
    ind = gensym("i")
    state = gensym("s")
    startex = Expr(:block,
        Expr(:(=), ind, 0),
        Expr(:(=), state, Expr(:call, :(Base.start), iter)))
    notdoneex = Expr(:call, :(!), Expr(:||,
        Expr(:call, :(>=), ind, n),
        Expr(:call, :(Base.done), iter, state)))
    nextex = Expr(:block,
        Expr(:(=), Expr(:tuple, var, state),
                   Expr(:call, :(Base.next), iter, state)),
        Expr(:(=), ind, Expr(:call, :(+), ind, 1)))
    if strict
        checkex = Expr(:if, Expr(:call, :(<), ind, n),
            Expr(:call, :throw, ArgumentError("in takestrict(xs, n), xs had fewer than n items to take.")))
    else
        checkex = :nothing
    end

    Expr(:let, Expr(:block,
        startex,
        Expr(:while, notdoneex, Expr(:block,
            nextex,
            body)),
        checkex),
        ind, state)
end

macro take(ex)
    :(@_take($(esc(ex)), false))
end

macro takestrict(ex)
    :(@_take($(esc(ex)), true))
end

macro drop(ex)
    @assert ex.head == :for
    @assert ex.args[1].head == :(=)
    isexpr(ex.args[1].args[2], :tuple) || throw(ArgumentError("@drop macro needs an explicit tuple argument"))
    length(ex.args[1].args[2].args) == 2 || throw(ArgumentError("length of tuple must be 2 in @drop macro"))
    body = esc(ex.args[2])
    var = esc(ex.args[1].args[1])
    iter = esc(ex.args[1].args[2].args[1])
    n = esc(ex.args[1].args[2].args[2])
    ind = gensym("i")
    state = gensym("s")
    startex = Expr(:block,
        Expr(:(=), ind, 0),
        Expr(:(=), state, Expr(:call, :(Base.start), iter)))
    notdoneex1 = Expr(:call, :(!), Expr(:||,
        Expr(:call, :(>=), ind, n),
        Expr(:call, :(Base.done), iter, state)))
    nextex1 = Expr(:block,
        Expr(:(=), Expr(:tuple, var, state),
                   Expr(:call, :(Base.next), iter, state)),
        Expr(:(=), ind, Expr(:call, :(+), ind, 1)))
    notdoneex2 = Expr(:call, :(!), Expr(:call, :(Base.done), iter, state))
    nextex2 = Expr(:(=), Expr(:tuple, var, state), Expr(:call, :(Base.next), iter, state))

    Expr(:let, Expr(:block,
        startex,
        Expr(:while, notdoneex1, nextex1),
        Expr(:while, notdoneex2, Expr(:block,
            nextex2,
            body))),
        ind, state)
end

macro chain(ex)
    @assert ex.head == :for
    @assert ex.args[1].head == :(=)
    isexpr(ex.args[1].args[2], :tuple) || throw(ArgumentError("@chain macro needs explicit tuple arguments"))
    n = length(ex.args[1].args[2].args)
    body = esc(ex.args[2])
    var = esc(ex.args[1].args[1])
    iters = map(esc, ex.args[1].args[2].args)
    states = [gensym("s") for i=1:n]

    cycleex = [Expr(:block,
        Expr(:(=), states[i], Expr(:call, :(Base.start), iters[i])),
        Expr(:while, Expr(:call, :(!), Expr(:call, :(Base.done), iters[i], states[i])), Expr(:block,
            Expr(:(=), Expr(:tuple, var, states[i]), Expr(:call, :(Base.next), iters[i], states[i])),
            body))) for i = 1:n]

    Expr(:let, Expr(:block, cycleex...), states...)
end

end # module IterTools
