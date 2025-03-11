"""
    zero!(x::AbstractArray)

In-place version of `Base.zero`.
"""
function zero! end

@derive (T=AbstractArray,) begin
  DerivableInterfaces.zero!(::T)
end
