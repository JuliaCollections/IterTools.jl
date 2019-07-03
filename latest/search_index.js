var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": "DocTestSetup = quote\n    using IterTools\nend"
},

{
    "location": "index.html#IterTools-1",
    "page": "Introduction",
    "title": "IterTools",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#Installation-1",
    "page": "Introduction",
    "title": "Installation",
    "category": "section",
    "text": "Install this package with Pkg.add(\"IterTools\")"
},

{
    "location": "index.html#Usage-1",
    "page": "Introduction",
    "title": "Usage",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#IterTools.distinct",
    "page": "Introduction",
    "title": "IterTools.distinct",
    "category": "function",
    "text": "distinct(xs)\n\nIterate through values skipping over those already encountered.\n\njulia> for i in distinct([1,1,2,1,2,4,1,2,3,4])\n           @show i\n       end\ni = 1\ni = 2\ni = 4\ni = 3\n\n\n\n\n\n"
},

{
    "location": "index.html#distinct(xs)-1",
    "page": "Introduction",
    "title": "distinct(xs)",
    "category": "section",
    "text": "Iterate through values skipping over those already encountered.distinct"
},

{
    "location": "index.html#IterTools.groupby",
    "page": "Introduction",
    "title": "IterTools.groupby",
    "category": "function",
    "text": "groupby(f, xs)\n\nGroup consecutive values that share the same result of applying f.\n\njulia> for i in groupby(x -> x[1], [\"face\", \"foo\", \"bar\", \"book\", \"baz\", \"zzz\"])\n           @show i\n       end\ni = [\"face\", \"foo\"]\ni = [\"bar\", \"book\", \"baz\"]\ni = [\"zzz\"]\n\n\n\n\n\n"
},

{
    "location": "index.html#groupby(f,-xs)-1",
    "page": "Introduction",
    "title": "groupby(f, xs)",
    "category": "section",
    "text": "Group consecutive values that share the same result of applying f.groupby"
},

{
    "location": "index.html#IterTools.imap",
    "page": "Introduction",
    "title": "IterTools.imap",
    "category": "function",
    "text": "imap(f, xs1, [xs2, ...])\n\nIterate over values of a function applied to successive values from one or more iterators. Like Iterators.zip, the iterator is done when any of the input iterators have been exhausted.\n\njulia> for i in imap(+, [1,2,3], [4,5,6])\n            @show i\n       end\ni = 5\ni = 7\ni = 9\n\n\n\n\n\n"
},

{
    "location": "index.html#imap(f,-xs1,-[xs2,-...])-1",
    "page": "Introduction",
    "title": "imap(f, xs1, [xs2, ...])",
    "category": "section",
    "text": "Iterate over values of a function applied to successive values from one or more iterators.imap"
},

{
    "location": "index.html#IterTools.iterated",
    "page": "Introduction",
    "title": "IterTools.iterated",
    "category": "function",
    "text": "iterated(f, x)\n\nIterate over successive applications of f, as in x, f(x), f(f(x)), f(f(f(x))), ...\n\nUse Base.Iterators.take() to obtain the required number of elements.\n\njulia> for i in Iterators.take(iterated(x -> 2x, 1), 5)\n           @show i\n       end\ni = 1\ni = 2\ni = 4\ni = 8\ni = 16\n\njulia> for i in Iterators.take(iterated(sqrt, 100), 6)\n           @show i\n       end\ni = 100\ni = 10.0\ni = 3.1622776601683795\ni = 1.7782794100389228\ni = 1.333521432163324\ni = 1.1547819846894583\n\n\n\n\n\n"
},

{
    "location": "index.html#iterated(f,-x)-1",
    "page": "Introduction",
    "title": "iterated(f, x)",
    "category": "section",
    "text": "Iterate over successive applications of f, as in x, f(x), f(f(x)), f(f(f(x))), ....iterated"
},

