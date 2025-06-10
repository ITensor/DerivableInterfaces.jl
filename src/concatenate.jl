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
using ..DerivableInterfaces: DerivableInterfaces, AbstractArrayInterface, interface, zero!

unval(x) = x
unval(::Val{x}) where {x} = x

set_interface_ndims(::Type{Nothing}, ::Val{N}) where {N} = nothing
function set_interface_ndims(Interface::Type{<:AbstractArrayInterface}, ::Val{N}) where {N}
  return Interface(Val(N))
end

function _Concatenated end

"""
    Concatenated{Interface,Dims,Args<:Tuple}

Lazy representation of the concatenation of various `Args` along `Dims`, in order to provide
hooks to customize the implementation.
"""
struct Concatenated{Interface,Dims,Args<:Tuple}
  interface::Interface
  dims::Val{Dims}
  args::Args
  global @inline function _Concatenated(
    interface::Interface, dims::Val{Dims}, args::Args
  ) where {Interface,Dims,Args<:Tuple}
    return new{Interface,Dims,Args}(interface, dims, args)
  end
end

function Concatenated(interface::Nothing, dims::Val, args::Tuple)
  return _Concatenated(interface, dims, args)
end
function Concatenated(interface::AbstractArrayInterface, dims::Val, args::Tuple)
  N = cat_ndims(dims, args...)
  return _Concatenated(typeof(interface)(Val(N)), dims, args)
end
function Concatenated(dims::Val, args::Tuple)
  N = cat_ndims(dims, args...)
  return _Concatenated(typeof(interface(args...))(Val(N)), dims, args)
end
function Concatenated{Interface}(dims::Val, args::Tuple) where {Interface}
  N = cat_ndims(dims, args...)
  return _Concatenated(set_interface_ndims(Interface, Val(N)), dims, args)
end

dims(::Concatenated{<:Any,D}) where {D} = D
DerivableInterfaces.interface(concat::Concatenated) = getfield(concat, :interface)

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
function Base.similar(concat::Concatenated, ax::Tuple)
  return similar(interface(concat), eltype(concat), ax)
end
function Base.similar(concat::Concatenated, ::Type{T}, ax::Tuple) where {T}
  return similar(interface(concat), T, ax)
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

function cat_axes(dims, a::AbstractArray, as::AbstractArray...)
  return ntuple(cat_ndims(dims, a, as...)) do dim
    return dim in dims ? cat_axis(map(Base.Fix2(axes, dim), (a, as...))...) : axes(a, dim)
  end
end
function cat_axes(dims::Val, as::AbstractArray...)
  return cat_axes(unval(dims), as...)
end

Base.eltype(concat::Concatenated) = promote_eltypeof(concat.args...)
Base.axes(concat::Concatenated) = cat_axes(dims(concat), concat.args...)
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

# The following is largely copied from the Base implementation of `Base.cat`, see:
# https://github.com/JuliaLang/julia/blob/885b1cd875f101f227b345f681cc36879124d80d/base/abstractarray.jl#L1778-L1887
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

# default falls back to replacing interface with Nothing
# this permits specializing on typeof(dest) without ambiguities
# Note: this needs to be defined for AbstractArray specifically to avoid ambiguities with Base.
@inline function Base.copyto!(dest::AbstractArray, concat::Concatenated)
  return copyto!(dest, convert(Concatenated{Nothing}, concat))
end

function Base.copyto!(dest::AbstractArray, concat::Concatenated{Nothing})
  catdims = dims2cat(dims(concat))
  shape = size(concat)
  count(!iszero, catdims)::Int > 1 && zero!(dest)
  return __cat!(dest, shape, catdims, concat.args...)
end

end
