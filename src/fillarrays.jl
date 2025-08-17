# TODO: Turn this into a package extension, for some reson there is an issue
# with having a package extension for both FillArrays and BlockArrays
# in Julia v1.10.
using FillArrays: RectDiagonal
function permuteddims(a::RectDiagonal, perm)
  (ndims(a) == length(perm) && isperm(perm)) ||
    throw(ArgumentError("no valid permutation of dimensions"))
  return RectDiagonal(parent(a), ntuple(d -> axes(a)[perm[d]], ndims(a)))
end
