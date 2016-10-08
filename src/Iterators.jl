__precompile__()

module Iterators

using Compat
import Base: start, next, done, eltype, length, size

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
    @itr

# iteratorsize is new in 0.5, declare it here for older versions. However,
# we do not actually support calling these, since the traits are not defined
if VERSION < v"0.5.0-dev+3305"
    function iteratorsize(v)
        error("Do not call this on older versions")
    end
else
    import Base: iteratorsize, SizeUnknown, IsInfinite, HasLength
end


# Some iterators have been moved into Base (and count has been renamed as well)

import Base: count
Base.@deprecate count(start::Number, step::Number) countfrom(start, step)
Base.@deprecate count(start::Number) countfrom(start)
Base.@deprecate count() countfrom()

# Iterate through the first n elements, throwing an exception if
# fewer than n items ar encountered.

immutable TakeStrict{I}
    xs::I
    n::Int
end
iteratorsize{T<:TakeStrict}(::Type{T}) = HasLength()

eltype{I}(::Type{TakeStrict{I}}) = eltype(I)

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

immutable RepeatCall
    f::Function
    n::Int
end
iteratorsize{T<:RepeatCall}(::Type{T}) = HasLength()

length(it::RepeatCall) = it.n
repeatedly(f, n) = RepeatCall(f, n)

start(it::RepeatCall) = it.n
next(it::RepeatCall, state) = (it.f(), state - 1)
done(it::RepeatCall, state) = state <= 0


immutable RepeatCallForever
    f::Function
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

iteratorsize{T<:Chain}(::Type{T}) = SizeUnknown()

eltype{T}(::Type{Chain{T}}) = typejoin([eltype(t) for t in T.parameters]...)

chain(xss...) = Chain(xss)

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

iteratorsize{T<:Product}(::Type{T}) = SizeUnknown()

eltype{T}(::Type{Product{T}}) = Tuple{map(eltype, T.parameters)...}
length(p::Product) = mapreduce(length, *, 1, p.xss)

product(xss...) = Product(xss)

function start(it::Product)
    n = length(it.xss)
    js = Any[start(xs) for xs in it.xss]
    for i = 1:n
        if done(it.xss[i], js[i])
            return js, nothing
        end
    end
    vs = Array(Any, n)
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

distinct{I}(xs::I) = Distinct{I, eltype(xs)}(xs, Dict{eltype(xs), Int}())

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
immutable GroupBy{I}
    keyfunc::Function
    xs::I
end
iteratorsize{T<:GroupBy}(::Type{T}) = SizeUnknown()

# eltype{I}(it::GroupBy{I}) = I
eltype{I}(::Type{GroupBy{I}}) = Vector{eltype(I)}

function groupby(xs, keyfunc::Function)
    Base.warn_once("groupby(xs, keyfunc) should be groupby(keyfunc, xs)")
    groupby(keyfunc, xs)
end

function groupby(keyfunc, xs)
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
immutable IMap
    mapfunc::Base.Callable
    xs::Vector{Any}
end
iteratorsize{T<:IMap}(::Type{T}) = SizeUnknown()

function imap(mapfunc, it1, its...)
    IMap(mapfunc, Any[it1, its...])
end

function start(it::IMap)
    map(start, it.xs)
end

function next(it::IMap, state)
    next_result = map(next, it.xs, state)
    return (
        it.mapfunc(map(x -> x[1], next_result)...),
        map(x -> x[2], next_result)
    )
end

function done(it::IMap, state)
    any(map(done, it.xs, state))
end


# Iterate over all subsets of a collection

immutable Subsets{C}
    xs::C
end
iteratorsize{T<:Subsets}(::Type{T}) = HasLength()

eltype{C}(::Type{Subsets{C}}) = Vector{eltype(C)}
length(it::Subsets) = 1 << length(it.xs)

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

function nth(xs, n::Integer)
    n > 0 || throw(BoundsError(xs, n))
    # catch, if possible
    applicable(length, xs) && (n ≤ length(xs) || throw(BoundsError(xs, n)))
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

nth(xs::AbstractArray, n::Integer) = xs[n]


# takenth(xs,n): take every n'th element from xs

immutable TakeNth{I}
    xs::I
    interval::UInt
end
iteratorsize{I}(::Type{TakeNth{I}}) = iteratorsize(I)

length(x::TakeNth) = div(length(x.xs), x.interval)
size(x::TakeNth) = (length(x),)

function takenth(xs, interval::Integer)
    if interval <= 0
        throw(ArgumentError(string("expected interval to be 1 or more, ",
                                   "got $interval")))
    end
    TakeNth(xs, convert(UInt, interval))
end
eltype{I}(::Type{TakeNth{I}}) = eltype(I)


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
iteratorsize{T<:Iterate}(::Type{T}) = SizeUnknown()

iterate(f, seed) = Iterate(f, seed)
start(it::Iterate) = it.seed
next(it::Iterate, state) = (state, it.f(state))
done(it::Iterate, state) = (state==Union{})

using Base.Meta

## @itr macro for auto-inlining in for loops
#
# it dispatches on macros defined below

macro itr(ex)
    isexpr(ex, :for) || throw(ArgumentError("@itr macro expects a for loop"))
    isexpr(ex.args[1], :(=)) || throw(ArgumentError("malformed or unsupported for loop in @itr macro"))
    isexpr(ex.args[1].args[2], :call) || throw(ArgumentError("@itr macro expects an iterator call, e.g. @itr for (x,y) = zip(a,b)"))
    iterator = ex.args[1].args[2].args[1]
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

end # module Iterators
