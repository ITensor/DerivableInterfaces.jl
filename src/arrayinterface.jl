"""
`AbstractArrayInterface <: AbstractInterface` is the abstract supertype for any interface
using Base: BroadcastStyle
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

function interface(::Type{B}) where {B<:Broadcast.Broadcasted}
  return interface(Broadcast.BroadcastStyle(B))
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
# whenever we want to overload new interface implementations, we better have a fallback that
# sends us back to the default implementation.

@interface ::AbstractArrayInterface Base.getindex(A::AbstractArray, I...) = (
  @inline; getindex(A, I...)
)
@interface ::AbstractArrayInterface Base.setindex!(A::AbstractArray, v, I...) = (
  @inline; setindex!(A, v, I...)
)

@interface ::AbstractArrayInterface Base.similar(
  A::AbstractArray, ::Type{T}, axes
) where {T} = similar(A, T, axes)

@interface ::AbstractArrayInterface Base.map(f, A::AbstractArray, As::AbstractArray...) =
  map(f, A, As...)
@interface ::AbstractArrayInterface Base.map!(f, A::AbstractArray, As::AbstractArray...) =
  map!(f, A, As...)

@interface ::AbstractArrayInterface Base.reduce(
  op, A::AbstractArray, As::AbstractArray...
) = reduce(op, A, As...)
@interface ::AbstractArrayInterface Base.mapreduce(
  f, op, A::AbstractArray, As::AbstractArray...
) = mapreduce(f, op, A, As...)
