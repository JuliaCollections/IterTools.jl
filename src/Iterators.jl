VERSION >= v"0.4.0-dev+6521" && __precompile__()

module Iterators

using Compat
import Base: start, next, done, eltype, length

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
    takenth,
    @itr


# Some iterators have been moved into Base (and count has been renamed as well)
if VERSION >= v"0.4.0-def+3323"

    import Base: count
    Base.@deprecate count(start::Number, step::Number) countfrom(start, step)
    Base.@deprecate count(start::Number) countfrom(start)
    Base.@deprecate count() countfrom()
else

    import Base: take, count

    export
        countfrom,
        count,
        take,
        drop,
        cycle,
        repeated

    # Infinite counting

    immutable Count{S<:Number}
        start::S
        step::S
    end

    eltype{S}(it::Count{S}) = S

    count(start::Number, step::Number) = Count(promote(start, step)...)
    count(start::Number)               = Count(start, one(start))
    count()                            = Count(0, 1)

    # Deprecate on 0.3 as well?
    countfrom(start::Number, step::Number) = count(start, step)
    countfrom(start::Number)               = count(start)
    countfrom()                            = count(1)

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

length(it::RepeatCall) = it.n
repeatedly(f, n) = RepeatCall(f, n)

start(it::RepeatCall) = it.n
next(it::RepeatCall, state) = (it.f(), state - 1)
done(it::RepeatCall, state) = state <= 0


immutable RepeatCallForever
    f::Function
end

repeatedly(f) = RepeatCallForever(f)

start(it::RepeatCallForever) = nothing
next(it::RepeatCallForever, state) = (it.f(), nothing)
done(it::RepeatCallForever, state) = false


# Concatenate the output of n iterators

immutable Chain
    xss::Vector{Any}
    function Chain(xss...)
        new(Any[xss...])
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
        new(Any[xss...])
    end
end

# Using @compat causes error JuliaLang/Compat.jl#81
# eltype(p::Product) = @compat(Tuple{map(eltype, p.xss)...})
if VERSION >= v"0.4-dev"
    eltype(p::Product) = Tuple{map(eltype, p.xss)...}
else
    eltype(p::Product) = tuple(map(eltype, p.xss)...)
end
length(p::Product) = prod(map(length, p.xss))

product(xss...) = Product(xss...)

function start(it::Product)
    n = length(it.xss)
    js = Any[start(xs) for xs in it.xss]
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

# Using @compat causes error JuliaLang/Compat.jl#81
# eltype(it::Partition) = @compat(Tuple{fill(eltype(it.xs),it.n)...})
if VERSION >= v"0.4-dev"
    eltype(it::Partition) = Tuple{fill(eltype(it.xs),it.n)...}
else
    eltype(it::Partition) = tuple(fill(eltype(it.xs),it.n)...)
end

function partition(xs, n::Int)
    Partition(xs, n, n)
end

function partition(xs, n::Int, step::Int)
    if step < 1
        throw(ArgumentError("Partition step must be at least 1."))
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
    keyfunc::Function
    xs::I
end

eltype{I}(it::GroupBy{I}) = I
eltype{I<:Range}(it::GroupBy{I}) = Array{eltype(it.xs),}

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


# Iterate over all subsets of a collection with a given size

immutable Binomial{T}
    xs::Array{T,1}
    n::Int64
    k::Int64
end

eltype(it::Binomial) = Array{eltype(it.xs),1}
length(it::Binomial) = binomial(it.n,it.k)

subsets(xs,k) = Binomial(xs,length(xs),k)

start(it::Binomial) = (collect(Int64, 1:it.k), false)

function next(it::Binomial, state::(@compat Tuple{Array{Int64,1}, Bool}))
    idx = state[1]
    set = it.xs[idx]
    i = it.k
    while(i>0)
        if idx[i] < it.n - it.k + i
            idx[i] += 1
            idx[i+1:it.k] = idx[i]+1:idx[i]+it.k-i
            break
        else
            i -= 1
        end
    end
    if i==0
        return set, (idx,true)
    else
        return set, (idx,false)
    end
end

done(it::Binomial, state::(@compat Tuple{Array{Int64,1}, Bool})) = state[2]


# takenth(xs,n): take every n'th element from xs

immutable TakeNth{I}
    xs::I
    interval::Uint
end

function takenth(xs, interval::Integer)
    if interval <= 0
        throw(ArgumentError(string("expected interval to be 1 or more, ",
                                   "got $interval")))
    end
    TakeNth(xs, convert(Uint, interval))
end
eltype(en::TakeNth) = eltype(en.xs)


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

iterate(f, seed) = Iterate(f, seed)
start(it::Iterate) = it.seed
next(it::Iterate, state) = (state, it.f(state))
done(it::Iterate, state) = (state==None)

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
