# separate out in module to have the abliity of defining cat
"""
    module Concatenate

This module provides a slight modification to the Base implementation of concatenation.
In particular, the biggest hindrance there is that the output is selected based solely on the first input argument.
Here, we remedy this, and along the way leave some more flexible entry points.
Where possible, the final default implementation hooks back into Base, to minimize the required code.

For users, this implements `cat(!)`, which up to a slight modification of the signature follow their Base counterparts.

Developers can specialize the behavior and implementations of these functions,
either changing the destination through [`cat_size_shape`](@ref) and [`cat_similar`](@ref),
or the filling procedure via [`copy_or_fill!`](@ref), [`cat_offset1!`](@ref) or [`cat_offset!`](@ref)
"""
module Concatenate

#=
This is mostly a copy of the Base implementation, with the main difference being
that the destination is chosen based on all inputs instead of just the first.

Additionally, we have an intermediate representation in terms of a Concatenated object,
reminiscent of how Broadcast works.

The various entry points for specializing behavior are:

* Destination selection can be achieved through
    Base.similar(cat::Concatenated{Interface}, ::Type{T}, axes) where {Interface}

* Implementation for moving one or more arguments into the destionation through
    copy_offset!(dest, shape, catdims, offsets, args...)
    copy_offset1!(dest, shape, catdims, offsets, x)

* Custom implementations:
    Base.copy(cat::Concatenated{Interface}) # custom implementation of concatenate
    Base.copyto!(dest, cat::Concatenated{Interface}) # custom implementation of concatenate! based on interface
    Base.copyto!(dest, cat::Concatenated{Nothing}) # custom implementation of concatenate! based on typeof(dest)
=#

export concatenate, concatenate!
public Concatenated, cat_offset!, cat_offset1!, copy_or_fill!

using Base: promote_eltypeof
using .DerivableInterfaces: AbstractInterface, interface

# TODO: named like this because Catted looks so ugly and Cat is module name?
# cfr Broadcast - Broadcasted
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
DerivableInterfaces.interface(cat::Concatenated) = cat.interface

concatenated(args...; dims) = Concatenated(args, Val(dims))

# allocating the destination container
# ------------------------------------
Base.similar(cat::Concatenated) = similar(cat, promote_eltypeof(cat.args...))
Base.similar(cat::Concatenated, ::Type{T}) where {T} = similar(cat, T, axes(cat))
function Base.similar(cat::Concatenated, ::Type{T}, ax) where {T}
  return cat_similar(interface(cat), T, ax)
end

# For now, simply couple back to base implementation
function Base.axes(cat::Concatenated)
  catdims = Base.dims2cat(dims(cat))
  return cat_size_shape(catdims, cat.args...)
end

cat_size_shape(catdims, args...) = Base.cat_size_shape(catdims, args...)
cat_similar(::Type{T}, shape, args...) = Base.cat_similar(args[1], T, shape)

# Main logic
# ----------
concatenate(args...; dims) = Base.materialize(concatenated(dims, args...))
Base.materialize(cat::Concatenated) = copy(cat)

function concatenate!(dest, args...; dims)
  Base.materialize!(dest, concatenated(dims, args...))
  return dest
end
Base.materialize!(dest, cat::Concatenated) = copyto!(dest, cat)

Base.copy(cat::Concatenated) = copyto!(similar(cat), cat)

# default falls back to replacing interface with Nothing
# this permits specializing on typeof(dest) without ambiguities
@inline Base.copyto!(dest, cat::Concatenated) =
  copyto!(dest, convert(Concatenated{Nothing}, cat))

function Base.copyto!(dest::AbstractArray, cat::Concatenated{Nothing})
  # if concatenation along multiple directions, holes need to be zero.
  catdims = Base.dims2cat(dims(cat))
  count(!iszero, catdims)::Int > 1 && zero!(dest)

  shape = cat_size_shape(catdims, cat.args...)
  offsets = ntuple(zero, ndims(dest))
  return cat_offset!(dest, shape, catdims, offsets, cat.args...)
end

# Array implementation
# --------------------
# Write in terms of a generic cat_offset!, which in term aims to specialize on 1 argument
# at a time via cat_offset1! to avoid having to write too many specializations
function cat_offset!(dest, shape, catdims, offsets, x, X...)
  dest, newoffsets = cat_offset1!(dest, shape, catdims, offsets, x)
  return cat_offset!(dest, shape, newoffsets, X...)
end
cat_offset!(dest, shape, catdims, offsets) = dest

# this is the typical specialization point, which is no longer vararg.
# it simply computes indices and calls out to copy_or_fill!, so if that
# pattern works you can also overload that function
function cat_offset1!(dest, shape, catdims, offsets, x)
  inds = ntuple(length(offests)) do i
    (i ≤ length(catdims) && catdims[i]) ? offsets[i] + cat_indices(x, i) : 1:shape[i]
  end
  copy_or_fill!(dest, inds, x)
  newoffsets = ntuple(length(offsets)) do i
    (i ≤ length(catdims) && catdims[i]) ? offsets[i] + cat_size(x, i) : offsets[i]
  end
  return dest, newoffsets
end

copy_or_fill!(dest, inds, x) = Base._copy_or_fill!(dest, inds, x)

end
