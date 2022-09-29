"""

    chunks(array::AbstractArray, nchunks::Int, chunk_type::Symbol=:batch)

This function returns an iterable object that will split the *indices* of `array` into
to `nchunks` chunks. `chunk_type` can be `:batch` or `:scatter`. It can be used to directly iterate
over the chunks of a collection in a multi-threaded manner.

## Eamples

The iteration over `chunks` provides ranges that are continous sets of indices in 
the `:batch` option (default), or indices that distant from each other if using `:scatter`.

```julia-repl
julia> using IterTools

julia> x = rand(7);

julia> Threads.@threads for (range, ichunk) in chunks(x, 3, :batch)
           @show Threads.threadid(), range, ichunk
       end
(Threads.threadid(), range, ichunk) = (3, 1:3, 1)
(Threads.threadid(), range, ichunk) = (8, 6:7, 3)
(Threads.threadid(), range, ichunk) = (12, 4:5, 2)

julia> Threads.@threads for (range, ichunk) in chunks(x, 3, :scatter)
           @show Threads.threadid(), range, ichunk
       end
(Threads.threadid(), range, ichunk) = (5, 3:3:6, 3)
(Threads.threadid(), range, ichunk) = (2, 1:3:7, 1)
(Threads.threadid(), range, ichunk) = (3, 2:3:5, 2)
```

The ranges and chunk indices obtained in the iterations can be used to fine control
multi-threaded updates of shared variables. For example, consider the simple parallel
sum:

```julia-repl
julia> function sum_parallel(f, x; nchunks=Threads.nthreads())
           s = fill(zero(eltype(x)), nchunks)
           Threads.@threads for (xrange, ichunk) in chunks(x, nchunks)
               for i in xrange
                   s[ichunk] += f(x[i])
               end
           end
           return sum(s)
       end
sum_parallel (generic function with 1 method)

julia> x = rand(10^7);

julia> sum_parallel(x -> log(x)^7, x; nchunks=12)
-4.981040495460925e10
```

The fine control of chunk size can provide important performance benefits:
```julia-repl
julia> Threads.nthreads()
12

julia> @btime sum_parallel(x -> log(x)^7, \$x; nchunks=12)
  34.274 ms (77 allocations: 6.61 KiB)
-4.981040495460925e10

julia> @btime sum_parallel(x -> log(x)^7, \$x; nchunks=128)
  21.568 ms (77 allocations: 7.52 KiB)
-4.981040495462144e10
```

"""
function chunks end

# Current chunks types
const chunks_types = (:batch, :scatter)

# Structure that carries the chunks data
struct Chunk{I,N,T}
    x::I
    nchunks::Int
end

# Constructor for the chunks
function chunks(x::AbstractArray, nchunks::Int, chunk_type=:batch)
    nchunks >= 1 || throw(ArgumentError("nchunks must be >= 1"))
    (chunk_type in chunks_types) || throw(ArgumentError("chunk_type must be one of $chunks_types"))
    Chunk{typeof(x),nchunks,chunk_type}(x, nchunks)
end

import Base: length, eltype
length(::Chunk{I,N}) where {I,N} = N
eltype(::Chunk) = UnitRange{Int}

import Base: firstindex, lastindex, getindex
firstindex(::Chunk) = 1
lastindex(::Chunk{I,N}) where {I,N} = N
getindex(it::Chunk{I,N,T}, i::Int) where {I,N,T} = (chunks(it.x, i, it.nchunks, T), i)

#
# Iteration of the chunks
#
import Base: iterate
function iterate(it::Chunk{I,N,T}, state=nothing) where {I,N,T}
    if isnothing(state)
        return ((chunks(it.x, 1, it.nchunks, T), 1), 1)
    elseif state < it.nchunks
        return ((chunks(it.x, state + 1, it.nchunks, T), state + 1), state + 1)
    else
        return nothing
    end
end

#
# This is the lower level function that receives `ichunk` as a parameter
#
"""
    chunks(array::AbstractArray, ichunk::Int, nchunks::Int, chunk_type::Symbol=:batch)

Lower level function that returns a range of indexes of `array`, given the number of chunks in
which the array is to be split, `nchunks`, and the current chunk number `ichunk`. 

# Extended help

If `chunk_type == :batch`, the ranges are consecutive. If `chunk_type == :scatter`, the range
is scattered over the array. 

## Example

For example, if we have an array of 7 elements, and the work on the elements is divided
into 3 chunks, we have (using the default `chunk_type = :batch` option):

```julia-repl
julia> using ChunkSplitters

julia> x = rand(7);

julia> chunks(x, 1, 3)
1:3

julia> chunks(x, 2, 3)
4:5

julia> chunks(x, 3, 3)
6:7
```

And using `chunk_type = :scatter`, we have:

```julia-repl
julia> chunks(x, 1, 3, :scatter)
1:3:7

julia> chunks(x, 2, 3, :scatter)
2:3:5

julia> chunks(x, 3, 3, :scatter)
3:3:6
```
"""
function chunks(array::AbstractArray, ichunk::Int, nchunks::Int, chunk_type::Symbol=:batch)
    ichunk <= nchunks || throw(ArgumentError("ichunk must be less or equal to nchunks"))
    return _chunks(array, ichunk, nchunks, Val(chunk_type))
end

#
# function that splits the work in chunks that are scattered over the array
#
function _chunks(array, ichunk, nchunks, ::Val{:scatter})
    first = (firstindex(array) - 1) + ichunk
    last = lastindex(array)
    step = nchunks
    return first:step:last
end

#
# function that splits the work in batches that are consecutive in the array
#
function _chunks(array, ichunk, nchunks, ::Val{:batch})
    n = length(array)
    n_per_chunk = div(n, nchunks)
    n_remaining = n - nchunks * n_per_chunk
    first = firstindex(array) + (ichunk - 1) * n_per_chunk + ifelse(ichunk <= n_remaining, ichunk - 1, n_remaining)
    last = (first - 1) + n_per_chunk + ifelse(ichunk <= n_remaining, 1, 0)
    return first:last
end
