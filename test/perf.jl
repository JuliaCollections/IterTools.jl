using BenchmarkLite
using Iterators

type Collect{Itr} <: Proc end

Base.string{Itr}(::Collect{Itr}) = string(Itr)
Base.length(::Collect, n::Int) = n
Base.isvalid(::Collect, n::Int) = n > 0
Base.done(::Collect, n, s) = nothing

abstract Take

type Take1 <: Take end
type Take2 <: Take end
type Take3 <: Take end
type Take4 <: Take end
type Take5 <: Take end
type Take6 <: Take end

collect(::Take, v, n) = Base.collect(take(v, n))

function Base.run{Itr<:Take}(::Collect{Itr}, n::Int, v)
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

abstract Partition

type Partition1 <: Partition end
type Partition2 <: Partition end
type Partition3 <: Partition end

collect(::Partition, v, m, n) = Base.collect(partition(v, m, n))

function Base.run{Itr<:Partition}(p::Collect{Itr}, n::Int, state)
    v,x,y = state
    op = Itr()
    collect(op, v, x, y)
end

Base.start(::Collect{Partition1}, n::Int) = (1:n+1, 2, 1)
Base.start(::Collect{Partition2}, n::Int) = (1:3n+3, 2, 3)
Base.start(::Collect{Partition3}, n::Int) = (1:10n+10, 2, 10)

############

abstract GroupBy

type GroupBy1 <: GroupBy end
type GroupBy2 <: GroupBy end

collect(::GroupBy, v, f) = Base.collect(groupby(v, f))

function Base.run{Itr<:GroupBy}(p::Collect{Itr}, n::Int, state)
    v, f = state
    op = Itr()
    collect(op, v, f)
end

Base.start(::Collect{GroupBy1}, n::Int) = (["abc"[[rand(1:3), rand(1:3)]] for i = 1:n], x->x[1])
Base.start(::Collect{GroupBy2}, n::Int) = (1:n, iseven)

############

type IMap end

collect(::IMap, op, vs) = Base.collect(imap(op, vs...))

function Base.run(p::Collect{IMap}, n::Int, state)
    iop, vs = state
    op = IMap()
    collect(op, iop, vs)
end

Base.start(::Collect{IMap}, n::Int) = (+, (1:n, 2n:-2:0))

############

type Distinct end
collect(::Distinct, v) = Base.collect(distinct(v))

type Subsets end
collect(::Subsets, v) = Base.collect(subsets(v))

function Base.run{Itr<:Union(Subsets, Distinct)}(p::Collect{Itr}, n::Int, v)
    op = Itr()
    collect(op, v)
end

Base.start(::Collect{Distinct}, n::Int) = rand(1:n, n)
Base.start(::Collect{Subsets}, n::Int) = 1:n

#############

type Chain end
collect(::Chain, vs) = Base.collect(chain(vs...))

type Product end
collect(::Product, vs) = Base.collect(product(vs...))

function Base.run{Itr<:Union(Chain, Product)}(p::Collect{Itr}, n::Int, vs)
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
              Collect{GroupBy1}(),
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
