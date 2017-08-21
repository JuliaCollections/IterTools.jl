map_tt_t{T<:Tuple}(f, tt::Type{T}) = Base.tuple_type_cons(f(Base.tuple_type_head(tt)), map_tt_t(f, Base.tuple_type_tail(tt)))
map_tt_t(f, tt::Type{Tuple{}}) = Tuple{}

function mapreduce_tt(f, op, v0, tt)
    op(f(Base.tuple_type_head(tt)), mapreduce_tt(f, op, v0, Base.tuple_type_tail(tt)))
end
mapreduce_tt(f, op, v0, tt::Type{Tuple{}}) = v0
mapreduce_tt{T}(f, op, v0, tt::Type{Tuple{T}}) = op(f(T), v0)
mapreduce_tt{T}(f, op, v0, tt::Type{Tuple{Vararg{T}}}) = op(f(T), f(T))
