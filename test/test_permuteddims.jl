using DerivableInterfaces: permuteddims
using Test: @test, @testset

@testset "permuteddims" begin
  a = randn(2, 3, 4)
  @test permuteddims(a, (2, 1, 3)) ≡ PermutedDimsArray(a, (2, 1, 3))
end
