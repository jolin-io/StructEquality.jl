using StructEquality
using Test

struct MyStruct1
  a
  b
end

# default implementation does  not use == for all attributes, but ===
@test MyStruct1(1, [2,3]) != MyStruct1(1, [2,3])
eval(def_structequal(:MyStruct1, [:a, :b]))
@test MyStruct1(1, [2,3]) == MyStruct1(1, [2,3])


"""
MyStruct2
"""
@def_structequal  struct MyStruct2
  a
  b::Vector
end
@test MyStruct2(1, [2,3]) == MyStruct2(1, [2,3])


"""
MyStruct3
"""
struct MyStruct3
  a::Int
  b
end
@test MyStruct3(1, [2,3]) != MyStruct3(1, [2,3])
@def_structequal MyStruct3
@test MyStruct3(1, [2,3]) == MyStruct3(1, [2,3])


# NOTE when combine with Base.@kwdef, make @def_structequal the most outer macro
"""
MyStruct4
"""
@def_structequal Base.@kwdef mutable struct MyStruct4{T} <: Number
  a = 1
  b::Vector = [2,3]
end
@test MyStruct4{Int}(a = 1) == MyStruct4{Int}(a = 1)


# make sure mutable struct does not behave differently
mutable struct MyStruct5
  a
  b
end
@test MyStruct5(1, [2,3]) != MyStruct5(1, [2,3])
@def_structequal MyStruct5
@test MyStruct5(1, [2,3]) == MyStruct5(1, [2,3])


# deal with constructors
struct MyStruct6
  a
  b
  MyStruct6(a, b) = new(a, b)
  function MyStruct6(a, b, c)
    new(a, b)
  end
end
@test MyStruct6(1, [2,3]) != MyStruct6(1, [2,3])
@def_structequal MyStruct6
@test MyStruct6(1, [2,3]) == MyStruct6(1, [2,3])


# test submodules
module MySubModule
  struct MyStruct7
    a
    b
  end
end
import .MySubModule

@test MySubModule.MyStruct7(1, [2,3]) != MySubModule.MyStruct7(1, [2,3])
@def_structequal MySubModule.MyStruct7
@test MySubModule.MyStruct7(1, [2,3]) == MySubModule.MyStruct7(1, [2,3])
