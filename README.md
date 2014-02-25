Common functional iterator patterns.

### product

Iterate over all combinations in the cartesian product of the inputs. For example,
```
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
