using DerivableInterfaces: @interface, ArrayInterface, DefaultArrayInterface, interface
using JLArrays: JLArray, jl
using Test: @testset, @test
using TestExtras: @constinferred

# function wrappers to test type-stability
_getindex(A, i...) = @interface DefaultArrayInterface() A[i...]
_setindex!(A, v, i...) = @interface DefaultArrayInterface() A[i...] = v
_map!(args...) = @interface DefaultArrayInterface() map!(args...)
function _mapreduce(args...; kwargs...)
  @interface DefaultArrayInterface() mapreduce(args...; kwargs...)
end

@testset "indexing" begin
  for (A, i) in ((zeros(2), 2), (zeros(2, 2), (2, 1)), (zeros(1, 2, 3), (1, 2, 3)))
    a = @constinferred _getindex(A, i...)
    @test a == A[i...]
    v = 1.1
    A′ = @constinferred _setindex!(A, v, i...)
    @test A′ == (A[i...] = v)
  end
end

@testset "map!" begin
  A = zeros(3)
  a = @constinferred _map!(Returns(2), copy(A), A)
  @test a == map!(Returns(2), copy(A), A)
end

@testset "mapreduce" begin
  A = zeros(3)
  a = @constinferred _mapreduce(Returns(2), +, A)
  @test a == mapreduce(Returns(2), +, A)
end

@testset "DefaultArrayInterface" begin
  @test interface(Array) === DefaultArrayInterface{Any}()
  @test interface(Array{Float32}) === DefaultArrayInterface{Any}()
  @test interface(Matrix) === DefaultArrayInterface{2}()
  @test interface(Matrix{Float32}) === DefaultArrayInterface{2}()
  @test DefaultArrayInterface() === DefaultArrayInterface{Any}()
  @test DefaultArrayInterface(Val(2)) === DefaultArrayInterface{2}()
  @test DefaultArrayInterface{Any}(Val(2)) === DefaultArrayInterface{2}()
  @test DefaultArrayInterface{3}(Val(2)) === DefaultArrayInterface{2}()

  # DefaultArrayInterface
  @test interface(AbstractArray) === DefaultArrayInterface{Any}()
  @test interface(AbstractArray{<:Any,3}) === DefaultArrayInterface{3}()
  @test interface(Array{Float32}) === DefaultArrayInterface{Any}()
  @test interface(Array{Float32,3}) === DefaultArrayInterface{3}()
  @test interface(SubArray{<:Any,<:Any,Array}) === DefaultArrayInterface{Any}()
  @test interface(SubArray{<:Any,<:Any,AbstractArray}) === DefaultArrayInterface{Any}()
  @test interface(SubArray{<:Any,2,Array}) === DefaultArrayInterface{2}()
  @test interface(randn(2, 2)) === DefaultArrayInterface{2}()
  @test interface(view(randn(2, 2), 1:2, 1)) === DefaultArrayInterface{1}()

  # Combining DefaultArrayInterface
  @test interface(DefaultArrayInterface(), DefaultArrayInterface()) ===
    DefaultArrayInterface()
  @test interface(DefaultArrayInterface{2}(), DefaultArrayInterface{2}()) ===
    DefaultArrayInterface{2}()
  @test interface(DefaultArrayInterface{2}(), DefaultArrayInterface{3}()) ===
    DefaultArrayInterface()
  @test interface(DefaultArrayInterface(), DefaultArrayInterface{3}()) ===
    DefaultArrayInterface()
  @test interface(randn(2, 2), randn(2, 2)) === DefaultArrayInterface{2}()
  @test interface(randn(2, 2), randn(2)) === DefaultArrayInterface()
  @test interface(randn(2, 2), randn(2, 2)') === DefaultArrayInterface{2}()
end

@testset "similar(::DefaultArrayInterface, ...)" begin
  a = @constinferred similar(DefaultArrayInterface(), Float32, (2, 2))
  @test typeof(a) === Matrix{Float32}
  @test size(a) == (2, 2)

  a = @constinferred similar(DefaultArrayInterface{1}(), Float32, (2, 2))
  @test typeof(a) === Matrix{Float32}
  @test size(a) == (2, 2)
end

@testset "Broadcast.DefaultArrayStyle" begin
  @test interface(Broadcast.DefaultArrayStyle) == DefaultArrayInterface()
  @test interface(Broadcast.DefaultArrayStyle{2}) == DefaultArrayInterface{2}()
  @test interface(Broadcast.Broadcasted(nothing, +, (randn(2), randn(2)))) ==
    DefaultArrayInterface{1}()
end

@testset "ArrayInterface" begin
  # ArrayInterface
  a = jl(randn(2, 2))
  @test interface(JLArray{Float32}) === ArrayInterface{Any,JLArray}()
  @test interface(SubArray{<:Any,2,JLArray{Float32}}) === ArrayInterface{2,JLArray}()
  @test interface(a) === ArrayInterface{2,JLArray}()
  @test interface(a') === ArrayInterface{2,JLArray}()
  @test interface(view(a, 1:2, 1)) === ArrayInterface{1,JLArray}()
  a′ = similar(a, Float32, (2, 3, 3))
  @test a′ isa JLArray{Float32,3}
  @test size(a′) == (2, 3, 3)

  # Combining ArrayInterface
  @test interface(ArrayInterface{2,JLArray}(), ArrayInterface{2,JLArray}()) ===
    ArrayInterface{2,JLArray}()
  @test interface(ArrayInterface{2,JLArray}(), ArrayInterface{3,JLArray}()) ===
    ArrayInterface{Any,JLArray}()
  @test interface(ArrayInterface{2,JLArray}(), DefaultArrayInterface{2}()) ===
    DefaultArrayInterface{2}()
  @test interface(ArrayInterface{2,JLArray}(), ArrayInterface{2,Array}()) ===
    DefaultArrayInterface{2}()
  @test interface(DefaultArrayInterface{2}(), ArrayInterface{2,JLArray}()) ===
    DefaultArrayInterface{2}()
  @test interface(ArrayInterface{2,Array}(), ArrayInterface{2,JLArray}()) ===
    DefaultArrayInterface{2}()
  @test interface(ArrayInterface{2,JLArray}(), DefaultArrayInterface{3}()) ===
    DefaultArrayInterface()
  @test interface(ArrayInterface{2,JLArray}(), ArrayInterface{3,Array}()) ===
    DefaultArrayInterface()
  @test interface(DefaultArrayInterface{3}(), ArrayInterface{2,JLArray}()) ===
    DefaultArrayInterface()
  @test interface(ArrayInterface{3,Array}(), ArrayInterface{2,JLArray}()) ===
    DefaultArrayInterface()
  @test interface(jl(randn(2, 2)), jl(randn(2, 2))) === ArrayInterface{2,JLArray}()
  @test interface(jl(randn(2, 2)), jl(randn(2, 2))') === ArrayInterface{2,JLArray}()
  @test interface(jl(randn(2, 2)), jl(randn(2, 2, 2))) === ArrayInterface{Any,JLArray}()
  @test interface(view(jl(randn(2, 2))', 1:2, 1), jl(randn(2))) ===
    ArrayInterface{1,JLArray}()
  @test interface(randn(2, 2), jl(randn(2, 2))) === DefaultArrayInterface{2}()
  @test interface(randn(2, 2), jl(randn(2))) === DefaultArrayInterface()
end
