using ExproniconLite: JLFunction, codegen_ast, split_function, split_function_head
using MLStyle: @match

macro interface(expr...)
  return esc(interface_expr(expr...))
end

# TODO: Use `MLStyle.@match`/`Moshi.@match`.
# f(args...)
iscallexpr(expr) = Meta.isexpr(expr, :call)
# a[I...]
isrefexpr(expr) = Meta.isexpr(expr, :ref)
# a[I...] = value
issetrefexpr(expr) = Meta.isexpr(expr, :(=)) && isrefexpr(expr.args[1])

function interface_expr(interface::Union{Symbol,Expr}, func::Expr)
  # TODO: Use `MLStyle.@match`/`Moshi.@match`.
  # f(args...)
  iscallexpr(func) && return interface_call(interface, func)
  # a[I...]
  isrefexpr(func) && return interface_ref(interface, func)
  # a[I...] = value
  issetrefexpr(func) && return interface_setref(interface, func)
  # Assume it is a function definition.
  return interface_definition(interface, func)
end

#=
Rewrite:
```julia
@interface SparseArrayInterface() Base.getindex(a, I...)
```
or:
```julia
@interface SparseArrayInterface() a[I...]
```
to:
```julia
DerivableInterfaces.call(SparseArrayInterface(), Base.getindex, a, I...)
```
=#
function interface_call(interface::Union{Symbol,Expr}, func::Expr)
  return @match func begin
    :($name($(args...))) =>
      :($(GlobalRef(DerivableInterfaces, :InterfaceFunction))($interface, $name)(
        $(args...)
      ))
    :($name($(args...); $(kwargs...))) =>
      :($(GlobalRef(DerivableInterfaces, :InterfaceFunction))($interface, $name)(
        $(args...); $(kwargs...)
      ))
  end
end

#=
Rewrite:
```julia
@interface SparseArrayInterface() a[I...]
```
to:
```julia
DerivableInterfaces.call(SparseArrayInterface(), Base.getindex, a, I...)
```
=#
function interface_ref(interface::Union{Symbol,Expr}, func::Expr)
  func = @match func begin
    :($a[$(I...)]) => :(Base.getindex($a, $(I...)))
  end
  return interface_call(interface, func)
end

#=
Rewrite:
```julia
@interface SparseArrayInterface() a[I...] = value
```
to:
```julia
DerivableInterfaces.call(SparseArrayInterface(), Base.setindex!, a, value, I...)
```
=#
function interface_setref(interface::Union{Symbol,Expr}, func::Expr)
  return @match func begin
    :($a[$(I...)] = $value) => Expr(
      :block, interface_call(interface, :(Base.setindex!($a, $value, $(I...)))), :($value)
    )
  end
end

#=
Rewrite:
```julia
@interface interface::SparseArrayInterface function Base.getindex(a, I::Int...)
  !isstored(a, I...) && return getunstoredindex(a, I...)
  return getstoredindex(a, I...)
end
```
to:
```julia
function DerivableInterfaces.call(interface::SparseArrayInterface, Base.getindex, a, I::Int...)
  !isstored(a, I...) && return getunstoredindex(a, I...)
  return getstoredindex(a, I...)
end
```
=#
function interface_definition(interface::Union{Symbol,Expr}, func::Expr)
  head, call, body = split_function(func)
  name, args, kwargs, whereparams, rettype = split_function_head(call)
  new_name = :(DerivableInterfaces.call)
  # We use `Core.Typeof` here because `name` can either be a function or type,
  # and `typeof(T::Type)` outputs things like `DataType`, `UnionAll`, etc.
  # while `Core.Typeof(T::Type)` returns `Type{T}`.
  new_args = [:($interface); :(::Core.Typeof($name)); args]
  return globalref_derive(
    codegen_ast(
      JLFunction(; name=new_name, args=new_args, kwargs, rettype, whereparams, body)
    ),
  )
end
