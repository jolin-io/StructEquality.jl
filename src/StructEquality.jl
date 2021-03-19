module StructEquality
export def_structequal, @def_structequal

using Compat

const issomething = !isnothing
const nonempty = !isempty

"""
    @def_structequal YourStructTypeName

Defines an equal `==` method for your struct which compares all fields.

Why this macro? On the opposite, Julia's default `==` compares custom structs by object reference.
I.e. it would give `YourStructTypeName([]) != YourStructTypeName([])` despite `[] == []`.
As this can be quite unintuitive, this macro provides a simple way to define the field-wise comparison.
"""
macro def_structequal(struct_expr)
  nested_reference = _nested_reference(struct_expr)
  if nonempty(nested_reference)
    struct′ = _getnestedfield(__module__, nested_reference)
    struct_attributes = fieldnames(struct′)
    esc(def_structequal(struct_expr, struct_attributes))
  else
    definitions = def_structequal(struct_expr)
    esc(quote
      Core.@__doc__ $struct_expr
      $definitions
    end)
  end
end

_nested_reference(symbol::Symbol) = (symbol,)
_nested_reference(quotenode::QuoteNode) = _nested_reference(quotenode.value)
_nested_reference(expr::Expr) = _nested_reference(Val{expr.head}(), expr.args)
_nested_reference(head::Val{:(.)}, args) = tuple(_nested_reference(args[1])..., _nested_reference(args[2])...)
_nested_reference(_, _) = ()
_getnestedfield(mod, nested_reference) = reduce(getfield, nested_reference; init=mod)


function def_structequal(expr)
  struct_exprs = _find_substructs(expr)
  @assert !isempty(struct_exprs) "expecting structs somewhere, got $(expr.head)"
  results = map(_def_structequal, struct_exprs)
  length(results) == 1 ? results[1] : Expr(:block, results...)
end

_find_substructs(_) = []
function _find_substructs(expr::Expr)
  if expr.head == :struct
    [expr]
  else
    _flatten(_find_substructs(a) for a in expr.args)
  end
end

_flatten(a) = vcat(a...)


function _def_structequal(struct_expr)
  @assert struct_expr.head == :struct  "expecting struct, got $struct_expr"
  struct_name = _extract_structname(struct_expr.args[2])
  struct_body = struct_expr.args[3]
  struct_attributes = filter(issomething, _extract_field_symbol.(struct_body.args))
  def_structequal(struct_name, struct_attributes)
end

_extract_structname(symbol::Symbol) = symbol
_extract_structname(expr::Expr) = _extract_structname(Val{expr.head}(), expr.args)
_extract_structname(head::Val{:(<:)}, args) = _extract_structname(args[1])
_extract_structname(head::Val{:(curly)}, args) = _extract_structname(args[1])

_extract_field_symbol(symbol::Symbol) = symbol
_extract_field_symbol(::LineNumberNode) = nothing
_extract_field_symbol(expr::Expr) = _extract_field_symbol(Val{expr.head}(), expr.args)
_extract_field_symbol(head::Val{:(=)}, args) = _extract_field_symbol(args[1])
_extract_field_symbol(head::Val{:(::)}, args) = _extract_field_symbol(args[1])
_extract_field_symbol(head::Val, args) = nothing
_extract_field_symbol(docstring::String) = nothing
# _extract_field_symbol(head::Val{:function}, args) = nothing
# _extract_field_symbol(head::Val{:call}, args) = nothing
# _extract_field_symbol(head::Val{:where}, args) = nothing


function def_structequal(struct_name, struct_attributes)
  @assert !isempty(struct_attributes) "struct $struct_name is singleton. structequal only makes sense for non-singleton structs"
  comparisons = (:(s1.$attr == s2.$attr) for attr in struct_attributes)
  comparison = Base.reduce(comparisons) do c1, c2
    :($c1 && $c2)
  end
  :(function Base.:(==)(s1::$struct_name, s2::$struct_name)
    $comparison
  end)
end

end # module