{
    "location": "index.html#IterTools.ncycle",
    "page": "Introduction",
    "title": "IterTools.ncycle",
    "category": "function",
    "text": "ncycle(iter, n)\n\nCycle through iter n times.\n\njulia> for i in ncycle(1:3, 2)\n           @show i\n       end\ni = 1\ni = 2\ni = 3\ni = 1\ni = 2\ni = 3\n\n\n\n\n\n"
},

{
    "location": "index.html#ncycle(xs,-n)-1",
    "page": "Introduction",
    "title": "ncycle(xs, n)",
    "category": "section",
    "text": "Cycles through an iterator n times.ncycle"
},

{
    "location": "index.html#IterTools.nth",
    "page": "Introduction",
    "title": "IterTools.nth",
    "category": "function",
    "text": "nth(xs, n)\n\nReturn the nth element of xs. This is mostly useful for non-indexable collections.\n\njulia> mersenne = Set([3, 7, 31, 127])\nSet([7, 31, 3, 127])\n\njulia> nth(mersenne, 3)\n3\n\n\n\n\n\n"
},

{
    "location": "index.html#nth(xs,-n)-1",
    "page": "Introduction",
    "title": "nth(xs, n)",
    "category": "section",
    "text": "Return the nth element of xs.nth"
},

{
    "location": "index.html#IterTools.partition",
    "page": "Introduction",
    "title": "IterTools.partition",
    "category": "function",
    "text": "partition(xs, n, [step])\n\nGroup values into n-tuples.\n\njulia> for i in partition(1:9, 3)\n           @show i\n       end\ni = (1, 2, 3)\ni = (4, 5, 6)\ni = (7, 8, 9)\n\nIf the step parameter is set, each tuple is separated by step values.\n\njulia> for i in partition(1:9, 3, 2)\n           @show i\n       end\ni = (1, 2, 3)\ni = (3, 4, 5)\ni = (5, 6, 7)\ni = (7, 8, 9)\n\njulia> for i in partition(1:9, 3, 3)\n           @show i\n       end\ni = (1, 2, 3)\ni = (4, 5, 6)\ni = (7, 8, 9)\n\njulia> for i in partition(1:9, 2, 3)\n           @show i\n       end\ni = (1, 2)\ni = (4, 5)\ni = (7, 8)\n\n\n\n\n\n"
},

{
    "location": "index.html#partition(xs,-n,-[step])-1",
    "page": "Introduction",
    "title": "partition(xs, n, [step])",
    "category": "section",
    "text": "Group values into n-tuples.partition"
},

{
    "location": "index.html#IterTools.ivec",
    "page": "Introduction",
    "title": "IterTools.ivec",
    "category": "function",
    "text": "ivec(iter)\n\nDrops all shape from iter while iterating. Like a non-materializing version of vec.\n\njulia> m = collect(reshape(1:6, 2, 3))\n2×3 Array{Int64,2}:\n 1  3  5\n 2  4  6\n\njulia> collect(ivec(m))\n6-element Array{Int64,1}:\n 1\n 2\n 3\n 4\n 5\n 6\n\n\n\n\n\n"
},

{
    "location": "index.html#ivec(xs)-1",
    "page": "Introduction",
    "title": "ivec(xs)",
    "category": "section",
    "text": "Iterate over xs but do not preserve shape information.ivec"
},

{
    "location": "index.html#IterTools.peekiter",
    "page": "Introduction",
    "title": "IterTools.peekiter",
    "category": "function",
    "text": "peekiter(xs)\n\nLets you peek at the head element of an iterator without updating the state.\n\njulia> it = peekiter([\"face\", \"foo\", \"bar\", \"book\", \"baz\", \"zzz\"])\nIterTools.PeekIter{Array{String,1}}([\"face\", \"foo\", \"bar\", \"book\", \"baz\", \"zzz\"])\n\njulia> @show peek(it);\npeek(it) = Some(\"face\")\n\njulia> @show peek(it);\npeek(it) = Some(\"face\")\n\njulia> x, s = iterate(it)\n(\"face\", (\"foo\", 3))\n\njulia> @show x;\nx = \"face\"\n\njulia> @show peek(it, s);\npeek(it, s) = Some(\"foo\")\n\n\n\n\n\n"
},

