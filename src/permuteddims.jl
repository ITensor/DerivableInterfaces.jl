"""
    permuteddims(a::AbstractArray, perm)

Lazy version of `permutedims`. Defaults to constructing a `Base.PermutedDimsArray`
but can be customized to output a different type of array.
"""
permuteddims(a::AbstractArray, perm) = PermutedDimsArray(a, perm)
# See: https://github.com/JuliaLang/julia/issues/53188
