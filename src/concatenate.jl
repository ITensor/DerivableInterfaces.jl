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

* Implementation for moving one or more arguments into the destionation through

    copy_offset!(dest, shape, catdims, offsets, args...)
    copy_offset1!(dest, shape, catdims, offsets, x)

* Custom implementations:

    Base.copy(concat::Concatenated{Interface}) # custom implementation of cat
    Base.copyto!(dest, concat::Concatenated{Interface}) # custom implementation of cat! based on interface
    Base.copyto!(dest, concat::Concatenated{Nothing}) # custom implementation of cat! based on typeof(dest)
"""
module Concatenate

using Compat: @compat
@compat public Concatenated

using Base: promote_eltypeof
using ..DerivableInterfaces: DerivableInterfaces, AbstractInterface, interface

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

concatenated(args...; dims) = Concatenated(Val(dims), args)

function Base.convert(
  ::Type{Concatenated{NewInterface}}, concat::Concatenated{<:Any,Dims,Args}
) where {NewInterface,Dims,Args}
  return Concatenated{NewInterface}(
    concat.dims, concat.args
  )::Concatenated{NewInterface,Dims,Args}
end

# allocating the destination container
# ------------------------------------
Base.similar(concat::Concatenated) = similar(concat, eltype(cat))
Base.similar(concat::Concatenated, ::Type{T}) where {T} = similar(concat, T, axes(cat))
function Base.similar(concat::Concatenated, ::Type{T}, ax) where {T}
  return similar(interface(concat), T, ax)
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
    Concatenate.cat(args...; dims)

Concatenate the supplied `args` along dimensions `dims`.

See also [`cat!`](@ref).
"""
cat(args...; dims) = Base.materialize(concatenated(args...; dims))
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

# Array implementation
# --------------------
# Write in terms of a generic cat_offset!, which in term aims to specialize on 1 argument
# at a time via cat_offset1! to avoid having to write too many specializations
# function cat_offset!(dest, shape, catdims, offsets, x, X...)
#   dest, newoffsets = cat_offset1!(dest, shape, catdims, offsets, x)
#   return cat_offset!(dest, shape, catdims, newoffsets, X...)
# end
# cat_offset!(dest, shape, catdims, offsets) = dest

# this is the typical specialization point, which is no longer vararg.
# it simply computes indices and calls out to copy_or_fill!, so if that
# pattern works you can also overload that function
# function cat_offset1!(dest, shape, catdims, offsets, x)
#   inds = ntuple(length(offsets)) do i
#     (i ≤ length(catdims) && catdims[i]) ? offsets[i] .+ axes(x, i) : 1:shape[i]
#   end
#   copy_or_fill!(dest, inds, x)
#   newoffsets = ntuple(length(offsets)) do i
#     (i ≤ length(catdims) && catdims[i]) ? offsets[i] + size(x, i) : offsets[i]
#   end
#   return dest, newoffsets
# end

# copy of Base._copy_or_fill!
# copy_or_fill!(A, inds, x) = fill!(view(A, inds...), x)
# copy_or_fill!(A, inds, x::AbstractArray) = (A[inds...] = x)

zero!(x::AbstractArray) = fill!(x, zero(eltype(x)))

end
