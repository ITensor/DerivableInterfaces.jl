module DerivableInterfacesFillArraysExt

using DerivableInterfaces: DerivableInterfaces
using FillArrays: RectDiagonal
function DerivableInterfaces.permuteddims(a::RectDiagonal, perm)
  (ndims(a) == length(perm) && isperm(perm)) ||
    throw(ArgumentError("no valid permutation of dimensions"))
  return RectDiagonal(parent(a), ntuple(d -> axes(a)[perm[d]], ndims(a)))
end

end
