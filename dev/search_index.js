var documenterSearchIndex = {"docs":
[{"location":"reference/#API-Reference","page":"API Reference","title":"API Reference","text":"","category":"section"},{"location":"reference/","page":"API Reference","title":"API Reference","text":"Modules = [IterTools]","category":"page"},{"location":"reference/#IterTools.cache-Tuple{IT} where IT","page":"API Reference","title":"IterTools.cache","text":"cache(it)\n\nCache the elements of an iterator so that subsequent iterations are served from the cache.\n\njulia> c = cache(Iterators.map(println, 1:3));\n\njulia> collect(c);\n1\n2\n3\n\njulia> collect(c);\n\n\nBe aware that if iterating the original  has a side-effect it will not be repeated when iterating again,  – indeed that is a key feature of the CachedIterator. Be aware also that if the original iterator is nondeterminatistic in its order, when iterating again from the cache it will infact be determinatistic and will be the same order as before – this also is a feature.\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.distinct-Tuple{I} where I","page":"API Reference","title":"IterTools.distinct","text":"distinct(xs)\n\nIterate through values skipping over those already encountered.\n\njulia> for i in distinct([1,1,2,1,2,4,1,2,3,4])\n           @show i\n       end\ni = 1\ni = 2\ni = 4\ni = 3\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.fieldvalues-Tuple{T} where T","page":"API Reference","title":"IterTools.fieldvalues","text":"fieldvalues(x)\n\nIterate through the values of the fields of x.\n\njulia> collect(fieldvalues(1 + 2im))\n2-element Vector{Any}:\n 1\n 2\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.firstrest-Tuple{Any}","page":"API Reference","title":"IterTools.firstrest","text":"firstrest(xs) -> (f, r)\n\nReturn the first element and an iterator of the rest as a tuple.\n\nSee also: Base.Iterators.peel.\n\njulia> f, r = firstrest(1:3);\n\njulia> f\n1\n\njulia> collect(r)\n2-element Vector{Int64}:\n 2\n 3\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.flagfirst-Tuple{Any}","page":"API Reference","title":"IterTools.flagfirst","text":"flagfirst(iter)\n\nAn iterator that yields (isfirst, x) where isfirst::Bool is true for the first element, and false after that, while the xs are elements from iter.\n\njulia> collect(flagfirst(1:3))\n3-element Vector{Tuple{Bool, Int64}}:\n (1, 1)\n (0, 2)\n (0, 3)\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.groupby-Union{Tuple{I}, Tuple{F}, Tuple{F, I}} where {F<:Union{Function, Type}, I}","page":"API Reference","title":"IterTools.groupby","text":"groupby(f, xs)\n\nGroup consecutive values that share the same result of applying f.\n\njulia> for i in groupby(x -> x[1], [\"face\", \"foo\", \"bar\", \"book\", \"baz\", \"zzz\"])\n           @show i\n       end\ni = [\"face\", \"foo\"]\ni = [\"bar\", \"book\", \"baz\"]\ni = [\"zzz\"]\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.imap-Tuple{Any, Any, Vararg{Any}}","page":"API Reference","title":"IterTools.imap","text":"imap(f, xs1, [xs2, ...])\n\nIterate over values of a function applied to successive values from one or more iterators. Like Iterators.zip, the iterator is done when any of the input iterators have been exhausted.\n\njulia> for i in imap(+, [1,2,3], [4,5,6])\n            @show i\n       end\ni = 5\ni = 7\ni = 9\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.interleaveby","page":"API Reference","title":"IterTools.interleaveby","text":"interleaveby(predicate=Base.isless, a, b)\n\nIterate over the an interleaving of a and b selected by the predicate (default less-than).\n\nInput:\n\npredicate(ak,bk) -> Bool:  Whether to pick the next element of a (true) or b (false).\nfa(ak), fb(bk): Functions to apply to the picked elements\n\njulia> collect(interleaveby(1:2:5, 2:2:6))\n6-element Vector{Int64}:\n 1\n 2\n 3\n 4\n 5\n 6\n\nIf the predicate is Base.isless (the default) and both inputs are sorted, this produces the sorted output. If the predicate is a stateful functor that alternates true-false-true-false... then this produces the classic interleave operation as described e.g. in the definition of microkanren.\n\n\n\n\n\n","category":"function"},{"location":"reference/#IterTools.iterated-Tuple{Any, Any}","page":"API Reference","title":"IterTools.iterated","text":"iterated(f, x)\n\nIterate over successive applications of f, as in x, f(x), f(f(x)), f(f(f(x))), ...\n\nUse Base.Iterators.take() to obtain the required number of elements.\n\njulia> for i in Iterators.take(iterated(x -> 2x, 1), 5)\n           @show i\n       end\ni = 1\ni = 2\ni = 4\ni = 8\ni = 16\n\njulia> for i in Iterators.take(iterated(sqrt, 100), 6)\n           @show i\n       end\ni = 100\ni = 10.0\ni = 3.1622776601683795\ni = 1.7782794100389228\ni = 1.333521432163324\ni = 1.1547819846894583\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.ivec-Tuple{Any}","page":"API Reference","title":"IterTools.ivec","text":"ivec(iter)\n\nDrops all shape from iter while iterating. Like a non-materializing version of vec.\n\njulia> m = collect(reshape(1:6, 2, 3))\n2×3 Matrix{Int64}:\n 1  3  5\n 2  4  6\n\njulia> collect(ivec(m))\n6-element Vector{Int64}:\n 1\n 2\n 3\n 4\n 5\n 6\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.ncycle-Tuple{Any, Int64}","page":"API Reference","title":"IterTools.ncycle","text":"ncycle(iter, n)\n\nCycle through iter n times.\n\njulia> for i in ncycle(1:3, 2)\n           @show i\n       end\ni = 1\ni = 2\ni = 3\ni = 1\ni = 2\ni = 3\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.nth-Tuple{Any, Integer}","page":"API Reference","title":"IterTools.nth","text":"nth(xs, n)\n\nReturn the nth element of xs. This is mostly useful for non-indexable collections.\n\njulia> powers_of_two = iterated(x->2x,1);\n\njulia> nth(powers_of_two, 4)\n8\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.partition-Tuple{Any, Int64}","page":"API Reference","title":"IterTools.partition","text":"partition(xs, n, [step])\n\nGroup values into n-tuples.\n\njulia> for i in partition(1:9, 3)\n           @show i\n       end\ni = (1, 2, 3)\ni = (4, 5, 6)\ni = (7, 8, 9)\n\nIf the step parameter is set, each tuple is separated by step values.\n\njulia> for i in partition(1:9, 3, 2)\n           @show i\n       end\ni = (1, 2, 3)\ni = (3, 4, 5)\ni = (5, 6, 7)\ni = (7, 8, 9)\n\njulia> for i in partition(1:9, 3, 3)\n           @show i\n       end\ni = (1, 2, 3)\ni = (4, 5, 6)\ni = (7, 8, 9)\n\njulia> for i in partition(1:9, 2, 3)\n           @show i\n       end\ni = (1, 2)\ni = (4, 5)\ni = (7, 8)\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.peekiter-Tuple{Any}","page":"API Reference","title":"IterTools.peekiter","text":"peekiter(xs)\n\nLets you peek at the head element of an iterator without updating the state.\n\njulia> it = peekiter([\"face\", \"foo\", \"bar\", \"book\", \"baz\", \"zzz\"]);\n\njulia> peek(it)\nSome(\"face\")\n\njulia> peek(it)\nSome(\"face\")\n\njulia> x, s = iterate(it)\n(\"face\", (\"foo\", 3))\n\njulia> x\n\"face\"\n\njulia> peek(it, s)\nSome(\"foo\")\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.properties-Tuple{T} where T","page":"API Reference","title":"IterTools.properties","text":"properties(x)\n\nIterate through the names and value of the properties of x.\n\njulia> collect(properties(1 + 2im))\n2-element Vector{Any}:\n (:re, 1)\n (:im, 2)\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.propertyvalues-Tuple{T} where T","page":"API Reference","title":"IterTools.propertyvalues","text":"propertyvalues(x)\n\nIterate through the values of the properties of x.\n\njulia> collect(propertyvalues(1 + 2im))\n2-element Vector{Any}:\n 1\n 2\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.repeatedly-Tuple{Any, Any}","page":"API Reference","title":"IterTools.repeatedly","text":"repeatedly(f)\nrepeatedly(f, n)\n\nCall function f n times, or infinitely if n is omitted.\n\njulia> t() = (sleep(0.1); Dates.millisecond(now()))\nt (generic function with 1 method)\n\njulia> collect(repeatedly(t, 5))\n5-element Vector{Any}:\n 993\n  97\n 200\n 303\n 408\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.subsets-Tuple{Any}","page":"API Reference","title":"IterTools.subsets","text":"subsets(xs)\nsubsets(xs, k)\nsubsets(xs, Val{k}())\n\nIterate over every subset of the indexable collection xs. You can restrict the subsets to a specific size k.\n\nGiving the subset size in the form Val{k}() allows the compiler to produce code optimized for the particular size requested. This leads to performance comparable to hand-written loops if k is small and known at compile time, but may or may not improve performance otherwise.\n\njulia> for i in subsets([1, 2, 3])\n          @show i\n       end\ni = Int64[]\ni = [1]\ni = [2]\ni = [1, 2]\ni = [3]\ni = [1, 3]\ni = [2, 3]\ni = [1, 2, 3]\n\njulia> for i in subsets(1:4, 2)\n          @show i\n       end\ni = [1, 2]\ni = [1, 3]\ni = [1, 4]\ni = [2, 3]\ni = [2, 4]\ni = [3, 4]\n\njulia> for i in subsets(1:4, Val{2}())\n           @show i\n       end\ni = (1, 2)\ni = (1, 3)\ni = (1, 4)\ni = (2, 3)\ni = (2, 4)\ni = (3, 4)\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.takenth-Tuple{Any, Integer}","page":"API Reference","title":"IterTools.takenth","text":"takenth(xs, n)\n\nIterate through every nth element of xs.\n\njulia> collect(takenth(5:15,3))\n3-element Vector{Int64}:\n  7\n 10\n 13\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.takestrict-Tuple{Any, Int64}","page":"API Reference","title":"IterTools.takestrict","text":"takestrict(xs, n::Int)\n\nLike take(), an iterator that generates at most the first n elements of xs, but throws an exception if fewer than n items are encountered in xs.\n\njulia> collect(takestrict(1:2:11, 3))\n3-element Vector{Int64}:\n 1\n 3\n 5\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.takewhile-Tuple{Any, Any}","page":"API Reference","title":"IterTools.takewhile","text":"takewhile(cond, xs)\n\nAn iterator that yields values from the iterator xs as long as the predicate cond is true.\n\njulia> collect(takewhile(x-> x^2 < 10, 1:100))\n3-element Vector{Int64}:\n 1\n 2\n 3\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.zip_longest-Tuple","page":"API Reference","title":"IterTools.zip_longest","text":"zip_longest(iters...; default=nothing)\n\nFor one or more iterable objects, return an iterable of tuples, where the ith tuple contains the ith component of each input iterable if it is not finished, and default otherwise. default can be a scalar, or a tuple with one default per iterable.\n\njulia> for t in zip_longest(1:2, 5:8)\n         @show t\n       end\nt = (1, 5)\nt = (2, 6)\nt = (nothing, 7)\nt = (nothing, 8)\n\njulia> for t in zip_longest('a':'e', ['m', 'n']; default='x')\n         @show t\n       end\nt = ('a', 'm')\nt = ('b', 'n')\nt = ('c', 'x')\nt = ('d', 'x')\nt = ('e', 'x')\n\n\n\n\n\n","category":"method"},{"location":"reference/#IterTools.@ifsomething-Tuple{Any}","page":"API Reference","title":"IterTools.@ifsomething","text":"IterTools.@ifsomething expr\n\nIf expr evaluates to nothing, equivalent to return nothing, otherwise the macro evaluates to the value of expr. Not exported, useful for implementing iterators.\n\njulia> IterTools.@ifsomething iterate(1:2)\n(1, 1)\n\njulia> let elt, state = IterTools.@ifsomething iterate(1:2, 2); println(\"not reached\"); end\n\n\n\n\n\n","category":"macro"},{"location":"#IterTools","page":"Home","title":"IterTools","text":"","category":"section"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Install this package with Pkg.add(\"IterTools\")","category":"page"},{"location":"#Index","page":"Home","title":"Index","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Modules = [IterTools]","category":"page"}]
}
