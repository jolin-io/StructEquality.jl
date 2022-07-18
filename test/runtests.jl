using StructEquality
using Test

include("testutils.jl")

@testset "def_structequal" begin
    include("def_structequal.jl")
end

# Structs
# =======
begin
    function create_structs_1(structname)
        quote
            struct $structname
                a
                b
            end
            a = $structname(1, [2,3])
            b = $structname(1, [2,3])
            true, a, b
        end
    end
    function create_structs_2(structname)
        quote
            struct $structname
                a
                b::Vector
            end
            a = $structname(1, [2,3])
            b = $structname(1, [2,3])
            true, a, b
        end
    end

    function create_structs_3(structname)
        quote
            struct $structname
                a::Int
                b
            end
            a = $structname(1, [2,3])
            b = $structname(1, [2,3])
            true, a, b
        end
    end

    function create_structs_4(structname)
        quote
            Base.@kwdef mutable struct $structname{T} <: Number
                a = 1
                b::Vector = [2,3]
            end
            a = $structname{Int}(a = 1)
            b = $structname{Int}(a = 1)
            true, a, b
        end
    end

    function create_structs_5(structname)
        quote
            mutable struct $structname
                a
                b
            end
            a = $structname(1, [2,3])
            b = $structname(1, [2,3])
            true, a, b
        end
    end

    function create_structs_6(structname)
        quote
            struct $structname
                a
                b
                $structname(a, b) = new(a, b)
                function $structname(a, b, c)
                    new(a, b)
                end
            end
            a = $structname(1, [2,3])
            b = $structname(1, [2,3])
            true, a, b
        end
    end

    function create_structs_7(structname)
        quote
            struct $structname{Element}
                a
                b::Vector{Element}
            end
            a = $structname{Int}(1, [2,3])
            b = $structname{Any}(1, [2,3])
            true, a, b
        end
    end

    function create_structs_8(structname)
        structname2 = Symbol(structname, 2)
        quote
            struct $structname{Element}
                a
                b::Vector{Element}
            end

            struct $structname2{Element}
                a
                b::Vector{Element}
            end
            a = $structname{Int}(1, [2,3])
            b = $structname2{Int}(1, [2,3])
            false, a, b
        end
    end
end

create_structs_funcs = [
    create_structs_1,
    create_structs_2,
    create_structs_3,
    create_structs_4,
    create_structs_5,
    create_structs_6,
    create_structs_7,
    create_structs_8,
]


# Test macro before struct
# ========================

@testset "macro-before-struct" begin
    
    tests_with = [
        Symbol("@struct_equal") => ==,
        Symbol("@struct_isequal") => isequal,
        Symbol("@struct_hash") => (a, b) -> hash(a) == hash(b),
    ]
    
    for (create_structs, (macroname, test_with)) in Iterators.product(create_structs_funcs, tests_with)
        @testset "$(repr(macroname))-$(repr(test_with))" begin
            structname = gensym(repr(create_structs))
            should_be_same, a, b = eval(insert_macro_before_struct!(create_structs(structname), macroname))
            @test test_with(a, b) == should_be_same
        end
    end

end


# Test macro after struct
# =======================

begin
    function test_equal(structname, should_be_same, a, b)
        quote
            @test $a != $b
            @struct_equal $structname
            @test ($a == $b) == $should_be_same
        end
    end


    function test_isequal(structname, should_be_same, a, b)
        quote
            @test !isequal($a, $b)
            @struct_isequal $structname
            @test isequal($a, $b) == $should_be_same
        end
    end

    function test_hash(structname, should_be_same, a, b)
        quote
            @test hash($a) != hash($b)
            @struct_hash $structname
            @test (hash($a) == hash($b)) == $should_be_same
        end
    end
end

tests_without = [
    test_equal,
    test_isequal,
    test_hash
]


@testset "macro-after-struct" begin
    for (create_structs, test_without) in Iterators.product(create_structs_funcs, tests_without)
        @testset "$(repr(create_structs))-$(repr(test_without))" begin
            structname = gensym(repr(create_structs))
            should_be_same, a, b = eval(create_structs(structname))
            eval(test_without(structname, should_be_same, a, b))
        end
    end
end


# Test submodules
# ...............

@testset "macro-after-struct-submodule" begin

    function create_submodule_mystruct(structname)
        quote
            @eval module $structname
                struct MyStruct
                    a
                    b
                end
            end
            import .$structname
            a = $structname.MyStruct(1, [2])
            b = $structname.MyStruct(1, [2])
            true, a, b
        end
    end

    for test_without in tests_without
        @testset "submodule_struct-$(repr(test_without))" begin
            create_submodule_mystruct
            structname = gensym(repr(create_submodule_mystruct))
            should_be_same, a, b = eval(create_submodule_mystruct(structname))
            eval(test_without(:($structname.MyStruct), should_be_same, a, b))
        end
    end

end


# Test isapprox
# =============

@testset "isapprox" begin

    struct StructIsApprox{T1, T2, T3}
        a::T1
        b::T2
        c::T3
    end

    f1 = StructIsApprox(1.0, 2.0, "hi")
    f2 = StructIsApprox(Float16(1.0), Float32(2.0), "hi")
    f3 = StructIsApprox(Float16(1.1), Float32(2.1), "hi")

    @test_throws MethodError isapprox(f1, f1)
    @test_throws MethodError isapprox(f1, f2)
    @test_throws MethodError isapprox(f1, f2, atol=0.2)

    @struct_isapprox StructIsApprox

    @test isapprox(f1, f1)
    @test isapprox(f1, f2)

    @test isapprox(f1, f3) == false

    @test isapprox(f1, f3, atol=0.2)
    @test isapprox(f1, f3, rtol=2)


    # extra testset created by matthijscox
    # ....................................
    @struct_isapprox Base.@kwdef struct Foo{T}
        name::String = "myfoo"
        value::T = 5.0
    end
    
    """
    docstring
    """
    @struct_isapprox Base.@kwdef struct Bar{T}
        name::String = "mybar"
        foo::Foo = Foo()
        value::T = 1.0
    end
    
    b = Bar()
    b2 = Bar()
    @test b ≈ b2
    
    b = Bar()
    b2 = Bar(value = 1.1)
    @test isapprox(b, b2, atol=0.11)
    @test isapprox(b, b2, rtol=0.11)
    
    b = Bar()
    b2 = Bar(value = 2.0)
    @test !(b ≈ b2)
    
    b = Bar()
    b2 = Bar(foo = Foo(value = -1.0))
    @test !(b ≈ b2)

    @test (Base.doc(Bar) |> string |> strip) == "docstring"

end
