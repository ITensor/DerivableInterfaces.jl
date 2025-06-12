struct DefaultArrayInterface{N} <: AbstractArrayInterface{N} end

DefaultArrayInterface() = DefaultArrayInterface{Any}()
DefaultArrayInterface(::Val{N}) where {N} = DefaultArrayInterface{N}()
DefaultArrayInterface{M}(::Val{N}) where {M,N} = DefaultArrayInterface{N}()

function DerivableInterfaces.interface(arrayt::Type{<:Array{<:Any,N}}) where {N}
  return DefaultArrayInterface{N}()
end
function DerivableInterfaces.interface(arrayt::Type{<:Array})
  return DefaultArrayInterface()
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

struct ArrayInterface{N,A<:AbstractArray} <: AbstractArrayInterface{N} end
ArrayInterface{M,A}(::Val{N}) where {M,A,N} = ArrayInterface{N,A}()

function Base.similar(
  interface::ArrayInterface{A}, elt::Type, ax::Tuple
) where {A<:AbstractArray}
  return similar(set_eltype(A, elt), ax)
end

using TypeParameterAccessors: parenttype, unspecify_type_parameters
function _interface(::Val{N}, arrayt::Type{<:AbstractArray}) where {N}
  arrayt′ = parenttype(arrayt)
  if arrayt′ === arrayt
    if arrayt <: Array || isabstracttype(arrayt)
      return DefaultArrayInterface{N}()
    else
      return ArrayInterface{N,unspecify_type_parameters(arrayt)}()
    end
  end
  return _interface(Val(N), arrayt′)
end

function DerivableInterfaces.interface(arrayt::Type{<:AbstractArray{<:Any,N}}) where {N}
  return _interface(Val(N), arrayt)
end
function DerivableInterfaces.interface(arrayt::Type{<:AbstractArray})
  return _interface(Val(Any), arrayt)
end

using TypeParameterAccessors: set_eltype
function Base.similar(::ArrayInterface{<:Any,A}, T::Type, ax::Tuple) where {A}
  return similar(set_eltype(A, T), ax)
end

function combine_interface_rule(
  interface1::ArrayInterface{N,A}, interface2::ArrayInterface{N,A}
) where {N,A<:AbstractArray}
  return ArrayInterface{N,A}()
end

function combine_interface_rule(
  interface1::ArrayInterface{<:Any,A}, interface2::ArrayInterface{<:Any,A}
) where {A<:AbstractArray}
  return ArrayInterface{Any,A}()
end
function combine_interface_rule(
  interface1::ArrayInterface{N}, interface2::ArrayInterface{N}
) where {N}
  return DefaultArrayInterface{N}()
end
function combine_interface_rule(interface1::ArrayInterface, interface2::ArrayInterface)
  return DefaultArrayInterface()
end
function DerivableInterfaces.combine_interface_rule(
  inter1::ArrayInterface, inter2::DefaultArrayInterface
)
  return DefaultArrayInterface()
end
function DerivableInterfaces.combine_interface_rule(
  inter1::DefaultArrayInterface, inter2::ArrayInterface
)
  return DefaultArrayInterface()
end
function DerivableInterfaces.combine_interface_rule(
  inter1::ArrayInterface{N}, inter2::DefaultArrayInterface{N}
) where {N}
  return DefaultArrayInterface{N}()
end
function DerivableInterfaces.combine_interface_rule(
  inter1::DefaultArrayInterface{N}, inter2::ArrayInterface{N}
) where {N}
  return DefaultArrayInterface{N}()
end
