using DerivableInterfaces: @interface, DefaultArrayInterface, interface
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
  @test @constinferred(interface(Array)) === DefaultArrayInterface{Any,Array}()
  @test @constinferred(interface(Array{Float32})) === DefaultArrayInterface{Any,Array}()
  @test @constinferred(interface(Matrix)) === DefaultArrayInterface{2,Array}()
  @test @constinferred(interface(Matrix{Float32})) === DefaultArrayInterface{2,Array}()
  @test @constinferred(DefaultArrayInterface()) === DefaultArrayInterface{Any}()
  @test @constinferred(DefaultArrayInterface(Val(2))) === DefaultArrayInterface{2}()
  @test @constinferred(DefaultArrayInterface{Any}(Val(2))) === DefaultArrayInterface{2}()
  @test @constinferred(DefaultArrayInterface{3}(Val(2))) === DefaultArrayInterface{2}()

  # DefaultArrayInterface
  @test @constinferred(interface(AbstractArray)) === DefaultArrayInterface{Any}()
  @test @constinferred(interface(AbstractArray{<:Any,3})) === DefaultArrayInterface{3}()
  @test @constinferred(interface(Array{Float32})) === DefaultArrayInterface{Any,Array}()
  @test @constinferred(interface(Array{Float32,3})) === DefaultArrayInterface{3,Array}()
  @test @constinferred(interface(SubArray{<:Any,<:Any,Array})) ===
    DefaultArrayInterface{Any,Array}()
  @test @constinferred(interface(SubArray{<:Any,<:Any,AbstractArray})) ===
    DefaultArrayInterface{Any}()
  @test @constinferred(interface(SubArray{<:Any,2,Array})) ===
    DefaultArrayInterface{2,Array}()
  @test @constinferred(interface(randn(2, 2))) === DefaultArrayInterface{2,Array}()
  @test @constinferred(interface(view(randn(2, 2), 1:2, 1))) ===
    DefaultArrayInterface{1,Array}()

  # Combining DefaultArrayInterface
  @test @constinferred(interface(DefaultArrayInterface(), DefaultArrayInterface())) ===
    DefaultArrayInterface()
  @test @constinferred(
    interface(DefaultArrayInterface{2}(), DefaultArrayInterface{2}())
  ) === DefaultArrayInterface{2}()
  @test @constinferred(
    interface(DefaultArrayInterface{2}(), DefaultArrayInterface{3}())
  ) === DefaultArrayInterface()
  @test @constinferred(interface(DefaultArrayInterface(), DefaultArrayInterface{3}())) ===
    DefaultArrayInterface()
  @test @constinferred(interface(randn(2, 2), randn(2, 2))) ===
    DefaultArrayInterface{2,Array}()
  @test @constinferred(interface(randn(2, 2), randn(2))) ===
    DefaultArrayInterface{Any,Array}()
  @test @constinferred(interface(randn(2, 2), randn(2, 2)')) ===
    DefaultArrayInterface{2,Array}()
end

@testset "similar(::DefaultArrayInterface, ...)" begin
  a = @constinferred similar(DefaultArrayInterface(), Float32, (2, 2))
  @test typeof(a) === Matrix{Float32}
  @test size(a) == (2, 2)

  a = @constinferred similar(DefaultArrayInterface{Any,Array}(), Float32, (2, 2))
  @test typeof(a) === Matrix{Float32}
  @test size(a) == (2, 2)

  a = @constinferred similar(DefaultArrayInterface{1}(), Float32, (2, 2))
  @test typeof(a) === Matrix{Float32}
  @test size(a) == (2, 2)
end

@testset "Broadcast.DefaultArrayStyle" begin
  @test @constinferred(interface(Broadcast.DefaultArrayStyle)) == DefaultArrayInterface()
  @test @constinferred(interface(Broadcast.DefaultArrayStyle{2})) ==
    DefaultArrayInterface{2}()
  @test @constinferred(
    interface(Broadcast.Broadcasted(nothing, +, (randn(2), randn(2))))
  ) == DefaultArrayInterface{1}()
end

@testset "DefaultArrayInterface with custom array type" begin
  # ArrayInterface
  a = jl(randn(2, 2))
  @test @constinferred(interface(JLArray{Float32})) === DefaultArrayInterface{Any,JLArray}()
  @test @constinferred(interface(SubArray{<:Any,2,JLArray{Float32}})) ===
    DefaultArrayInterface{2,JLArray}()
  @test @constinferred(interface(a)) === DefaultArrayInterface{2,JLArray}()
  @test @constinferred(interface(a')) === DefaultArrayInterface{2,JLArray}()
  @test @constinferred(interface(view(a, 1:2, 1))) === DefaultArrayInterface{1,JLArray}()
  a′ = @constinferred similar(a, Float32, (2, 3, 3))
  @test a′ isa JLArray{Float32,3}
  @test size(a′) == (2, 3, 3)

  # Combining ArrayInterface
  @test @constinferred(
    interface(DefaultArrayInterface{2,JLArray}(), DefaultArrayInterface{2,JLArray}())
  ) === DefaultArrayInterface{2,JLArray}()
  @test @constinferred(
    interface(DefaultArrayInterface{2,JLArray}(), DefaultArrayInterface{3,JLArray}())
  ) === DefaultArrayInterface{Any,JLArray}()
  @test @constinferred(
    interface(DefaultArrayInterface{2,JLArray}(), DefaultArrayInterface{2}())
  ) === DefaultArrayInterface{2}()
  @test @constinferred(
    interface(DefaultArrayInterface{2,JLArray}(), DefaultArrayInterface{2,Array}())
  ) === DefaultArrayInterface{2}()
  @test @constinferred(
    interface(DefaultArrayInterface{2}(), DefaultArrayInterface{2,JLArray}())
  ) === DefaultArrayInterface{2}()
  @test @constinferred(
    interface(DefaultArrayInterface{2,Array}(), DefaultArrayInterface{2,JLArray}())
  ) === DefaultArrayInterface{2}()
  @test @constinferred(
    interface(DefaultArrayInterface{2,JLArray}(), DefaultArrayInterface{3}())
  ) === DefaultArrayInterface()
  @test @constinferred(
    interface(DefaultArrayInterface{2,JLArray}(), DefaultArrayInterface{3,Array}())
  ) === DefaultArrayInterface()
  @test @constinferred(
    interface(DefaultArrayInterface{3}(), DefaultArrayInterface{2,JLArray}())
  ) === DefaultArrayInterface()
  @test @constinferred(
    interface(DefaultArrayInterface{3,Array}(), DefaultArrayInterface{2,JLArray}())
  ) === DefaultArrayInterface()
  @test @constinferred(interface(jl(randn(2, 2)), jl(randn(2, 2)))) ===
    DefaultArrayInterface{2,JLArray}()
  @test @constinferred(interface(jl(randn(2, 2)), jl(randn(2, 2))')) ===
    DefaultArrayInterface{2,JLArray}()
  @test @constinferred(interface(jl(randn(2, 2)), jl(randn(2, 2, 2)))) ===
    DefaultArrayInterface{Any,JLArray}()
  @test @constinferred(interface(view(jl(randn(2, 2))', 1:2, 1), jl(randn(2)))) ===
    DefaultArrayInterface{1,JLArray}()
  @test @constinferred(interface(randn(2, 2), jl(randn(2, 2)))) ===
    DefaultArrayInterface{2}()
  @test @constinferred(interface(randn(2, 2), jl(randn(2)))) === DefaultArrayInterface()
end
