using DerivableInterfaces: permuteddims
using FillArrays: RectDiagonal
using LinearAlgebra: Diagonal
using Test: @test, @testset

@testset "permuteddims" begin
  a = randn(2, 3, 4)
  @test permuteddims(a, (2, 1, 3)) ≡ PermutedDimsArray(a, (2, 1, 3))

  a = Diagonal(randn(3))
  @test permuteddims(a, (1, 2)) ≡ a
  @test permuteddims(a, (2, 1)) ≡ a

  a = RectDiagonal(randn(3), (3, 4))
  @test permuteddims(a, (1, 2)) ≡ a
  @test permuteddims(a, (2, 1)) ≡ RectDiagonal(parent(a), (4, 3))
end
