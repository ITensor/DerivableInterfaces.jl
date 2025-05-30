using DerivableInterfaces: zero!
include("SparseArrayDOKs.jl")
using .SparseArrayDOKs: SparseArrayDOK, storedlength
using Test: @test, @testset

elts = (Float32, Float64, Complex{Float32}, Complex{Float64})
@testset "DerivableInterfaces" for elt in elts
  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  @test a isa SparseArrayDOK{elt,2}
  @test size(a) == (2, 2)
  @test a[1, 1] == 0
  @test a[1, 1, 1] == 0
  @test a[1, 2] == 12
  @test a[1, 2, 1] == 12
  @test storedlength(a) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  for b in (similar(a, Float32, (3, 3)), similar(a, Float32, Base.OneTo.((3, 3))))
    @test b isa SparseArrayDOK{Float32,2}
    @test b == zeros(Float32, 3, 3)
    @test size(b) == (3, 3)
  end

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = similar(a)
  bc = Broadcast.Broadcasted(x -> 2x, (a,))
  copyto!(b, bc)
  @test b isa SparseArrayDOK{elt,2}
  @test b == [0 24; 0 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(3, 3, 3)
  a[1, 2, 3] = 123
  b = permutedims(a, (2, 3, 1))
  @test b isa SparseArrayDOK{elt,3}
  @test b[2, 3, 1] == 123
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = copy(a')
  @test b isa SparseArrayDOK{elt,2}
  @test b == [0 0; 12 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = map(x -> 2x, a)
  @test b isa SparseArrayDOK{elt,2}
  @test b == [0 24; 0 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = a * a'
  @test b isa SparseArrayDOK{elt,2}
  @test b == [144 0; 0 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = a .+ 2 .* a'
  @test b isa SparseArrayDOK{elt,2}
  @test b == [0 12; 24 0]
  @test storedlength(b) == 2

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = a[1:2, 2]
  @test b isa SparseArrayDOK{elt,1}
  @test b == [12, 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  @test iszero(a)
  a[2, 1] = 21
  a[1, 2] = 12
  @test !iszero(a)
  @test isreal(a)
  @test sum(a) == 33
  @test mapreduce(x -> 2x, +, a) == 66

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = similar(a)
  copyto!(b, a)
  @test b isa SparseArrayDOK{elt,2}
  @test b == a
  @test b[1, 2] == 12
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a .= 2
  @test storedlength(a) == length(a)
  for I in eachindex(a)
    @test a[I] == 2
  end

  a = SparseArrayDOK{elt}(2, 2)
  fill!(a, 2)
  @test storedlength(a) == length(a)
  for I in eachindex(a)
    @test a[I] == 2
  end

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  zero!(a)
  @test iszero(a)
  @test iszero(storedlength(a))

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = zero(a)
  @test b isa SparseArrayDOK{elt,2}
  @test iszero(b)
  @test iszero(storedlength(b))

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = SparseArrayDOK{elt}(4, 4)
  b[2:3, 2:3] .= a
  @test isone(storedlength(b))
  @test b[2, 3] == 12

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = SparseArrayDOK{elt}(4, 4)
  b[2:3, 2:3] = a
  @test isone(storedlength(b))
  @test b[2, 3] == 12

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = SparseArrayDOK{elt}(4, 4)
  c = @view b[2:3, 2:3]
  c .= a
  @test isone(storedlength(b))
  @test b[2, 3] == 12

  a1 = SparseArrayDOK{elt}(2, 2)
  a1[1, 2] = 12
  a2 = SparseArrayDOK{elt}(2, 2)
  a2[2, 1] = 21
  b = cat(a1, a2; dims=(1, 2))
  @test b isa SparseArrayDOK{elt,2}
  @test storedlength(b) == 2
  @test b[1, 2] == 12
  @test b[4, 3] == 21
end