{
    "location": "index.html#peekiter(xs)-1",
    "page": "Introduction",
    "title": "peekiter(xs)",
    "category": "section",
    "text": "Peek at the head element of an iterator without updating the state.peekiter"
},

{
    "location": "index.html#IterTools.repeatedly",
    "page": "Introduction",
    "title": "IterTools.repeatedly",
    "category": "function",
    "text": "repeatedly(f)\nrepeatedly(f, n)\n\nCall function f n times, or infinitely if n is omitted.\n\njulia> t() = (sleep(0.1); Dates.millisecond(now()))\nt (generic function with 1 method)\n\njulia> collect(repeatedly(t, 5))\n5-element Array{Any,1}:\n 993\n  97\n 200\n 303\n 408\n\n\n\n\n\n"
},

{
    "location": "index.html#repeatedly(f,-[n])-1",
    "page": "Introduction",
    "title": "repeatedly(f, [n])",
    "category": "section",
    "text": "Call a function n times, or infinitely if n is omitted.repeatedly"
},

{
    "location": "index.html#IterTools.takenth",
    "page": "Introduction",
    "title": "IterTools.takenth",
    "category": "function",
    "text": "takenth(xs, n)\n\nIterate through every nth element of xs.\n\njulia> collect(takenth(5:15,3))\n3-element Array{Int64,1}:\n  7\n 10\n 13\n\n\n\n\n\n"
},

{
    "location": "index.html#takenth(xs,-n)-1",
    "page": "Introduction",
    "title": "takenth(xs, n)",
    "category": "section",
    "text": "Iterate through every n\'th element of xstakenth"
},

{
    "location": "index.html#IterTools.subsets",
    "page": "Introduction",
    "title": "IterTools.subsets",
    "category": "function",
    "text": "subsets(xs)\nsubsets(xs, k)\nsubsets(xs, Val{k}())\n\nIterate over every subset of the indexable collection xs. You can restrict the subsets to a specific size k.\n\nGiving the subset size in the form Val{k}() allows the compiler to produce code optimized for the particular size requested. This leads to performance comparable to hand-written loops if k is small and known at compile time, but may or may not improve performance otherwise.\n\njulia> for i in subsets([1, 2, 3])\n          @show i\n       end\ni = Int64[]\ni = [1]\ni = [2]\ni = [1, 2]\ni = [3]\ni = [1, 3]\ni = [2, 3]\ni = [1, 2, 3]\n\njulia> for i in subsets(1:4, 2)\n          @show i\n       end\ni = [1, 2]\ni = [1, 3]\ni = [1, 4]\ni = [2, 3]\ni = [2, 4]\ni = [3, 4]\n\njulia> for i in subsets(1:4, Val{2}())\n           @show i\n       end\ni = (1, 2)\ni = (1, 3)\ni = (1, 4)\ni = (2, 3)\ni = (2, 4)\ni = (3, 4)\n\n\n\n\n\n"
},

{
    "location": "index.html#subsets(xs,-[k])-1",
    "page": "Introduction",
    "title": "subsets(xs, [k])",
    "category": "section",
    "text": "Iterate over every subset of an indexable collection xs, or iterate over every subset of size k from an indexable collection xs.subsets"
},

{
    "location": "index.html#IterTools.takestrict",
    "page": "Introduction",
    "title": "IterTools.takestrict",
    "category": "function",
    "text": "takestrict(xs, n::Int)\n\nLike take(), an iterator that generates at most the first n elements of xs, but throws an exception if fewer than n items are encountered in xs.\n\njulia> a = :1:2:11\n1:2:11\n\njulia> collect(takestrict(a, 3))\n3-element Array{Int64,1}:\n 1\n 3\n 5\n\n\n\n\n\n"
},

