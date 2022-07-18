module StructEquality
export struct_hash, struct_equal, struct_isequal, struct_isapprox
export @struct_hash, @struct_equal, @struct_isequal, @struct_isapprox
export @struct_hash_equal, @struct_hash_equal_isapprox
export @struct_hash_equal_isequal, @struct_hash_equal_isequal_isapprox
export @def_structequal

using Compat
include("utils.jl")

# Generator functions
# ===================

@generated struct_equal(e1::T1, e2::T2) where {T1, T2} = begin
  # check that they are of the same type, ignoring typevariables
  Base.typename(T1) === Base.typename(T2) || return false
  T = Base.typename(T1).wrapper
  # singleton structs need to be of the exact same type
  fieldcount(T1) > 0 || return T1 == T2
  
  # else compare field-wise
  eqfields = (:(e1.$field == e2.$field) for field in fieldnames(T))
  combine(expr, acc) = Expr(:&&, expr, acc)
  return foldr(combine, eqfields)
end


@generated struct_isequal(e1::T1, e2::T2) where {T1, T2} = begin
  # check that they are of the same type, ignoring typevariables
  Base.typename(T1) === Base.typename(T2) || return false
  T = Base.typename(T1).wrapper
  # singleton structs need to be of the exact same type
  fieldcount(T) > 0 || return T1 == T2
  
  # else compare field-wise
  eqfields = (:(isequal(e1.$field, e2.$field)) for field in fieldnames(T))
  combine(expr, acc) = Expr(:&&, expr, acc)
  return foldr(combine, eqfields)
end


@generated struct_isapprox(e1::T1, e2::T2; kwargs...) where {T1, T2} = begin
  # isapprox works accross different fieldtypes, but the struct wrapper type needs to be the same
  Base.typename(T1).wrapper === Base.typename(T2).wrapper || return false
  T = Base.typename(T1).wrapper
  # singleton structs need to be of the exact same type
  fieldcount(T1) > 0 || return T1 == T2
  
  # else compare field-wise
  eqfields = Iterators.map(zip(fieldnames(T), fieldtypes(T1), fieldtypes(T2))) do (field, type1, type2)
    if hasmethod(Base.isapprox, Tuple{type1, type2})
      :(isapprox(e1.$field, e2.$field; kwargs...))
    else
      :(isequal(e1.$field, e2.$field))
    end
  end
  combine(expr, acc) = Expr(:&&, expr, acc)
  return foldr(combine, eqfields)
end

struct_hash(x) = struct_hash(x, zero(UInt))
@generated struct_hash(e::T, h::UInt) where T = begin
  fields = (:(e.$field) for field in fieldnames(T))
  init = Expr(:call, Base.hash, QuoteNode(Base.typename(T).name), :h)
  combine(expr, acc) = Expr(:call, Base.hash, expr, acc)
  foldr(combine, fields; init)
end


# Macros
# ======

_expr_equal(T) = :(Base.:(==)(a::$T, b::$T) = $struct_equal(a, b))
_expr_isequal(T) = :(Base.isequal(a::$T, b::$T) = $struct_isequal(a, b))
_expr_isapprox(T) = :(Base.isapprox(a::$T, b::$T; kwargs...) = $struct_isapprox(a, b; kwargs...))
_expr_hash(T) = :(Base.hash(a::$T, h::UInt) = $struct_hash(a, h))

macro struct_equal(expr)
  _struct____(expr, _expr_equal)
end
macro struct_isequal(expr)
  _struct____(expr, _expr_isequal)
end
macro struct_isapprox(expr)
  _struct____(expr, _expr_isapprox)
end
macro struct_hash(expr)
  _struct____(expr, _expr_hash)
end


# Macro Combinations 
# ..................

macro struct_hash_equal(expr)
  _struct____(expr, T -> Expr(:block, _expr_hash(T), _expr_equal(T)))
end

macro struct_hash_equal_isapprox(expr)
  _struct____(expr, T -> Expr(:block, _expr_hash(T), _expr_equal(T), _expr_isapprox(T)))
end

macro struct_hash_equal_isequal(expr)
  _struct____(expr, T -> Expr(:block, _expr_hash(T), _expr_equal(T), _expr_isequal(T)))
end

macro struct_hash_equal_isequal_isapprox(expr)
  _struct____(expr, T -> Expr(:block, _expr_hash(T), _expr_equal(T), _expr_isequal(T), _expr_isapprox(T)))
end


# Backwards compatibility
# .......................

macro def_structequal(expr)
  Base.depwarn("`@def_structequal` is deprecated, use `@struct_equal` instead.", Symbol("@def_structequal"))
  _struct____(expr, _expr_equal)
end


# Generic implementation
# ======================

function _struct____(expr, create_expr)
  # check whether the given input expr is just referring to the name of a struct
  if _isreference(expr)
    esc(create_expr(expr))

  elseif isa(expr, Type)
    name = structtype_to_referenceexpr(expr)
    esc(create_expr(name))

  else
    new_exprs = map(create_expr ∘ _extract_structname, _find_structs(expr))
    @assert nonempty(new_exprs) "haven't found any struct"
    new_exprs_merged = length(new_exprs) == 1 ? new_exprs[1] : Expr(:block, new_exprs...)
    
    esc(quote
      Core.@__doc__ $expr
      $new_exprs_merged
    end)
  end
end


end # module
