StructEquality
==============

[![Build Status](https://github.com/jolin-io/StructEquality.jl/workflows/CI/badge.svg)](https://github.com/jolin-io/StructEquality.jl/actions)
[![Coverage](https://codecov.io/gh/jolin-io/StructEquality.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jolin-io/StructEquality.jl)

install like
```julia
using Pkg
pkg"add StructEquality"
```

load like
```julia
using StructEquality
```

which let's you easily define `hash` and `==` for your custom struct. 
```julia
@struct_hash_equal struct MyStruct
  one
  two
end

MyStruct("1", [2]) == MyStruct("1", [2])  # true
```

API Overview
------------

| macro | defines ... for your struct |
| ----- | --------------------------- |
| `@struct_hash` | `hash` |
| `@struct_equal` | `==` |
| `@struct_isequal` | `isequal` |
| `@struct_isapprox` | `isapprox` |

| combined macro | defines ... for your struct |
| ----- | --------------------------- |
| `@struct_hash_equal` | `hash`, `==` |
| `@struct_hash_equal_isapprox` | `hash`, `==`, `isapprox` |
| `@struct_hash_equal_isequal` | `hash`, `==`, `isequal` |
| `@struct_hash_equal_isequal_isapprox` | `hash`, `==`, `isequal`, `isapprox` |

If you don't like macros, you can directly use the underlying generated functions and implement the definitions yourself.

| generated functions | use for custom implementation like ... |
| ------------------- | -------------------------------------- |
| `struct_hash` | `Base.hash(a::YourStructType, h::UInt) = struct_hash(a, h)` |
| `struct_equal` | `Base.:(==)(a::YourStructType, b::YourStructType) = struct_equal(a, b)` |
| `struct_isequal` | `Base.isequal(a::YourStructType, b::YourStructType) = struct_isequal(a, b)` |
| `struct_isapprox` | `Base.isapprox(a::YourStructType, b::YourStructType; kwargs...) = struct_isapprox(a, b; kwargs...)` |


Motivation & Usage
------------------

Struct types have an `==` implementation by default which uses `===`, i.e. object identity, on the underlying components, in order to compare structs. (The same holds true for `hash`, which should always follow the implementation of `==`)

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

To fix this use the supplied macro `@struct_hash_equal`
```julia
@struct_hash_equal MyStruct
MyStruct(1, [2,3]) == MyStruct(1, [2,3])  # true
```

Alternatively you can use the macro right on struct definition

```julia
@struct_hash_equal struct MyStruct2
  a::Int
  b::Vector
end
MyStruct2(1, [2,3]) == MyStruct2(1, [2,3])  # true
```

You could also merely use `@struct_equal` instead of `@struct_hash_equal`, however it is recommended to always implement `hash` and `==` together.

Implementation
--------------

The implementation uses generated functions, which generate optimal code, specified to your custom struct type.

Inspecting the macro with
```julia
@macroexpand @struct_hash_equal MyStruct
```
returns the following
```julia
quote
    Base.hash(a::MyStruct, h::UInt) = begin
        StructEquality.struct_hash(a, h)
    end
    Base.:(==)(a::MyStruct, b::MyStruct) = begin
        StructEquality.struct_equal(a, b)
    end
end
```

In order to inspect generated functions, the `@code_lowered` macro is best.
```julia
struct MyStruct
  a::Int
  b::Vector
end

@code_lowered struct_equal(MyStruct(1, [2,3]), MyStruct(1, [2,3]))
```
which returns
```julia
    @ /path/to/StructEquality/src/StructEquality.jl:15 within `struct_equal`
   ┌ @ /path/to/StructEquality/src/StructEquality.jl within `macro expansion`
1 ─│ %1 = Base.getproperty(e1, :a)
│  │ %2 = Base.getproperty(e2, :a)
│  │ %3 = %1 == %2
└──│      goto #3 if not %3
2 ─│ %5 = Base.getproperty(e1, :b)
│  │ %6 = Base.getproperty(e2, :b)
│  │ %7 = %5 == %6
└──│      return %7
3 ─│      return false
   └
)
```


It is like you would expect. the generated function extracts the field names and defines `==` by referring to `==` comparison of the fields.


References
----------

For more details to this topic, please see this discourse thread
https://discourse.julialang.org/t/surprising-struct-equality-test/4890/9 and this issue https://github.com/JuliaLang/julia/issues/4648
