# Iterators.jl

Common functional iterator patterns.

-----------

- **count**([start, [step]])

    Count, starting at ``start`` and incrementing by ``step``.  By default, ``start=0`` and ``step=1``.  For example:
    ```julia
    for i in take(count(5,5),5)
        @show i
    end
    ```
    yields
    ```
    i => 5
    i => 10
    i => 15
    i => 20
    i => 25
    ```

- **product**(xs...)

    Iterate over all combinations in the cartesian product of the inputs. For example,
    ```julia
    for p in product(1:3,1:2)
        @show p
    end
    ```
    yields
    ```
    p => (1,1)
    p => (2,1)
    p => (3,1)
    p => (1,2)
    p => (2,2)
    p => (3,2)
    ```

