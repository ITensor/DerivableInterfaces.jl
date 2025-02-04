# separate out in module to have the abliity of defining cat
"""
    module Cat

This module provides a slight modification to the Base implementation of concatenation.
In particular, the biggest hindrance there is that the output is selected based solely on the first input argument.
Here, we remedy this, and along the way leave some more flexible entry points.
Where possible, the final default implementation hooks back into Base, to minimize the required code.

For users, this implements `cat(!)`, which up to a slight modification of the signature follow their Base counterparts.

Developers can specialize the behavior and implementations of these functions,
either changing the destination through [`cat_size_shape`](@ref) and [`cat_similar`](@ref),
or the filling procedure via [`copy_or_fill!`](@ref), [`cat_offset1!`](@ref) or [`cat_offset!`](@ref)
"""
module Cat

# this seems to break the formatter?
# public cat
# public cat!
# public cat_size_shape
# public cat_similar
# public cat_offset!
# public cat_offset1!
# public copy_or_fill!

# This is mostly a copy of the Base implementation, with the main difference being
# that the destination is chosen based on all inputs instead of just the first.

# The entry points for deciding the destination are cat_size_shape and cat_similar(T, shape, args...)

# Hooking into the actual concatenation machinery can be done in two ways:
# - specializing cat_offset!(dest, shape, catdims, offsets, x) on dest and/or x
# - specializing copy_or_fill!(dest, inds, x) on dest and/or x

function cat(dims, args...)
  T = promote_eltypeof(args...)
  catdims = Base.dims2cat(dims)
  shape = cat_size_shape(catdims, args...)
  dest = cat_similar(T, shape, args...)
  if count(!iszero, catdims)::Int > 1
    zero!(dest)
  end
  return cat!(dest, shape, catdims, args...)
end

function cat!(dest, shape, catdims, args...)
  offsets = ntuple(zero, ndims(dest))
  return cat_offset!(dest, shape, catdims, offsets, args...)
end

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

# utility functions, default to their base counterparts but defined here to
# have the option to hook into (promote to public)
copy_or_fill!(dest, inds, x) = Base._copy_or_fill!(dest, inds, x)
cat_size_shape(catdims, args...) = Base.cat_size_shape(catdims, args...)
cat_similar(::Type{T}, shape, args...) = Base.cat_similar(args[1], T, shape)

end
