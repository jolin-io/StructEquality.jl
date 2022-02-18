
struct DefMyStruct1
    a
    b
end

# default implementation does  not use == for all attributes, but ===
@test DefMyStruct1(1, [2,3]) != DefMyStruct1(1, [2,3])
@def_structequal DefMyStruct1
@test DefMyStruct1(1, [2,3]) == DefMyStruct1(1, [2,3])


"""
DefMyStruct2
"""
@def_structequal struct DefMyStruct2
    a
    b::Vector
end
@test DefMyStruct2(1, [2,3]) == DefMyStruct2(1, [2,3])


"""
DefMyStruct3
"""
struct DefMyStruct3
    a::Int
    b
end
@test DefMyStruct3(1, [2,3]) != DefMyStruct3(1, [2,3])
@def_structequal DefMyStruct3
@test DefMyStruct3(1, [2,3]) == DefMyStruct3(1, [2,3])


# NOTE when combine with Base.@kwdef, make @def_structequal the most outer macro
"""
DefMyStruct4
"""
@def_structequal Base.@kwdef mutable struct DefMyStruct4{T} <: Number
    a = 1
    b::Vector = [2,3]
end
@test DefMyStruct4{Int}(a = 1) == DefMyStruct4{Int}(a = 1)


# make sure mutable struct does not behave differently
mutable struct DefMyStruct5
    a
    b
end
@test DefMyStruct5(1, [2,3]) != DefMyStruct5(1, [2,3])
@def_structequal DefMyStruct5
@test DefMyStruct5(1, [2,3]) == DefMyStruct5(1, [2,3])


# deal with constructors
struct DefMyStruct6
    a
    b
    DefMyStruct6(a, b) = new(a, b)
    function DefMyStruct6(a, b, c)
    new(a, b)
    end
end
@test DefMyStruct6(1, [2,3]) != DefMyStruct6(1, [2,3])
@def_structequal DefMyStruct6
@test DefMyStruct6(1, [2,3]) == DefMyStruct6(1, [2,3])


# test submodules
module MySubModule
    struct DefMyStruct7
    a
    b
    end
end
import .MySubModule

@test MySubModule.DefMyStruct7(1, [2,3]) != MySubModule.DefMyStruct7(1, [2,3])
@def_structequal MySubModule.DefMyStruct7
@test MySubModule.DefMyStruct7(1, [2,3]) == MySubModule.DefMyStruct7(1, [2,3])
