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
# this effectively has almost no implementations, as they are inherited from the supertype
# either explicitly or will throw an error. It is simply a concrete instance to use the
# abstractarrayinterface implementations.

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
# -----------------
function combine_interface_rule(
  ::DefaultArrayInterface{N}, I::AbstractArrayInterface{N}
) where {N}
  return I
end
function combine_interface_rule(
  I::AbstractArrayInterface{N}, ::DefaultArrayInterface{N}
) where {N}
  return I
end
function combine_interface_rule(
  ::DefaultArrayInterface{N}, ::DefaultArrayInterface{N}
) where {N}
  return DefaultArrayInterface{N}()
end

# Fallback implementations
# ------------------------
