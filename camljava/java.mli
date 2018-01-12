(** Interfaces Java
	Unsafe *)

(** Represent a java object
	Does not support hash and marshalling *)
type obj

(** The null value *)
val null : obj

(** Methods and fields
	There is a type for each type of method/field
	meth				Member method
	meth_static			Static method
	meth_constructor	Object constructor
	field				Object attribute
	field_static		Static field *)
type meth
type meth_static
type meth_constructor
type field
type field_static

(** Raised when a java exception is thrown
	The parameter is the java Exception *)
exception Exception of obj

(** Initialize the JVM
	Takes the JVM options as parameter *)
val init : string array -> unit

module Class : sig

	(** A Java class *)
	type t

	(** `find_class s` returns the class named `s`
		Raises `Not_found` if the class does not exists *)
	external find_class : string -> t = "ocaml_java__find_class"

	(** `get_meth cls name sgt` returns the method
			named `name` with signature `sgt`
		Raises `Not_found` if the method does not exists with this signature *)
	external get_meth : t -> string -> string -> meth
		= "ocaml_java__class_get_meth"

	(** Same as `get_meth`, for static methods *)
	external get_meth_static : t -> string -> string -> meth_static
		= "ocaml_java__class_get_meth_static"

	(** Same as `get_meth`, for object constructor *)
	external get_constructor : t -> string -> meth_constructor
		= "ocaml_java__class_get_constructor"

	(** `get_field cls name sgt` returns the field named `name`
			with signature `sgt`
		Raises `Not_found` if the field does not exists with this signature *)
	external get_field : t -> string -> string -> field
		= "ocaml_java__class_get_field"

	(** Same as `get_field`, for static fields *)
	external get_field_static : t -> string -> string -> field_static
		= "ocaml_java__class_get_field_static"

end

(** Calling a function
	-
	Begins the calling of a function with a call to one of:
		- `meth obj meth`
		- `meth_static class_ meth`
		- `meth_nonvirtual obj class_ meth`
		- `new_ class_ init`
	-
	Push arguments using the `arg_`* functions
	-
	| Function		| OCaml type	| Java type
	| ---			| ---			| ---
	| arg_int		| int			| int
	| arg_float		| float			| float
	| arg_double	| float			| double
	| arg_string	| string		| String
	| arg_bool		| bool			| boolean
	| arg_char		| char			| char
	| arg_byte		| int			| byte
	| arg_short		| int			| short
	| arg_int32		| int32			| int
	| arg_int64		| int64			| long
	| arg_obj		| Java.obj		| Object
	-
	Call the function and get the result with the `call_`* functions *)

(** Begins the calling of a method
	Raises `Invalid_argument` if `object` is null *)
external meth : obj -> meth -> unit = "ocaml_java__calling_meth"

(** Same as `meth` for static methods *)
external meth_static : Class.t -> meth_static -> unit
	= "ocaml_java__calling_meth_static"

(** Same as `meth` for non-virtual call
	Call the method of a specific class instead of the class of the object *)
external meth_nonvirtual : obj -> Class.t -> meth -> unit
	= "ocaml_java__calling_meth_nonvirtual"

(** Begin the calling of an object constructor
	Must be called with `call_obj` to retrieve the object *)
external new_ : Class.t -> meth_constructor -> unit
	= "ocaml_java__calling_init"

(** Accessing a field
	-
	Begins the accessing of a field with a call to one of:
		- `field obj field`
		- `field_static class_ field`
	-
	Get the value with the `call_`* functions *)

(** Begin the accessing of a field
	Raises `Invalid_argument` if `object` is null *)
external field : obj -> field -> unit = "ocaml_java__calling_field"

(** Same as `field`, for static field *)
external field_static : Class.t -> field_static -> unit
	= "ocaml_java__calling_field_static"

(** Adds an argument on the stack *)
external arg_int : int -> unit = "ocaml_java__arg_int"
external arg_float : float -> unit = "ocaml_java__arg_float"
external arg_double : float -> unit = "ocaml_java__arg_double"
external arg_string : string -> unit = "ocaml_java__arg_string"
external arg_bool : bool -> unit = "ocaml_java__arg_bool"
external arg_char : char -> unit = "ocaml_java__arg_char"
external arg_int8 : int -> unit = "ocaml_java__arg_int8"
external arg_int16 : int -> unit = "ocaml_java__arg_int16"
external arg_int32 : int32 -> unit = "ocaml_java__arg_int32"
external arg_int64 : int64 -> unit = "ocaml_java__arg_int64"
external arg_obj : obj -> unit = "ocaml_java__arg_obj"

(** Calls the function and returns the result
	Same convertion as for the `arg_` functions *)
external call_unit : unit -> unit = "ocaml_java__call_unit"
external call_int : unit -> int = "ocaml_java__call_int"
external call_float : unit -> float = "ocaml_java__call_float"
external call_double : unit -> float = "ocaml_java__call_double"

(** Raises `Failure` if the string is null *)
external call_string : unit -> string = "ocaml_java__call_string"
external call_bool : unit -> bool = "ocaml_java__call_bool"
external call_char : unit -> char = "ocaml_java__call_char"
external call_int8 : unit -> int = "ocaml_java__call_int8"
external call_int16 : unit -> int = "ocaml_java__call_int16"
external call_int32 : unit -> int32 = "ocaml_java__call_int32"
external call_int64 : unit -> int64 = "ocaml_java__call_int64"
external call_obj : unit -> obj = "ocaml_java__call_obj"
