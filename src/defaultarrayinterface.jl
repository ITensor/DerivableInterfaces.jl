using TypeParameterAccessors: parenttype, set_eltype, unspecify_type_parameters

struct DefaultArrayInterface{N,A<:AbstractArray} <: AbstractArrayInterface{N} end

DefaultArrayInterface{N}() where {N} = DefaultArrayInterface{N,AbstractArray}()
DefaultArrayInterface() = DefaultArrayInterface{Any}()
DefaultArrayInterface(::Val{N}) where {N} = DefaultArrayInterface{N}()
DefaultArrayInterface{M}(::Val{N}) where {M,N} = DefaultArrayInterface{N}()
DefaultArrayInterface{M,A}(::Val{N}) where {M,A,N} = DefaultArrayInterface{N,A}()

# This version remembers the `ndims` of the wrapper type.
function _interface(::Val{N}, arrayt::Type{<:AbstractArray}) where {N}
  arrayt′ = parenttype(arrayt)
  if arrayt′ === arrayt
    return DefaultArrayInterface{N,unspecify_type_parameters(arrayt)}()
  end
  return typeof(interface(arrayt′))(Val(N))
end

function DerivableInterfaces.interface(arrayt::Type{<:AbstractArray{<:Any,N}}) where {N}
  return _interface(Val(N), arrayt)
end
function DerivableInterfaces.interface(arrayt::Type{<:AbstractArray})
  return _interface(Val(Any), arrayt)
end

function Base.similar(
  ::DefaultArrayInterface{<:Any,A}, T::Type, ax::Tuple
) where {A<:AbstractArray}
  if isabstracttype(A)
    # If the type is abstract, default to constructing the array on CPU.
    return similar(Array{T}, ax)
  else
    return similar(set_eltype(A, T), ax)
  end
end

function combine_interface_rule(
  interface1::DefaultArrayInterface{N,A}, interface2::DefaultArrayInterface{N,A}
) where {N,A<:AbstractArray}
  return DefaultArrayInterface{N,A}()
end
function combine_interface_rule(
  interface1::DefaultArrayInterface{<:Any,A}, interface2::DefaultArrayInterface{<:Any,A}
) where {A<:AbstractArray}
  return DefaultArrayInterface{Any,A}()
end
function combine_interface_rule(
  interface1::DefaultArrayInterface{N}, interface2::DefaultArrayInterface{N}
) where {N}
  return DefaultArrayInterface{N}()
end
function combine_interface_rule(
  interface1::DefaultArrayInterface, interface2::DefaultArrayInterface
)
  return DefaultArrayInterface()
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
