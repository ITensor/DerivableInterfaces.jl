# Get the interface of an object.
interface(x) = interface(typeof(x))
# TODO: Define as `DefaultInterface()`.
interface(::Type) = error("Interface unknown.")
interface(x1, x_rest...) = combine_interfaces(interface(x1), interface.(x_rest)...)

# Adapted from `Base.Broadcast.combine_styles`.
# Get the combined interfaces of the input objects.
function combine_interfaces(inter1, inter2, inter_rest...)
  return combine_interfaces(combine_interfaces(inter1, inter2), inter_rest...)
end
combine_interfaces(inter1, inter2) = combine_interface_rule(inter1, inter2)
combine_interfaces(inter) = interface(inter)

# Rules for combining interfaces.
function combine_interface_rule(
  inter1::Interface, inter2::Interface
) where {Interface}
  return inter1
end
# TODO: Define as `UnknownInterface()`.
combine_interface_rule(inter1, inter2) = error("No rule for combining interfaces.")

abstract type AbstractInterface end

(interface::AbstractInterface)(f) = InterfaceFunction(interface, f)
