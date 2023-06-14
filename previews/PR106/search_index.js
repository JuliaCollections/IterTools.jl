var documenterSearchIndex = {"docs":
[{"location":"functionindex/#Index","page":"Function index","title":"Index","text":"","category":"section"},{"location":"functionindex/","page":"Function index","title":"Function index","text":"","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"DocTestSetup = quote\n    using IterTools\nend","category":"page"},{"location":"#IterTools","page":"Introduction","title":"IterTools","text":"","category":"section"},{"location":"#Installation","page":"Introduction","title":"Installation","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Install this package with Pkg.add(\"IterTools\")","category":"page"},{"location":"#Usage","page":"Introduction","title":"Usage","text":"","category":"section"},{"location":"#distinct(xs)","page":"Introduction","title":"distinct(xs)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate through values skipping over those already encountered.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"distinct","category":"page"},{"location":"#IterTools.distinct","page":"Introduction","title":"IterTools.distinct","text":"distinct(xs)\n\nIterate through values skipping over those already encountered.\n\njulia> for i in distinct([1,1,2,1,2,4,1,2,3,4])\n           @show i\n       end\ni = 1\ni = 2\ni = 4\ni = 3\n\n\n\n\n\n","category":"function"},{"location":"#firstrest(xs)","page":"Introduction","title":"firstrest(xs)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Return first element and Iterators.rest iterator as a tuple.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"firstrest","category":"page"},{"location":"#IterTools.firstrest","page":"Introduction","title":"IterTools.firstrest","text":"firstrest(xs) -> (f, r)\n\nReturn the first element and an iterator of the rest as a tuple.\n\nSee also: Base.Iterators.peel.\n\njulia> f, r = firstrest(1:3);\n\njulia> f\n1\n\njulia> collect(r)\n2-element Vector{Int64}:\n 2\n 3\n\n\n\n\n\n","category":"function"},{"location":"#groupby(f,-xs)","page":"Introduction","title":"groupby(f, xs)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Group consecutive values that share the same result of applying f.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"groupby","category":"page"},{"location":"#IterTools.groupby","page":"Introduction","title":"IterTools.groupby","text":"groupby(f, xs)\n\nGroup consecutive values that share the same result of applying f.\n\njulia> for i in groupby(x -> x[1], [\"face\", \"foo\", \"bar\", \"book\", \"baz\", \"zzz\"])\n           @show i\n       end\ni = [\"face\", \"foo\"]\ni = [\"bar\", \"book\", \"baz\"]\ni = [\"zzz\"]\n\n\n\n\n\n","category":"function"},{"location":"#imap(f,-xs1,-[xs2,-...])","page":"Introduction","title":"imap(f, xs1, [xs2, ...])","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate over values of a function applied to successive values from one or more iterators.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"imap","category":"page"},{"location":"#IterTools.imap","page":"Introduction","title":"IterTools.imap","text":"imap(f, xs1, [xs2, ...])\n\nIterate over values of a function applied to successive values from one or more iterators. Like Iterators.zip, the iterator is done when any of the input iterators have been exhausted.\n\njulia> for i in imap(+, [1,2,3], [4,5,6])\n            @show i\n       end\ni = 5\ni = 7\ni = 9\n\n\n\n\n\n","category":"function"},{"location":"#iterated(f,-x)","page":"Introduction","title":"iterated(f, x)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate over successive applications of f, as in x, f(x), f(f(x)), f(f(f(x))), ....","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"iterated","category":"page"},{"location":"#IterTools.iterated","page":"Introduction","title":"IterTools.iterated","text":"iterated(f, x)\n\nIterate over successive applications of f, as in x, f(x), f(f(x)), f(f(f(x))), ...\n\nUse Base.Iterators.take() to obtain the required number of elements.\n\njulia> for i in Iterators.take(iterated(x -> 2x, 1), 5)\n           @show i\n       end\ni = 1\ni = 2\ni = 4\ni = 8\ni = 16\n\njulia> for i in Iterators.take(iterated(sqrt, 100), 6)\n           @show i\n       end\ni = 100\ni = 10.0\ni = 3.1622776601683795\ni = 1.7782794100389228\ni = 1.333521432163324\ni = 1.1547819846894583\n\n\n\n\n\n","category":"function"},{"location":"#ncycle(xs,-n)","page":"Introduction","title":"ncycle(xs, n)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Cycles through an iterator n times.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"ncycle","category":"page"},{"location":"#IterTools.ncycle","page":"Introduction","title":"IterTools.ncycle","text":"ncycle(iter, n)\n\nCycle through iter n times.\n\njulia> for i in ncycle(1:3, 2)\n           @show i\n       end\ni = 1\ni = 2\ni = 3\ni = 1\ni = 2\ni = 3\n\n\n\n\n\n","category":"function"},{"location":"#nth(xs,-n)","page":"Introduction","title":"nth(xs, n)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Return the nth element of xs.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"nth","category":"page"},{"location":"#IterTools.nth","page":"Introduction","title":"IterTools.nth","text":"nth(xs, n)\n\nReturn the nth element of xs. This is mostly useful for non-indexable collections.\n\njulia> powers_of_two = iterated(x->2x,1);\n\njulia> nth(powers_of_two, 4)\n8\n\n\n\n\n\n","category":"function"},{"location":"#partition(xs,-n,-[step])","page":"Introduction","title":"partition(xs, n, [step])","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Group values into n-tuples.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"partition","category":"page"},{"location":"#IterTools.partition","page":"Introduction","title":"IterTools.partition","text":"partition(xs, n, [step])\n\nGroup values into n-tuples.\n\njulia> for i in partition(1:9, 3)\n           @show i\n       end\ni = (1, 2, 3)\ni = (4, 5, 6)\ni = (7, 8, 9)\n\nIf the step parameter is set, each tuple is separated by step values.\n\njulia> for i in partition(1:9, 3, 2)\n           @show i\n       end\ni = (1, 2, 3)\ni = (3, 4, 5)\ni = (5, 6, 7)\ni = (7, 8, 9)\n\njulia> for i in partition(1:9, 3, 3)\n           @show i\n       end\ni = (1, 2, 3)\ni = (4, 5, 6)\ni = (7, 8, 9)\n\njulia> for i in partition(1:9, 2, 3)\n           @show i\n       end\ni = (1, 2)\ni = (4, 5)\ni = (7, 8)\n\n\n\n\n\n","category":"function"},{"location":"#ivec(xs)","page":"Introduction","title":"ivec(xs)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate over xs but do not preserve shape information.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"ivec","category":"page"},{"location":"#IterTools.ivec","page":"Introduction","title":"IterTools.ivec","text":"ivec(iter)\n\nDrops all shape from iter while iterating. Like a non-materializing version of vec.\n\njulia> m = collect(reshape(1:6, 2, 3))\n2×3 Matrix{Int64}:\n 1  3  5\n 2  4  6\n\njulia> collect(ivec(m))\n6-element Vector{Int64}:\n 1\n 2\n 3\n 4\n 5\n 6\n\n\n\n\n\n","category":"function"},{"location":"#peekiter(xs)","page":"Introduction","title":"peekiter(xs)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Peek at the head element of an iterator without updating the state.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"peekiter","category":"page"},{"location":"#IterTools.peekiter","page":"Introduction","title":"IterTools.peekiter","text":"peekiter(xs)\n\nLets you peek at the head element of an iterator without updating the state.\n\njulia> it = peekiter([\"face\", \"foo\", \"bar\", \"book\", \"baz\", \"zzz\"]);\n\njulia> peek(it)\nSome(\"face\")\n\njulia> peek(it)\nSome(\"face\")\n\njulia> x, s = iterate(it)\n(\"face\", (\"foo\", 3))\n\njulia> x\n\"face\"\n\njulia> peek(it, s)\nSome(\"foo\")\n\n\n\n\n\n","category":"function"},{"location":"#repeatedly(f,-[n])","page":"Introduction","title":"repeatedly(f, [n])","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Call a function n times, or infinitely if n is omitted.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"repeatedly","category":"page"},{"location":"#IterTools.repeatedly","page":"Introduction","title":"IterTools.repeatedly","text":"repeatedly(f)\nrepeatedly(f, n)\n\nCall function f n times, or infinitely if n is omitted.\n\njulia> t() = (sleep(0.1); Dates.millisecond(now()))\nt (generic function with 1 method)\n\njulia> collect(repeatedly(t, 5))\n5-element Vector{Any}:\n 993\n  97\n 200\n 303\n 408\n\n\n\n\n\n","category":"function"},{"location":"#takenth(xs,-n)","page":"Introduction","title":"takenth(xs, n)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate through every n'th element of xs","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"takenth","category":"page"},{"location":"#IterTools.takenth","page":"Introduction","title":"IterTools.takenth","text":"takenth(xs, n)\n\nIterate through every nth element of xs.\n\njulia> collect(takenth(5:15,3))\n3-element Vector{Int64}:\n  7\n 10\n 13\n\n\n\n\n\n","category":"function"},{"location":"#subsets(xs,-[k])","page":"Introduction","title":"subsets(xs, [k])","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate over every subset of an indexable collection xs, or iterate over every subset of size k from an indexable collection xs.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"subsets","category":"page"},{"location":"#IterTools.subsets","page":"Introduction","title":"IterTools.subsets","text":"subsets(xs)\nsubsets(xs, k)\nsubsets(xs, Val{k}())\n\nIterate over every subset of the indexable collection xs. You can restrict the subsets to a specific size k.\n\nGiving the subset size in the form Val{k}() allows the compiler to produce code optimized for the particular size requested. This leads to performance comparable to hand-written loops if k is small and known at compile time, but may or may not improve performance otherwise.\n\njulia> for i in subsets([1, 2, 3])\n          @show i\n       end\ni = Int64[]\ni = [1]\ni = [2]\ni = [1, 2]\ni = [3]\ni = [1, 3]\ni = [2, 3]\ni = [1, 2, 3]\n\njulia> for i in subsets(1:4, 2)\n          @show i\n       end\ni = [1, 2]\ni = [1, 3]\ni = [1, 4]\ni = [2, 3]\ni = [2, 4]\ni = [3, 4]\n\njulia> for i in subsets(1:4, Val{2}())\n           @show i\n       end\ni = (1, 2)\ni = (1, 3)\ni = (1, 4)\ni = (2, 3)\ni = (2, 4)\ni = (3, 4)\n\n\n\n\n\n","category":"function"},{"location":"#takestrict(xs,-n)","page":"Introduction","title":"takestrict(xs, n)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Equivalent to take, but will throw an exception if fewer than n items are encountered in xs.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"takestrict","category":"page"},{"location":"#IterTools.takestrict","page":"Introduction","title":"IterTools.takestrict","text":"takestrict(xs, n::Int)\n\nLike take(), an iterator that generates at most the first n elements of xs, but throws an exception if fewer than n items are encountered in xs.\n\njulia> collect(takestrict(1:2:11, 3))\n3-element Vector{Int64}:\n 1\n 3\n 5\n\n\n\n\n\n","category":"function"},{"location":"#takewhile(cond,-xs)","page":"Introduction","title":"takewhile(cond, xs)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterates through values from the iterable xs as long as a given predicate cond is true.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"takewhile","category":"page"},{"location":"#IterTools.takewhile","page":"Introduction","title":"IterTools.takewhile","text":"takewhile(cond, xs)\n\nAn iterator that yields values from the iterator xs as long as the predicate cond is true.\n\njulia> collect(takewhile(x-> x^2 < 10, 1:100))\n3-element Vector{Int64}:\n 1\n 2\n 3\n\n\n\n\n\n","category":"function"},{"location":"#flagfirst(xs)","page":"Introduction","title":"flagfirst(xs)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Provide a flag to check if this is the first element.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"flagfirst","category":"page"},{"location":"#IterTools.flagfirst","page":"Introduction","title":"IterTools.flagfirst","text":"flagfirst(iter)\n\nAn iterator that yields (isfirst, x) where isfirst::Bool is true for the first element, and false after that, while the xs are elements from iter.\n\njulia> collect(flagfirst(1:3))\n3-element Vector{Tuple{Bool, Int64}}:\n (1, 1)\n (0, 2)\n (0, 3)\n\n\n\n\n\n","category":"function"},{"location":"#IterTools.@ifsomething","page":"Introduction","title":"IterTools.@ifsomething","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Helper macro for returning from the enclosing block when there are no more elements.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"IterTools.@ifsomething","category":"page"},{"location":"#IterTools.@ifsomething","page":"Introduction","title":"IterTools.@ifsomething","text":"IterTools.@ifsomething expr\n\nIf expr evaluates to nothing, equivalent to return nothing, otherwise the macro evaluates to the value of expr. Not exported, useful for implementing iterators.\n\njulia> IterTools.@ifsomething iterate(1:2)\n(1, 1)\n\njulia> let elt, state = IterTools.@ifsomething iterate(1:2, 2); println(\"not reached\"); end\n\n\n\n\n\n","category":"macro"},{"location":"#properties(x)","page":"Introduction","title":"properties(x)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate over struct or named tuple properties.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"properties","category":"page"},{"location":"#IterTools.properties","page":"Introduction","title":"IterTools.properties","text":"properties(x)\n\nIterate through the names and value of the properties of x.\n\njulia> collect(properties(1 + 2im))\n2-element Vector{Any}:\n (:re, 1)\n (:im, 2)\n\n\n\n\n\n","category":"function"},{"location":"#propertyvalues(x)","page":"Introduction","title":"propertyvalues(x)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate over struct or named tuple property values.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"propertyvalues","category":"page"},{"location":"#IterTools.propertyvalues","page":"Introduction","title":"IterTools.propertyvalues","text":"propertyvalues(x)\n\nIterate through the values of the properties of x.\n\njulia> collect(propertyvalues(1 + 2im))\n2-element Vector{Any}:\n 1\n 2\n\n\n\n\n\n","category":"function"},{"location":"#fieldvalues(x)","page":"Introduction","title":"fieldvalues(x)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Like (getfield(x, i) for i in 1:nfields(x)) but faster.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"fieldvalues","category":"page"},{"location":"#IterTools.fieldvalues","page":"Introduction","title":"IterTools.fieldvalues","text":"fieldvalues(x)\n\nIterate through the values of the fields of x.\n\njulia> collect(fieldvalues(1 + 2im))\n2-element Vector{Any}:\n 1\n 2\n\n\n\n\n\n","category":"function"},{"location":"#interleaveby(a,b,-predicate-,-fa-identity,-fb-identity)","page":"Introduction","title":"interleaveby(a,b, predicate = <=, fa = identity, fb = identity)","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Iterate over the union of a and b, merge-sort style.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"interleaveby","category":"page"},{"location":"#IterTools.interleaveby","page":"Introduction","title":"IterTools.interleaveby","text":"interleaveby(predicate=Base.isless, a, b)\n\nIterate over the an interleaving of a and b selected by the predicate (default less-than).\n\nInput:\n\npredicate(ak,bk) -> Bool:  Whether to pick the next element of a (true) or b (false).\nfa(ak), fb(bk): Functions to apply to the picked elements\n\njulia> collect(interleaveby(1:2:5, 2:2:6))\n6-element Vector{Int64}:\n  1\n  2\n  3\n  4\n  5\n  6\n\nIf the predicate is Base.isless (the default) and both inputs are sorted, this produces the sorted output. If the predicate is a stateful functor that alternates true-false-true-false... then this produces the classic interleave operation as described e.g. in the definition of microkanren.\n\n\n\n\n\n","category":"function"}]
}