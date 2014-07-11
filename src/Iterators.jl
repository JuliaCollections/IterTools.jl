module Iterators
using Base

import Base: start, next, done, count, take, eltype, length

export
    count,
    take,
    takestrict,
    drop,
    cycle,
    repeated,
    chain,
    product,
    distinct,
    partition,
    groupby,
    imap,
    subsets,
    iterate,
    @itr

# Infinite counting

immutable Count{S<:Number}
    start::S
    step::S
end

eltype{S}(it::Count{S}) = S

count(start::Number, step::Number) = Count(promote(start, step)...)
count(start::Number)               = Count(start, one(start))
count()                            = Count(0, 1)

start(it::Count) = it.start
next(it::Count, state) = (state, state + it.step)
done(it::Count, state) = false


# Iterate through the first n elements

immutable Take{I}
    xs::I
    n::Int
end

eltype(it::Take) = eltype(it.xs)

take(xs, n::Int) = Take(xs, n)

start(it::Take) = (it.n, start(it.xs))

function next(it::Take, state)
    n, xs_state = state
    v, xs_state = next(it.xs, xs_state)
    return v, (n - 1, xs_state)
end

function done(it::Take, state)
    n, xs_state = state
    return n <= 0 || done(it.xs, xs_state)
end


# Iterate through the first n elements, throwing an exception if
# fewer than n items ar encountered.

immutable TakeStrict{I}
    xs::I
    n::Int
end

eltype(it::TakeStrict) = eltype(it.xs)

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
        error("In takestrict(xs, n), xs had fewer than n items to take.")
    else
        return false
    end
end

function length(it::TakeStrict)
    return it.n
end


# Iterator through all but the first n elements

immutable Drop{I}
    xs::I
    n::Int
end

eltype(it::Drop) = eltype(it.xs)

drop(xs, n::Int) = Drop(xs, n)

function start(it::Drop)
    xs_state = start(it.xs)
    for i in 1:it.n
        if done(it.xs, xs_state)
            break
        end

        _, xs_state = next(it.xs, xs_state)
    end
    xs_state
end

next(it::Drop, state) = next(it.xs, state)
done(it::Drop, state) = done(it.xs, state)


# Cycle an iterator forever

immutable Cycle{I}
    xs::I
end

eltype(it::Cycle) = eltype(it.xs)

cycle(xs) = Cycle(xs)

function start(it::Cycle)
    s = start(it.xs)
    return s, done(it.xs, s)
end

function next(it::Cycle, state)
    s, d = state
    if done(it.xs, s)
        s = start(it.xs)
    end
    v, s = next(it.xs, s)
    return v, (s, false)
end

done(it::Cycle, state) = state[2]

# Repeat an object n (or infinitely many) times.

immutable Repeat{O}
    x::O
    n::Int
end

eltype{O}(it::Repeat{O}) = O
length(it::Repeat) = it.n

repeated(x, n) = Repeat(x, n)

start(it::Repeat) = it.n
next(it::Repeat, state) = (it.x, state - 1)
done(it::Repeat, state) = state <= 0


immutable RepeatForever{O}
    x::O
end

eltype{O}(r::RepeatForever{O}) = O

repeated(x) = RepeatForever(x)

start(it::RepeatForever) = nothing
next(it::RepeatForever, state) = (it.x, nothing)
done(it::RepeatForever, state) = false



# Concatenate the output of n iterators

immutable Chain
    xss::Vector{Any}
    function Chain(xss...)
        new({xss...})
    end
end

function eltype(it::Chain)
    try
        typejoin([eltype(xs) for xs in it.xss]...)
    catch
        Any
    end
end

chain(xss...) = Chain(xss...)

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

immutable Product
    xss::Vector{Any}
    function Product(xss...)
        new({xss...})
    end
end

eltype(p::Product) = tuple(map(eltype, p.xss)...)
length(p::Product) = prod(map(length, p.xss))

product(xss...) = Product(xss...)

function start(it::Product)
    n = length(it.xss)
    js = {start(xs) for xs in it.xss}
    if n == 0
        return js, nothing
    end
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
            break
        elseif i == n
            vs = nothing
            break
        end

        js[i] = start(it.xss[i])
        vs[i], js[i] = next(it.xss[i], js[i])
    end
    return ans, (js, vs)
end

done(it::Product, state) = state[2] === nothing


# Filter out reccuring elements.

immutable Distinct{I}
    xs::I

    # Map elements to the index at which it was first seen, so given an iterator
    # state (index) we can test if an element has previously been observed.
    seen::Dict{Any, Int}

    Distinct(xs) = new(xs, Dict{Any, Int}())
end

eltype(it::Distinct) = eltype(it.xs)

distinct{I}(xs::I) = Distinct{I}(xs)

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

immutable Partition{I}
    xs::I
    n::Int
    step::Int
end

eltype(it::Partition) = tuple(fill(eltype(it.xs),it.n)...)

function partition(xs, n::Int)
    Partition(xs, n, n)
end

function partition(xs, n::Int, step::Int)
    if step < 1
        error("Partition step must be at least 1.")
    end

    Partition(xs, n, step)
end

