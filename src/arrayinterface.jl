"""
`AbstractArrayInterface{N} <: AbstractInterface` is the abstract supertype for any interface
associated with an `AbstractArray` type.
The `N` parameter is the dimensionality, which can be handy for array types that only support
specific dimensionalities.
"""
abstract type AbstractArrayInterface{N} <: AbstractInterface end

"""
`DefaultArrayInterface{N}()` is the interface indicating that an object behaves as an `N`-dimensional
array, but hasn't defined a specialized interface. In the absence of overrides from other
`AbstractArrayInterface` arguments, this results in non-overdubbed function calls.
"""
struct DefaultArrayInterface{N} <: AbstractArrayInterface{N} end

# avoid emitting warnings in fallback `call` definition
call(::DefaultArrayInterface, f, args...; kwargs...) = f(args...; kwargs...)

using TypeParameterAccessors: parenttype
# attempt to figure out interface type from parent
function interface(::Type{A}) where {A<:AbstractArray}
  pA = parenttype(A)
  return pA === A ? DefaultArrayInterface{ndims(A)}() : interface(pA)
end

function interface(::Type{B}) where {B<:Broadcast.AbstractArrayStyle}
  return DefaultArrayInterface{ndims(B)}()
end

# Combination rules
combine_interface_rule(::DefaultArrayInterface, I::AbstractArrayInterface) = I
combine_interface_rule(I::AbstractArrayInterface, ::DefaultArrayInterface) = I
