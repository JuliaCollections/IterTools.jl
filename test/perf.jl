using BenchmarkLite
using IterTools
using Compat

mutable struct Collect{Itr} <: Proc end

Base.string(::Collect{Itr}) where {Itr} = string(Itr)
Base.length(::Collect, n::Int) = n
Base.isvalid(::Collect, n::Int) = n > 0
Base.done(::Collect, n, s) = nothing

abstract type Take end

mutable struct Take1 <: Take end
mutable struct Take2 <: Take end
mutable struct Take3 <: Take end
mutable struct Take4 <: Take end
mutable struct Take5 <: Take end
mutable struct Take6 <: Take end

collect(::Take, v, n) = Base.collect(take(v, n))

function Base.run(::Collect{Itr}, n::Int, v) where Itr<:Take
    op = Itr()
    collect(op, v, n)
end

Base.start(::Collect{Take1}, n::Int) = count()
Base.start(::Collect{Take2}, n::Int) = repeated(1)
Base.start(::Collect{Take3}, n::Int) = cycle(1:3)
Base.start(::Collect{Take4}, n::Int) = cycle(1:500)
Base.start(::Collect{Take5}, n::Int) = chain(filter(iseven, 1:n), count(2,2))
Base.start(::Collect{Take6}, n::Int) = partition(cycle(1:3), 2, 1)

############

abstract type Partition end

mutable struct Partition1 <: Partition end
mutable struct Partition2 <: Partition end
mutable struct Partition3 <: Partition end

collect(::Partition, v, m, n) = Base.collect(partition(v, m, n))

function Base.run(p::Collect{Itr}, n::Int, state) where Itr<:Partition
    v,x,y = state
    op = Itr()
    collect(op, v, x, y)
end

Base.start(::Collect{Partition1}, n::Int) = (1:n+1, 2, 1)
Base.start(::Collect{Partition2}, n::Int) = (1:3n+3, 2, 3)
Base.start(::Collect{Partition3}, n::Int) = (1:10n+10, 2, 10)

############

abstract type GroupBy end

mutable struct GroupBy1 <: GroupBy end
mutable struct GroupBy2 <: GroupBy end

collect(::GroupBy, f, v) = Base.collect(groupby(f, v))

function Base.run(p::Collect{Itr}, n::Int, state) where Itr<:GroupBy
    f, v = state
    op = Itr()
    collect(op, f, v)
end

Base.start(::Collect{GroupBy1}, n::Int) = (x->x[1], ["abc"[[rand(1:3), rand(1:3)]] for i = 1:n])
Base.start(::Collect{GroupBy2}, n::Int) = (iseven, [1:n])

############

mutable struct IMap end

collect(::IMap, op, vs) = Base.collect(imap(op, vs...))

function Base.run(p::Collect{IMap}, n::Int, state)
    iop, vs = state
    op = IMap()
    collect(op, iop, vs)
end

Base.start(::Collect{IMap}, n::Int) = (+, (1:n, 2n:-2:0))

############

mutable struct Distinct end
collect(::Distinct, v) = Base.collect(distinct(v))

mutable struct Subsets end
collect(::Subsets, v) = Base.collect(subsets(v))

function Base.run(p::Collect{Itr}, n::Int, v) where Itr<:Union{Subsets, Distinct}
    op = Itr()
    collect(op, v)
end

Base.start(::Collect{Distinct}, n::Int) = rand(1:n, n)
Base.start(::Collect{Subsets}, n::Int) = 1:n

#############

mutable struct Chain end
collect(::Chain, vs) = Base.collect(chain(vs...))

mutable struct Product end
collect(::Product, vs) = Base.collect(product(vs...))

function Base.run(p::Collect{Itr}, n::Int, vs) where Itr<:Union{Chain, Product}
    op = Itr()
    collect(op, vs)
end

Base.start(::Collect{Chain}, n::Int) = (1:3:n, 2:3:n+1, 3:3:n+2)
Base.start(::Collect{Product}, n::Int) = (1:n>>1, 1:n>>2, 1:n>>3)

################

procs1 = Proc[
              Collect{Take1}(),
              Collect{Take2}(),
              Collect{Take3}(),
              Collect{Take4}(),
              Collect{Take5}(),
              Collect{Take6}(),
              Collect{Partition1}(),
              Collect{Partition2}(),
              Collect{Partition3}(),
              Collect{GroupBy1}(),
              Collect{GroupBy2}(),
              Collect{Distinct}(),
              Collect{Chain}(),
             ]

cfgs1 = 4 .^ (6:10)

procs2 = Proc[
              Collect{Subsets}(),
              ]

cfgs2 = [4:2:16]

procs3 = Proc[
              Collect{Product}(),
              ]

cfgs3 = 2 .^ (5:7)

###########

rtable1 = run(procs1, cfgs1)
rtable2 = run(procs2, cfgs2)
rtable3 = run(procs3, cfgs3)

show(rtable1; unit=:msec)
println()
show(rtable2; unit=:msec)
println()
show(rtable3; unit=:msec)
println()
