StructEquality
==============

load like
```julia
using StructEquality
```
which gives you access to one macro `@def_structequal`.

Struct types have an `==` implementation by default which uses `===`, i.e. object identity, on the underlying
components to compare structs.

Let's define a struct
```julia
struct MyStruct
  a::Int
  b::Vector
end
```

The default `==` fails to compare two structs with the same content
```julia
MyStruct(1, [2,3]) == MyStruct(1, [2,3])  # false
```

To fix this use the supplied macro `@def_structequal`
```julia
@def_structequal MyStruct
MyStruct(1, [2,3]) == MyStruct(1, [2,3])  # true
```

Alternatively you can use the macro right on struct definition

```julia
@def_structequal struct MyStruct2
  a::Int
  b::Vector
end
MyStruct2(1, [2,3]) == MyStruct2(1, [2,3])  # true
```

Implementation
--------------

It is like you would expect. the macro extracts the field names and defines `==` by referring to `==` comparison
of the fields.

```julia
@macroexpand @def_structequal MyStruct
```
```julia
:(function Base.:(==)(s1::MyStruct, s2::MyStruct)
      s1.a == s2.a && s1.b == s2.b
  end)
```

References
----------

For more details to this topic, please see the discouse thread
https://discourse.julialang.org/t/surprising-struct-equality-test/4890/9
