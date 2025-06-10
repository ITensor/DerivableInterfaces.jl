struct DefaultArrayInterface{N} <: AbstractArrayInterface{N} end

DefaultArrayInterface() = DefaultArrayInterface{Any}()
DefaultArrayInterface(::Val{N}) where {N} = DefaultArrayInterface{N}()
DefaultArrayInterface{M}(::Val{N}) where {M,N} = DefaultArrayInterface{N}()

using TypeParameterAccessors: parenttype
function interface(a::Type{<:AbstractArray})
  parenttype(a) === a && return DefaultArrayInterface()
  return interface(parenttype(a))
end
function interface(a::Type{<:AbstractArray{<:Any,N}}) where {N}
  parenttype(a) === a && return DefaultArrayInterface{N}()
  return interface(parenttype(a))
end

function combine_interface_rule(
  interface1::DefaultArrayInterface{N}, interface2::DefaultArrayInterface{N}
) where {N}
  return DefaultArrayInterface{N}()
end
function combine_interface_rule(
  interface1::DefaultArrayInterface, interface2::DefaultArrayInterface
)
  return DefaultArrayInterface{Any}()
end

@interface ::DefaultArrayInterface function Base.getindex(
  a::AbstractArray{<:Any,N}, I::Vararg{Int,N}
) where {N}
  return Base.getindex(a, I...)
end

@interface ::DefaultArrayInterface function Base.setindex!(
  a::AbstractArray{<:Any,N}, value, I::Vararg{Int,N}
) where {N}
  return Base.setindex!(a, value, I...)
end

@interface ::DefaultArrayInterface function Base.map!(
  f, a_dest::AbstractArray, a_srcs::AbstractArray...
)
  return Base.map!(f, a_dest, a_srcs...)
end

@interface ::DefaultArrayInterface function Base.mapreduce(
  f, op, as::AbstractArray...; kwargs...
)
  return Base.mapreduce(f, op, as...; kwargs...)
end

function Base.similar(::DefaultArrayInterface, T::Type, ax::Tuple)
  return similar(Array{T}, ax)
end
