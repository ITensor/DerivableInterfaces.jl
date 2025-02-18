module DerivableInterfaces

include("interface_function.jl")
include("abstractinterface.jl")
include("derive_macro.jl")
include("interface_macro.jl")
include("wrappedarrays.jl")
include("arrayinterface.jl")

# Specific AbstractArray alternatives
include("concatenate.jl")

end
