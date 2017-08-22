macro test_zip(input...)
    n = length(input)
    x = Expr(:tuple, ntuple(i->gensym(), n)...)
    v = Expr(:tuple, map(esc, input)...)
    w = :(zip($(map(esc, input)...)))
    quote
    br = Any[]
    for $x in zip($v...)
        push!(br, $x)
    end
    mr = Any[]
    @itr for $x in $w
        push!(mr, $x)
    end
    @test br == mr
    end
end

macro test_enumerate(input)
    i = gensym()
    x = gensym()
    v = esc(input)
    quote
    br = Any[]
    for ($i,$x) in enumerate($v)
        push!(br, ($i,$x))
    end
    mr = Any[]
    @itr for ($i,$x) in enumerate($v)
        push!(mr, ($i,$x))
    end
    @test br == mr
    end
end

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

macro test_takestrict(input, n)
    x = gensym()
    v = esc(input)
    quote
    br = Any[]
    bfailed = false
    try
        for $x in takestrict($v, $n)
            push!(br, $x)
        end
    catch
        bfailed = true
    end

    mr = Any[]
    mfailed = false
    try
        @itr for $x in takestrict($v, $n)
            push!(mr, $x)
        end
    catch
        mfailed = true
    end
    @test br == mr
    @test bfailed == mfailed
    end
end

macro test_drop(input, n)
    x = gensym()
    v = esc(input)
    quote
    br = Any[]
    for $x in drop($v, $n)
        push!(br, $x)
    end
    mr = Any[]
    @itr for $x in drop($v, $n)
        push!(mr, $x)
    end
    @test br == mr
    end
end

macro test_chain(input...)
    x = gensym()
    v = Expr(:tuple, map(esc, input)...)
    w = :(chain($(map(esc, input)...)))
    quote
    br = Any[]
    for $x in chain($v...)
        push!(br, $x)
    end
    mr = Any[]
    @itr for $x in $w
        push!(mr, $x)
    end
    @test br == mr
    end
end
