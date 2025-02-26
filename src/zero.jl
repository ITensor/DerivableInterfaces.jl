"""
    zero!(x::AbstractArray)

In-place function for zero-ing out an array.
"""
zero!(x::AbstractArray) = @interface interface(x) zero!(x)

@interface ::AbstractArrayInterface zero!(x::AbstractArray) = fill!(x, zero(eltype(x)))
