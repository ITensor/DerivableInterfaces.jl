using Test: @test, @testset, @test_throws
using DerivableInterfaces: DerivableInterfaces as DI
using DerivableInterfaces: @derive, @interface

# Test setup
# ----------
struct MyArray{T,N} <: AbstractArray{T,N}
  parent::Array{T,N}
end
Base.parent(A::MyArray) = A.parent

@derive (T=MyArray,) Base.getindex(::T, ::Int)

# Interfacetype
struct MyInterface{N} <: DI.AbstractArrayInterface{N} end
DI.interface(::Type{A}) where {A<:MyArray} = MyInterface{ndims(A)}()

const f_ctr = Ref(0) # used to verify if function was actually called
@interface ::MyInterface function Base.getindex(A::MyArray, i::Int)
  f_ctr[] += 1
  return getindex(parent(A), i)
end
@interface ::MyInterface function Base.getindex(A::AbstractArray, i::Int)
  f_ctr[] += 1
  return getindex(A::AbstractArray, i::Int)
end

f(A, B) = -1
for N in 1:3
  @eval @interface ::MyInterface{$N} f(A, B) = $N
end
@derive (T=AbstractArray,) f(::T, ::T)

# Tests
# -----
# TODO: test type stability
@testset "@derived types" begin
  ctr = f_ctr[]
  A = rand(Int, 3)
  B = MyArray(A)
  @test A[1] == B[1]
  @test f_ctr[] == ctr + 1
end

@testset "using @interface functions for non-derived types" begin
  ctr = f_ctr[]
  A = zeros(Int, 3)
  @test A[1] == @interface MyInterface{1}() A[1]
  @test f_ctr[] == ctr + 1
end

@testset "interface promotion rules" begin
  # DefaultArrayInterface should give default
  @test f(zeros(1), zeros(1)) == -1
  @test f(zeros(1), zeros(1, 1)) == -1
  # MyInterface
  @test f(MyArray(zeros(1)), MyArray(zeros(1))) == 1
  @test f(MyArray(zeros(1, 1)), MyArray(zeros(1, 1))) == 2
  # Mix
  @test f(MyArray(zeros(1)), zeros(1)) == 1
  @test f(zeros(1), MyArray(zeros(1))) == 1
  # undefined mix
  @test f((1,), zeros(1)) == 1
end
