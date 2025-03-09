module DerivableInterfaces

export Concatenate

include("interface_function.jl")
include("abstractinterface.jl")
include("derive_macro.jl")
include("interface_macro.jl")
include("wrappedarrays.jl")

include("zero.jl")
include("abstractarrayinterface.jl")
include("concatenate.jl")
include("defaultarrayinterface.jl")
include("traits.jl")

end
