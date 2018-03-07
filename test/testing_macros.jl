macro test_take(input, n)
    x = gensym()
    v = esc(input)
    quote
    br = Any[]
    for $x in take($v, $n)
        push!(br, $x)
    end
    mr = Any[]
    @itr for $x in take($v, $n)
        push!(mr, $x)
    end
    @test br == mr
    end
end
