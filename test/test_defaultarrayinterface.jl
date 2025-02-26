using Test: @inferred, @testset, @test
using DerivableInterfaces: @interface, DefaultArrayInterface, interface

# function wrappers to test type-stability
_getindex(A, i...) = @interface DefaultArrayInterface() A[i...]
_setindex!(A, v, i...) = @interface DefaultArrayInterface() A[i...] = v
_map!(args...) = @interface DefaultArrayInterface() map!(args...)
function _mapreduce(args...; kwargs...)
  @interface DefaultArrayInterface() mapreduce(args...; kwargs...)
end

@testset "indexing" begin
  for (A, i) in ((zeros(2), 2), (zeros(2, 2), (2, 1)), (zeros(1, 2, 3), (1, 2, 3)))
    a = @inferred _getindex(A, i...)
    @test a == A[i...]
    v = 1.1
    A′ = @inferred _setindex!(A, v, i...)
    @test A′ == (A[i...] = v)
  end
end

@testset "map!" begin
  A = zeros(3)
  a = @inferred _map!(Returns(2), copy(A), A)
  @test a == map!(Returns(2), copy(A), A)
end

@testset "mapreduce" begin
  A = zeros(3)
  a = @inferred _mapreduce(Returns(2), +, A)
  @test a == mapreduce(Returns(2), +, A)
end

@testset "Broadcast.DefaultArrayStyle" begin
  @test interface(Broadcast.DefaultArrayStyle) == DefaultArrayInterface()
  @test interface(Broadcast.broadcasted(+, randn(2), randn(2))) ==
        DefaultArrayInterface()
end
