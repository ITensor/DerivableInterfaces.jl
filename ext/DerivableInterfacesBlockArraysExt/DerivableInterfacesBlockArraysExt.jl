module DerivableInterfacesBlockArraysExt

using BlockArrays: BlockedOneTo, blockedrange, blocklengths
using DerivableInterfaces.Concatenate: Concatenate

function Concatenate.cat_axis(a1::BlockedOneTo, a2::BlockedOneTo)
  return blockedrange([blocklengths(a1); blocklengths(a2)])
end

end
