const issomething = !isnothing
const nonempty = !isempty

_isreference(::Symbol) = true
_isreference(expr::Expr) = expr.head == :(.)
_isreference(other) = false

_find_structs(_) = []
function _find_structs(expr::Expr)
    if expr.head == :struct
        [expr]
    else
        _flatten(_find_structs(a) for a in expr.args)
    end
end
_flatten(a) = vcat(a...)

_extract_structname(symbol::Symbol) = symbol
_extract_structname(expr::Expr) = _extract_structname(Val{expr.head}(), expr.args)
_extract_structname(head::Val{:(<:)}, args) = _extract_structname(args[1])
_extract_structname(head::Val{:curly}, args) = _extract_structname(args[1])
_extract_structname(head::Val{:struct}, args) = _extract_structname(args[2])