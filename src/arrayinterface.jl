"""
`AbstractArrayInterface <: AbstractInterface` is the abstract supertype for any interface
associated with an `AbstractArray` type.
"""
abstract type AbstractArrayInterface <: AbstractInterface end

"""
`DefaultArrayInterface()` is the interface indicating that an object behaves as an 
array, but hasn't defined a specialized interface. In the absence of overrides from other
`AbstractArrayInterface` arguments, this results in non-overdubbed function calls.
"""
struct DefaultArrayInterface <: AbstractArrayInterface end
# this effectively has almost no implementations, as they are inherited from the supertype
# either explicitly or will throw an error. It is simply a concrete instance to use the
# abstractarrayinterface implementations.

using TypeParameterAccessors: parenttype
# attempt to figure out interface type from parent
function interface(::Type{A}) where {A<:AbstractArray}
  pA = parenttype(A)
  return pA === A ? DefaultArrayInterface() : interface(pA)
end

function interface(::Type{B}) where {B<:Broadcast.AbstractArrayStyle}
  return DefaultArrayInterface()
end

# Combination rules
# -----------------
function combine_interface_rule(::DefaultArrayInterface, I::AbstractArrayInterface)
  return I
end
function combine_interface_rule(I::AbstractArrayInterface, ::DefaultArrayInterface)
  return I
end
function combine_interface_rule(::DefaultArrayInterface, ::DefaultArrayInterface)
  return DefaultArrayInterface()
end

# Fallback implementations
# ------------------------
