using StructEquality
using Test

include("testutils.jl")

@testset "def_structequal" begin
  include("def_structequal.jl")
end

# Structs
# =======
begin
  function create_structs_1(name)
    quote
      struct $name
        a
        b
      end
      a = $name(1, [2,3])
      b = $name(1, [2,3])
      a, b
    end
  end
  function create_structs_2(name)
    quote
      struct $name
        a
        b::Vector
      end
      a = $name(1, [2,3])
      b = $name(1, [2,3])
      a, b
    end
  end

  function create_structs_3(name)
    quote
      struct $name
        a::Int
        b
      end
      a = $name(1, [2,3])
      b = $name(1, [2,3])
      a, b
    end
  end

  function create_structs_4(name)
    quote
      Base.@kwdef mutable struct $name{T} <: Number
        a = 1
        b::Vector = [2,3]
      end
      a = $name{Int}(a = 1)
      b = $name{Int}(a = 1)
      a, b
    end
  end

  function create_structs_5(name)
    quote
      mutable struct $name
        a
        b
      end
      a = $name(1, [2,3])
      b = $name(1, [2,3])
      a, b
    end
  end

  function create_structs_6(name)
    quote
      struct $name
        a
        b
        $name(a, b) = new(a, b)
        function $name(a, b, c)
          new(a, b)
        end
      end
      a = $name(1, [2,3])
      b = $name(1, [2,3])
      a, b
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
      name = gensym(repr(create_structs))
      a, b = eval(insert_macro_before_struct!(create_structs(name), macroname))
      @test test_with(a, b)
    end
  end

end


# Test macro after struct
# =======================

begin
  function test_equal(name, a, b)
    quote
      @test $a != $b
      @struct_equal $name
      @test $a == $b
    end
  end


  function test_isequal(name, a, b)
    quote
      @test !isequal($a, $b)
      @struct_isequal $name
      @test isequal($a, $b)
    end
  end

  function test_hash(name, a, b)
    quote
      @test hash($a) != hash($b)
      @struct_hash $name
      @test hash($a) == hash($b)
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
      name = gensym(repr(create_structs))
      a, b = eval(create_structs(name))
      eval(test_without(name, a, b))
    end
  end
end


# Test submodules
# ...............

@testset "macro-after-struct-submodule" begin

  function create_submodule_mystruct(name)
    quote
      @eval module $name
        struct MyStruct
          a
          b
        end
      end
      import .$name
      a = $name.MyStruct(1, [2])
      b = $name.MyStruct(1, [2])
      a, b
    end
  end

  for test_without in tests_without
    @testset "submodule_struct-$(repr(test_without))" begin
      create_submodule_mystruct
      name = gensym(repr(create_submodule_mystruct))
      a, b = eval(create_submodule_mystruct(name))
      eval(test_without(:($name.MyStruct), a, b))
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

end
