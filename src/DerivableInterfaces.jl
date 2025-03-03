module DerivableInterfaces

include("interface_function.jl")
include("abstractinterface.jl")
include("derive_macro.jl")
include("interface_macro.jl")
include("wrappedarrays.jl")
include("abstractarrayinterface.jl")
include("defaultarrayinterface.jl")
include("traits.jl")

# Specific AbstractArray alternatives and additions
include("zero.jl")
include("concatenate.jl")

end
