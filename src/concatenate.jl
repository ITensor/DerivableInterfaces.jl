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

unval(x) = x
unval(::Val{x}) where {x} = x

function _Concatenated end

"""
    Concatenated{Interface,Dims,Axes,Args<:Tuple}

Lazy representation of the concatenation of various `Args` along `Dims`, in order to provide
hooks to customize the implementation.
"""
struct Concatenated{Interface,Dims,Axes,Args<:Tuple}
  interface::Interface
  dims::Val{Dims}
  args::Args
  axes::Axes
  global @inline function _Concatenated(
    interface::Interface, dims::Val{Dims}, args::Args
  ) where {Interface,Dims,Args<:Tuple}
    ax = cat_axes(dims, args...)
    return new{Interface,Dims,typeof(ax),Args}(interface, dims, args, ax)
  end
end

function Concatenated(interface::Union{Nothing,AbstractInterface}, dims::Val, args::Tuple)
  return _Concatenated(interface, dims, args)
end
function Concatenated(dims::Val, args::Tuple)
  return Concatenated(interface(args...), dims, args)
end
function Concatenated{Interface}(dims::Val, args) where {Interface}
  return Concatenated(Interface(), dims, args)
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

function cat_axis(
  a1::AbstractUnitRange, a2::AbstractUnitRange, a_rest::AbstractUnitRange...
)
  return cat_axis(cat_axis(a1, a2), a_rest...)
end
cat_axis(a1::AbstractUnitRange, a2::AbstractUnitRange) = Base.OneTo(length(a1) + length(a2))

function cat_ndims(dims, as::AbstractArray...)
  return max(maximum(dims), maximum(ndims, as))
end
function cat_ndims(dims::Val, as::AbstractArray...)
  return cat_ndims(unval(dims), as...)
end

function cat_axes(dims, as::AbstractArray...)
  return ntuple(cat_ndims(dims, as...)) do dim
    if dim ∉ dims
      return axes(first(as), dim)
    end
    return cat_axis(map(ax -> get(ax, dim, Base.OneTo(1)), axes.(as))...)
  end
end
function cat_axes(dims::Val, as::AbstractArray...)
  return cat_axes(unval(dims), as...)
end

function Base.axes(concat::Concatenated)
  !isnothing(concat.axes) && return concat.axes
  return cat_axes(dims(concat), concat.args...)
end

Base.eltype(concat::Concatenated) = promote_eltypeof(concat.args...)
Base.size(concat::Concatenated) = length.(axes(concat))
Base.ndims(concat::Concatenated) = length(axes(concat))

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
@inline function Base.copyto!(dest::AbstractArray, concat::Concatenated)
  return copyto!(dest, convert(Concatenated{Nothing}, concat))
end

_copy_or_fill!(A, inds, x) = fill!(view(A, inds...), x)
_copy_or_fill!(A, inds, x::AbstractArray) = (A[inds...] = x)

cat_size(A) = (1,)
cat_size(A::AbstractArray) = size(A)
cat_size(A, d) = 1
cat_size(A::AbstractArray, d) = size(A, d)

cat_indices(A, d) = Base.OneTo(1)
cat_indices(A::AbstractArray, d) = axes(A, d)

function __cat!(A, shape, catdims, X...)
  return __cat_offset!(A, shape, catdims, ntuple(zero, length(shape)), X...)
end
function __cat_offset!(A, shape, catdims, offsets, x, X...)
  # splitting the "work" on x from X... may reduce latency (fewer costly specializations)
  newoffsets = __cat_offset1!(A, shape, catdims, offsets, x)
  return __cat_offset!(A, shape, catdims, newoffsets, X...)
end
__cat_offset!(A, shape, catdims, offsets) = A
function __cat_offset1!(A, shape, catdims, offsets, x)
  inds = ntuple(length(offsets)) do i
    (i <= length(catdims) && catdims[i]) ? offsets[i] .+ cat_indices(x, i) : 1:shape[i]
  end
  _copy_or_fill!(A, inds, x)
  newoffsets = ntuple(length(offsets)) do i
    (i <= length(catdims) && catdims[i]) ? offsets[i] + cat_size(x, i) : offsets[i]
  end
  return newoffsets
end

dims2cat(dims::Val) = dims2cat(unval(dims))
function dims2cat(dims)
  if any(≤(0), dims)
    throw(ArgumentError("All cat dimensions must be positive integers, but got $dims"))
  end
  return ntuple(in(dims), maximum(dims))
end

# couple back to Base implementation if no specialization exists:
# https://github.com/JuliaLang/julia/blob/29da86bb983066dd076439c2c7bc5e28dbd611bb/base/abstractarray.jl#L1852
function Base.copyto!(dest::AbstractArray, concat::Concatenated{Nothing})
  catdims = dims2cat(dims(concat))
  shape = size(concat)
  count(!iszero, catdims)::Int > 1 && zero!(dest)
  return __cat!(dest, shape, catdims, concat.args...)
end

end