{
    "location": "index.html#takestrict(xs,-n)-1",
    "page": "Introduction",
    "title": "takestrict(xs, n)",
    "category": "section",
    "text": "Equivalent to take, but will throw an exception if fewer than n items are encountered in xs.takestrict"
},

{
    "location": "index.html#IterTools.takewhile",
    "page": "Introduction",
    "title": "IterTools.takewhile",
    "category": "function",
    "text": "takewhile(cond, xs)\n\nAn iterator that yields values from the iterator xs as long as the predicate cond is true.\n\njulia> collect(takewhile(x-> x^2 < 10, 1:100))\n3-element Array{Int64,1}:\n 1\n 2\n 3\n\n\n\n\n\n"
},

{
    "location": "index.html#takewhile(cond,-xs)-1",
    "page": "Introduction",
    "title": "takewhile(cond, xs)",
    "category": "section",
    "text": "Iterates through values from the iterable xs as long as a given predicate cond is true.takewhile"
},

{
    "location": "index.html#IterTools.flagfirst",
    "page": "Introduction",
    "title": "IterTools.flagfirst",
    "category": "function",
    "text": "flagfirst(iter)\n\nAn iterator that yields (isfirst, x) where isfirst::Bool is true for the first element, and false after that, while the xs are elements from iter.\n\njulia> collect(flagfirst(1:3))\n3-element Array{Tuple{Bool,Int64},1}:\n (true, 1)\n (false, 2)\n (false, 3)\n\n\n\n\n\n"
},

{
    "location": "index.html#flagfirst(xs)-1",
    "page": "Introduction",
    "title": "flagfirst(xs)",
    "category": "section",
    "text": "Provide a flag to check if this is the first element.flagfirst"
},

{
    "location": "index.html#IterTools.@ifsomething",
    "page": "Introduction",
    "title": "IterTools.@ifsomething",
    "category": "macro",
    "text": "IterTools.@ifsomething expr\n\nIf expr evaluates to nothing, equivalent to return nothing, otherwise the macro evaluates to the value of expr. Not exported, useful for implementing iterators.\n\njulia> IterTools.@ifsomething iterate(1:2)\n(1, 1)\n\njulia> let elt, state = IterTools.@ifsomething iterate(1:2, 2); println(\"not reached\"); end\n\n\n\n\n\n"
},

{
    "location": "index.html#IterTools.@ifsomething-1",
    "page": "Introduction",
    "title": "IterTools.@ifsomething",
    "category": "section",
    "text": "Helper macro for returning from the enclosing block when there are no more elements.IterTools.@ifsomething"
},

{
    "location": "index.html#IterTools.properties",
    "page": "Introduction",
    "title": "IterTools.properties",
    "category": "function",
    "text": "properties(x)\n\nIterate through the names and value of the properties of x.\n\njulia> collect(properties(1 + 2im))\n2-element Array{Any,1}:\n (:re, 1)\n (:im, 2)\n\n\n\n\n\n"
},

{
    "location": "index.html#properties(x)-1",
    "page": "Introduction",
    "title": "properties(x)",
    "category": "section",
    "text": "Iterate over struct or named tuple properties.properties"
},

{
    "location": "index.html#IterTools.propertyvalues",
    "page": "Introduction",
    "title": "IterTools.propertyvalues",
    "category": "function",
    "text": "propertyvalues(x)\n\nIterate through the values of the properties of x.\n\njulia> collect(propertyvalues(1 + 2im))\n2-element Array{Any,1}:\n 1\n 2\n\n\n\n\n\n"
},

{
    "location": "index.html#propertyvalues(x)-1",
    "page": "Introduction",
    "title": "propertyvalues(x)",
    "category": "section",
    "text": "Iterate over struct or named tuple property values.propertyvalues"
},

{
    "location": "functionindex.html#",
    "page": "Function index",
    "title": "Function index",
    "category": "page",
    "text": ""
},

{
    "location": "functionindex.html#Index-1",
    "page": "Function index",
    "title": "Index",
    "category": "section",
    "text": ""
},

]}
