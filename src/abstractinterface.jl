# TODO: if we stick to the broadcasting design pattern, it would be:
# AbstractInterface(s) to obtain the interface, and AbstractInterface(::AbstractInterface...)
# to combine them.
# Finally, combine_interfaces(x...) would then operate on values (i.e. not on interfaces)

"""
    abstract type AbstractInterface

Supertype for all interface traits.
"""
abstract type AbstractInterface end

"""
    UnknownInterface <: AbstractInterface

Singleton type to represent an undefined combination of interface types.
"""
struct UnknownInterface <: AbstractInterface end
# TODO: if this is the result, we should probably error somewhere

"""
    interface(x...)

Return the (combined) interface of the input objects.
By default, this function is defined in the type domain, so new types `T` should be
registered by implementing `interface(::Type{T}) where {T}`.

See also [`combine_interface_rule`](@ref) in order to define interface precedence rules.
"""
interface(x) = interface(typeof(x))
interface(T::Type) = throw(MethodError(f, (T,)))
interface(x1, x_rest...) = combine_interfaces(x1, x_rest...)

# TODO: do we need to have both `interface` and `combine_interfaces` to mean the same thing?

# Adapted from `Base.Broadcast.combine_styles`.
# Get the combined interfaces of the input objects.
function combine_interfaces(x1, x2, x_rest...)
  return combine_interfaces(combine_interfaces(x1, x2), x_rest...)
end
combine_interfaces(x1, x2) = combine_interface_rule(interface(x1), interface(x2))
combine_interfaces(x) = interface(x)

# Rules for combining interfaces.
"""
    combine_interface_rule(x::AbstractInterface, y::AbstractInterface)

Determine interface precedence rules for `x` and `y`. Users should typically only
define a single argument order.
"""
combine_interface_rule(x::Interface, ::Interface) where {Interface<:AbstractInterface} = x
combine_interface_rule(::AbstractInterface, ::AbstractInterface) = UnknownInterface()

"""
    (interface::AbstractInterface)(f)

Return a callable that overdubs the function `f` to make use of `interface`.
"""
(interface::AbstractInterface)(f) = InterfaceFunction(interface, f)