function start(it::Partition)
    p = Array(eltype(it.xs), it.n)
    s = start(it.xs)
    for i in 1:(it.n - 1)
        if done(it.xs, s)
            break
        end
        (p[i], s) = next(it.xs, s)
    end
    (s, p)
end

function next(it::Partition, state)
    (s, p0) = state
    (x, s) = next(it.xs, s)
    ans = p0; ans[end] = x

    p = similar(p0)
    overlap = max(0, it.n - it.step)
    for i in 1:overlap
        p[i] = ans[it.step + i]
    end

    # when step > n, skip over some elements
    for i in 1:max(0, it.step - it.n)
        if done(it.xs, s)
            break
        end
        (x, s) = next(it.xs, s)
    end

    for i in (overlap + 1):(it.n - 1)
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
#   groupby(x, z -> z[1]) =
#       ["face", "foo"]
#       ["bar", "book", "baz"]
#       ["zzz"]
immutable GroupBy{I}
    xs::I
    keyfunc::Function
end

eltype{I}(it::GroupBy{I}) = I
eltype{I<:Ranges}(it::GroupBy{I}) = Array{eltype(it.xs),}

function groupby(xs, keyfunc)
    GroupBy(xs, keyfunc)
end

function start(it::GroupBy)
    s = start(it.xs)
    prev_value = nothing
    prev_key = nothing
    return (s, (prev_key, prev_value))
end

function next(it::GroupBy, state)
    (s, (prev_key, prev_value)) = state
    values = Array(eltype(it.xs), 0)
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

function imap(mapfunc, it1, its...)
    IMap(mapfunc, {it1, its...})
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

immutable Subsets
    xs
end

eltype(it::Subsets) = Array{eltype(it.xs),1}
length(it::Subsets) = 1 << length(it.xs)

function subsets(xs)
    Subsets(xs)
end

function start(it::Subsets)
    # one extra bit to indicated that we are at the end
    BitVector(length(it.xs) + 1)
end

function next(it::Subsets, state)
    ss = Array(eltype(it.xs), 0)
    for i = 1:length(it.xs)
        if state[i]
            push!(ss, it.xs[i])
        end
    end

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

# Unfolding (anamorphism)
# Outputs the stream: seed, f(seed), f(f(seed)), ...

immutable Iterate{T}
    f::Function
    seed::T
end

iterate(f, seed) = Iterate(f, seed)
start(it::Iterate) = it.seed
next(it::Iterate, state) = (state, it.f(state))
done(it::Iterate, state) = (state==None)

using Base.Meta

## @itr macro for auto-inlining in for loops
#
# it dispatches on macros defined below

macro itr(ex)
    isexpr(ex, :for) || error("@itr macro expects a for loop")
    isexpr(ex.args[1], :(=)) || error("malformed or unsupported for loop in @itr macro")
    isexpr(ex.args[1].args[2], :call) || error("@itr macro expects an iterator call, e.g. @itr for (x,y) = zip(a,b)")
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
        error("unknown or unsupported iterator $iterator in @itr macro")
    end
    return rex
end

macro zip(ex)
    @assert ex.head == :for
    @assert ex.args[1].head == :(=)
    isexpr(ex.args[1].args[1], :tuple) || error("@zip macro needs explicit tuple arguments")
    isexpr(ex.args[1].args[2], :tuple) || error("@zip macro needs explicit tuple arguments")
    n = length(ex.args[1].args[1].args)
    length(ex.args[1].args[2].args) == n || error("unequal tuple sizes in @zip macro")
    body = esc(ex.args[2])
    vars = map(esc, ex.args[1].args[1].args)
    iters = map(esc, ex.args[1].args[2].args)
    states = [gensym("s") for i=1:n]
    as = {Expr(:call, :(Base.start), iters[i]) for i=1:n}
    startex = Expr(:(=), Expr(:tuple, states...), Expr(:tuple, as...))
    ad = {Expr(:call, :(Base.done), iters[i], states[i]) for i = 1:n}
    notdoneex = Expr(:call, :(!), Expr(:||, ad...))
    nextex = Expr(:(=), Expr(:tuple, {Expr(:tuple, vars[i], states[i]) for i=1:n}...),
                        Expr(:tuple, {Expr(:call, :(Base.next), iters[i], states[i]) for i=1:n}...))
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
    isexpr(ex.args[1].args[1], :tuple) || error("@enumerate macro needs an explicit tuple argument")
    length(ex.args[1].args[1].args) == 2 || error("lentgh of tuple must be 2 in @enumerate macro")
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
    isexpr(ex.args[1].args[2], :tuple) || error("@$(mname) macro needs an explicit tuple argument")
    length(ex.args[1].args[2].args) == 2 || error("length of tuple must be 2 in @$(mname) macro")
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
            Expr(:call, :error, "in takestrict(xs, n), xs had fewer than n items to take."))
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
    isexpr(ex.args[1].args[2], :tuple) || error("@drop macro needs an explicit tuple argument")
    length(ex.args[1].args[2].args) == 2 || error("length of tuple must be 2 in @drop macro")
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
    isexpr(ex.args[1].args[2], :tuple) || error("@chain macro needs explicit tuple arguments")
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
