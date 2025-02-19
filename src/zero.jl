"""
    zero!(x::AbstractArray)

In-place version of `Base.zero`.
"""
function zero! end

@derive (T=AbstractArray,) zero!(::T)

# TODO: should this be recursive? `map!(zero!, A, A)` might also work?
@interface ::AbstractArrayInterface zero!(A::AbstractArray) = fill!(A, zero(eltype(A)))
