# Ppx

Allows to make short and safe interface to Java classes

Java classes are declared using a syntax similar to OCaml's classes.
The types are written in readable way and class and method names are written once.

Since there could be a lot of classes with a lot of methods,
class, method and field handles are queried lazily to avoid possibly huge startup latency.

### Class declaration

```ocaml
class%java class_name "java.class.Name" =
object
	(* methods, fields and constructors here *)
end
```

`class_name` must be lower-case.
`"java.class.Name"` is the Java class name (with full path)

This example generates a module named `Class_name` with this signature:

```ocaml
(* generated *)
module Class_name :
sig
	type t
	val of_obj : 'a Java.obj -> t
	(* methods, fields and constructors will be generated here *)
end
```

The first character of the name is converted to upper-case.

### Methods

```ocaml
...
	method meth_name : type = "javaMethName"

	method overloaded_int : int -> unit = "overloaded"
	method overloaded_long : long -> unit = "overloaded"
	method overloaded_string : string -> unit = "overloaded"
...
```

`"javaMethName"` is the name of the corresponding Java method.

Method types does not use defined OCaml types, see [Types](#Types) below.

Overloading is not supported in OCaml, overloaded methods must have different names.

This example generates:

```ocaml
...
	(* generated *)
	val meth_name : t -> type
	val overloaded_int : t -> int -> unit
	val overloaded_long : t -> Int64.t -> unit
	val overloaded_string : t -> string -> unit
...
```

The functions type are converted (see [Types](#Types) below)
and an extra first argument is added for the object

### Fields

```ocaml
...
	val field_name : type = "field"
	val mutable mutable_field : type = "mutableField"
...
```

The `mutable` keyword must be used to be able to change the value from OCaml

This example generates:

```ocaml
...
	(* generated *)
	val get'field_name : t -> type
	val get'mutable_field : t -> type
	val set'mutable_field : t -> type -> unit
...
```

The fields type are converted (see [Types](#Types) below)
and getter/setter functions are generated

### Static methods and fields

```ocaml
...
	method [@static] static_meth : int -> int = "staticMeth"
	method [@static] static_meth_without_arg : int = "staticMeth"
	val [@static] mutable static_field : type = "staticField"
...
```

Static methods and fields are defined with the `[@static]` attribute.

This example generates:

```ocaml
...
	(* generated *)
	val static_meth : int -> int
	val static_meth_without_arg : unit -> int
	val get'static_field : unit -> type
	val set'static_field : type -> unit
...
```

An `unit` argument is added to static method without argument.

### Constructors

```ocaml
...
	initializer (constructor_name : _)
	initializer (with_argument : int -> _)
...
```

This example generates:

```ocaml
...
	(* generated *)
	val constructor_name : unit -> t
	val with_argument : int -> t
...
```

### Types

Methods and fields types are not defined OCaml,
but instead are converted using the following table:

| Ppx type	| Real OCaml type	| Java type	|
| ---	| ---	| ---	|
| int	| int	| int	|
| bool	| bool	| bool	|
| byte	| int	| byte	|
| short	| int	| short	|
| int32	| Int32.t	| int	|
| long	| Int64.t	| long	|
| char	| char	| char	|
| float	| float	| float	|
| double	| float	| double	|
| string	| string	| String	|
| string option	| string option	| String	|
| 'a Java.obj	| 'a Java.obj	| Object	|
| runnable	| Jrunnable.t	| Runnable	|
| runnable option	| Jrunnable.t option	| Runnable	|
| char_sequence	| string	| CharSequence	|
| char_sequence option	| char_sequence option	| CharSequence	|
| 'a value	| 'a	| Value	|
| 'a value option	| 'a option	| Value	|
| 'a array	| `converted 'a` Jarray.t	| `converted 'a`[]	|
| 'a array option	| `converted 'a` Jarray.t option	| `converted 'a`[]	|
| `class_name`	| Class_name.t	| java.class.Name	|
| unit (return type only)	| unit	| void	|

Array types are converted using the same rules with some exceptions:
`byte`, `short`, `double` and `'a value` uses custom Jarray types
and `'a option` is not supported.
