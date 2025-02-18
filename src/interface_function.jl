# noinline trick to make compiler avoid allocating a string
@noinline _warn_no_impl(interface, f, args) =
  "The function `$f` does not have a `$interface` implementation for arguments of type `$(typeof(args))`"

"""
     call(interface, f, args...; kwargs...)

Call the overdubbed function implementing `f(args...; kwargs...)` for a given interface.

See also [`@interface`](@ref).
"""
function call(interface, f, args...; kwargs...)
  @warn _warn_no_impl(interface, f, args) maxlog = 1
  return f(args...; kwargs...)
end

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
