using DerivableInterfaces.Concatenate: concatenated
using Test: @test, @testset

@testset "Concatenated" begin
  a = randn(Float32, 2, 2)
  b = randn(Float64, 2, 2)

  concat = concatenated((1, 2), a, b)
  @test axes(concat) == Base.OneTo.((4, 4))
  @test size(concat) == (4, 4)
  @test eltype(concat) === Float64
  @test copy(concat) == cat(a, b; dims=(1, 2))

  concat = concatenated(1, a, b)
  @test axes(concat) == Base.OneTo.((4, 2))
  @test size(concat) == (4, 2)
  @test eltype(concat) === Float64
  @test copy(concat) == cat(a, b; dims=1)

  concat = concatenated(3, a, b)
  @test axes(concat) == Base.OneTo.((2, 2, 2))
  @test size(concat) == (2, 2, 2)
  @test eltype(concat) === Float64
  @test copy(concat) == cat(a, b; dims=3)

  concat = concatenated(4, a, b)
  @test axes(concat) == Base.OneTo.((2, 2, 1, 2))
  @test size(concat) == (2, 2, 1, 2)
  @test eltype(concat) === Float64
  @test copy(concat) == cat(a, b; dims=4)
end
