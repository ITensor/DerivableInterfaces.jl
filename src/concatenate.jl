"""
    module Concatenate

Alternative implementation for `Base.cat` through [`cat(!)`](@ref cat).

This is mostly a copy of the Base implementation, with the main difference being
that the destination is chosen based on all inputs instead of just the first.

Additionally, we have an intermediate representation in terms of a Concatenated object,
reminiscent of how Broadcast works.

The various entry points for specializing behavior are:

* Destination selection can be achieved through

    Base.similar(concat::Concatenated{Interface}, ::Type{T}, axes) where {Interface}

* Custom implementations:

    Base.copy(concat::Concatenated{Interface}) # custom implementation of cat
    Base.copyto!(dest, concat::Concatenated{Interface}) # custom implementation of cat! based on interface
    Base.copyto!(dest, concat::Concatenated{Nothing}) # custom implementation of cat! based on typeof(dest)
"""
module Concatenate

using Compat: @compat
export concatenate
@compat public Concatenated, cat, cat!, concatenated

using Base: promote_eltypeof
using ..DerivableInterfaces:
  DerivableInterfaces, AbstractInterface, interface, zero!, arraytype

"""
    Concatenated{Interface,Dims,Args<:Tuple}

Lazy representation of the concatenation of various `Args` along `Dims`, in order to provide
hooks to customize the implementation.
"""
struct Concatenated{Interface,Dims,Args<:Tuple}
  interface::Interface
  dims::Val{Dims}
  args::Args

  function Concatenated(
    interface::Union{Nothing,AbstractInterface}, dims::Val{Dims}, args::Tuple
  ) where {Dims}
    return new{typeof(interface),Dims,typeof(args)}(interface, dims, args)
  end
  function Concatenated(dims, args::Tuple)
    return Concatenated(interface(args...), dims, args)
  end
  function Concatenated{Interface}(dims, args) where {Interface}
    return Concatenated(Interface(), dims, args)
  end
  function Concatenated{Interface,Dims}(args) where {Interface,Dims}
    return new{Interface,Dims,typeof(args)}(Interface(), Val(Dims), args)
  end
end

dims(::Concatenated{A,D}) where {A,D} = D
DerivableInterfaces.interface(concat::Concatenated) = concat.interface

concatenated(dims, args...) = concatenated(Val(dims), args...)
concatenated(dims::Val, args...) = Concatenated(dims, args)

function Base.convert(
  ::Type{Concatenated{NewInterface}}, concat::Concatenated{<:Any,Dims,Args}
) where {NewInterface,Dims,Args}
  return Concatenated{NewInterface}(
    concat.dims, concat.args
  )::Concatenated{NewInterface,Dims,Args}
end

# allocating the destination container
# ------------------------------------
Base.similar(concat::Concatenated) = similar(concat, eltype(concat))
Base.similar(concat::Concatenated, ::Type{T}) where {T} = similar(concat, T, axes(concat))
function Base.similar(concat::Concatenated, ::Type{T}, ax) where {T}
  return similar(arraytype(interface(concat), T), ax)
end

Base.eltype(concat::Concatenated) = promote_eltypeof(concat.args...)

# For now, simply couple back to base implementation
function Base.axes(concat::Concatenated)
  catdims = Base.dims2cat(dims(concat))
  return Base.cat_size_shape(catdims, concat.args...)
end

# Main logic
# ----------
"""
    concatenate(dims, args...)

Concatenate the supplied `args` along dimensions `dims`.

See also [`cat`] and [`cat!`](@ref).
"""
concatenate(dims, args...) = Base.materialize(concatenated(dims, args...))

"""
    Concatenate.cat(args...; dims)

Concatenate the supplied `args` along dimensions `dims`.

See also [`concatenate`] and [`cat!`](@ref).
"""
cat(args...; dims) = concatenate(dims, args...)
Base.materialize(concat::Concatenated) = copy(concat)

"""
    Concatenate.cat!(dest, args...; dims)

Concatenate the supplied `args` along dimensions `dims`, placing the result into `dest`.
"""
function cat!(dest, args...; dims)
  Base.materialize!(dest, concatenated(dims, args...))
  return dest
end
Base.materialize!(dest, concat::Concatenated) = copyto!(dest, concat)

Base.copy(concat::Concatenated) = copyto!(similar(concat), concat)

# default falls back to replacing interface with Nothing
# this permits specializing on typeof(dest) without ambiguities
# Note: this needs to be defined for AbstractArray specifically to avoid ambiguities with Base.
@inline Base.copyto!(dest::AbstractArray, concat::Concatenated) =
  copyto!(dest, convert(Concatenated{Nothing}, concat))

# couple back to Base implementation if no specialization exists:
# https://github.com/JuliaLang/julia/blob/29da86bb983066dd076439c2c7bc5e28dbd611bb/base/abstractarray.jl#L1852
function Base.copyto!(dest::AbstractArray, concat::Concatenated{Nothing})
  catdims = Base.dims2cat(dims(concat))
  shape = Base.cat_size_shape(catdims, concat.args...)
  count(!iszero, catdims)::Int > 1 && zero!(dest)
  return Base.__cat(dest, shape, catdims, concat.args...)
end

end
