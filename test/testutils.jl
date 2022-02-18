function structtype_to_referenceexpr(StructType)
    fields = map(Symbol, split(repr(StructType), "."))
    first, _rest = Iterators.peel(fields)

    # all but the first field are QuoteNodes, the first is a plain Symbol 
    rest = map(QuoteNode, _rest)

    return foldl(rest, init=first) do acc, name
        Expr(:(.), acc, name)
    end
end


function insert_macro_before_struct!(expr, macroname)
    expr.args[2] = Expr(:macrocall, macroname, expr.args[1], expr.args[2])
    return expr
end
  