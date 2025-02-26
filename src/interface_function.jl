"""
     call(interface, f, args...; kwargs...)

Call the overdubbed function implementing `f(args...; kwargs...)` for a given interface.

See also [`@interface`](@ref).
"""
call(interface, f, args...; kwargs...) = throw(MethodError(interface(f), args))
# TODO: do we want to methoderror for `call` instead?

"""
    struct InterfaceFunction{I,F} <: Function

Callable struct to overdub a function `f::F` with a custom implementation based on
an interface `interface::I`.

## Fields

- `interface::I`: interface struct
- `f::F`: function to overdub
"""
struct InterfaceFunction{Interface,F} <: Function
  interface::Interface
  f::F
end
(f::InterfaceFunction)(args...; kwargs...) = call(f.interface, f.f, args...; kwargs...)
