# Get the interface of an object.
interface(x) = interface(typeof(x))
# TODO: Define as `DefaultInterface()`.
interface(::Type) = error("Interface unknown.")
interface(x1, x_rest...) = combine_interfaces(interface(x1), interface.(x_rest)...)

abstract type AbstractInterface end

interface(x::AbstractInterface) = x

(interface::AbstractInterface)(f) = InterfaceFunction(interface, f)

# Adapted from `Base.Broadcast.combine_styles`.
# Get the combined interfaces of the input objects.
function combine_interfaces(
  inter1::AbstractInterface, inter2::AbstractInterface, inter_rest::AbstractInterface...
)
  return combine_interfaces(combine_interface_rule(inter1, inter2), inter_rest...)
end
function combine_interfaces(inter1::AbstractInterface, inter2::AbstractInterface)
  return combine_interface_rule(inter1, inter2)
end
combine_interfaces(inter::AbstractInterface) = inter

# Rules for combining interfaces.
function combine_interface_rule(
  inter1::Interface, inter2::Interface
) where {Interface<:AbstractInterface}
  return inter1
end
# TODO: Define as `UnknownInterface()`.
function combine_interface_rule(inter1::AbstractInterface, inter2::AbstractInterface)
  return error("No rule for combining interfaces.")
end
