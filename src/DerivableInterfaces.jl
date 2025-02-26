module DerivableInterfaces

export @derive, @interface
export interface, AbstractInterface, AbstractArrayInterface
export zero!

include("interface_function.jl")
include("abstractinterface.jl")
include("derive_macro.jl")
include("interface_macro.jl")
include("wrappedarrays.jl")
include("arrayinterface.jl")

# Specific AbstractArray alternatives

include("concatenate.jl")
include("zero.jl")

end
