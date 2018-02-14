(** Interfaces Java
	Unsafe *)

(** Represent a java object
	Does not support hash and marshalling *)
type obj

(** Java array
	See the `Jarray` module *)
type 'a jarray

(* Java class
	See the `Jclass` module *)
type jclass

(* Java throwable objects *)
type jthrowable

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
exception Exception of jthrowable

(** Initialize the JVM
	Takes the JVM options as parameter *)
val init : string array -> unit

(** The null value *)
val null : obj

(** `instanceof o cls`
	Returns `true` if `o` is an instance of the class `cls`
	and is not `null`
	or `false` otherwise *)
external instanceof : obj -> jclass -> bool
	= "ocaml_java__instanceof" [@@noalloc]

(** `sameobject a b`
	Returns `true` if `a` and `b` refer to the same object or false otherwise
	Not the same as `(=)` because `(=)` only compare references
	while many difference references may point to the same object
	(eg. global or weak references) *)
external sameobject : obj -> obj -> bool
	= "ocaml_java__sameobject" [@@noalloc]

(** Returns the class of an object
	Raises `Failure` if the object is `null` *)
val objectclass : obj -> jclass

(** Instantiate a new object
	Assume enough argument are in the calling stack (see `push`)
	Raises `Exception` if the constructor thrown a Java exception
	May crash for the same reason as `call` *)
val new_ : jclass -> meth_constructor -> obj

(** Convertions
	-
	| Java type			| OCaml type
	| ---				| ---
	| int				| int
	| boolean			| bool
	| byte				| int (truncated)
	| short				| int (truncated)
	| int				| Int32.t
	| long				| Int64.t
	| char				| char
	| float				| float
	| double			| float
	| String (non-null)	| string
	| String			| string option
	| Object			| Java.obj
	| Value (non-null)	| 'a
	| Value				| 'a option
	| *[] (non-null)	| 'a jarray
	| *[]				| 'a jarray option *)

(** Adds an argument on the calling stack *)
external push_int : int -> unit = "ocaml_java__push_int" [@@noalloc]
external push_bool : bool -> unit = "ocaml_java__push_bool" [@@noalloc]
external push_byte : int -> unit = "ocaml_java__push_byte" [@@noalloc]
external push_short : int -> unit = "ocaml_java__push_short" [@@noalloc]
external push_int32 : int32 -> unit = "ocaml_java__push_int32" [@@noalloc]
external push_long : int64 -> unit = "ocaml_java__push_long" [@@noalloc]
external push_char : char -> unit = "ocaml_java__push_char" [@@noalloc]
external push_float : (float [@unboxed]) -> unit
	= "ocaml_java__push_float" "ocaml_java__push_float_unboxed" [@@noalloc]
external push_double : (float [@unboxed]) -> unit
	= "ocaml_java__push_double" "ocaml_java__push_double_unboxed" [@@noalloc]
external push_string : string -> unit = "ocaml_java__push_string" [@@noalloc]
external push_string_opt : string option -> unit
	= "ocaml_java__push_string_opt" [@@noalloc]
external push_object : obj -> unit = "ocaml_java__push_object" [@@noalloc]
external push_value : 'a -> unit = "ocaml_java__push_value" [@@noalloc]
external push_value_opt : 'a option -> unit
	= "ocaml_java__push_value_opt" [@@noalloc]
external push_array : 'a jarray -> unit = "ocaml_java__push_array" [@@noalloc]
external push_array_opt : 'a jarray option -> unit
	= "ocaml_java__push_array_opt" [@@noalloc]

(** Perform a call
	Assume enough argument are in the calling stack (see `push`)
	Raises `Failure` if the object is null
	Raises `Exception` if the method throws a Java exception
	May crash if some argument are missing or have the wrong representation *)
val call_void : obj -> meth -> unit
val call_int : obj -> meth -> int
val call_bool : obj -> meth -> bool
val call_byte : obj -> meth -> int
val call_short : obj -> meth -> int
val call_int32 : obj -> meth -> int32
val call_long : obj -> meth -> int64
val call_char : obj -> meth -> char
val call_float : obj -> meth -> float
val call_double : obj -> meth -> float
(** Raises `Failure` if the result is null *)
val call_string : obj -> meth -> string
val call_string_opt : obj -> meth -> string option
val call_object : obj -> meth -> obj
(** Raises `Failure` if the result is null *)
val call_value : obj -> meth -> 'a
val call_value_opt : obj -> meth -> 'a option
val call_array : obj -> meth -> 'a jarray
val call_array_opt : obj -> meth -> 'a jarray option

(** Same as `call`, for static methods *)
val call_static_void : jclass -> meth_static -> unit
val call_static_int : jclass -> meth_static -> int
val call_static_bool : jclass -> meth_static -> bool
val call_static_byte : jclass -> meth_static -> int
val call_static_short : jclass -> meth_static -> int
val call_static_int32 : jclass -> meth_static -> int32
val call_static_long : jclass -> meth_static -> int64
val call_static_char : jclass -> meth_static -> char
val call_static_float : jclass -> meth_static -> float
val call_static_double : jclass -> meth_static -> float
val call_static_string : jclass -> meth_static -> string
val call_static_string_opt : jclass -> meth_static -> string option
val call_static_object : jclass -> meth_static -> obj
val call_static_value : jclass -> meth_static -> 'a
val call_static_value_opt : jclass -> meth_static -> 'a option
val call_static_array : jclass -> meth_static -> 'a jarray
val call_static_array_opt : jclass -> meth_static -> 'a jarray option

(** Same as `call`, for non-virtual call
	Call the method of a specific class instead of the class of the object *)
val call_nonvirtual_void : obj -> jclass -> meth -> unit
val call_nonvirtual_int : obj -> jclass -> meth -> int
val call_nonvirtual_bool : obj -> jclass -> meth -> bool
val call_nonvirtual_byte : obj -> jclass -> meth -> int
val call_nonvirtual_short : obj -> jclass -> meth -> int
val call_nonvirtual_int32 : obj -> jclass -> meth -> int32
val call_nonvirtual_long : obj -> jclass -> meth -> int64
val call_nonvirtual_char : obj -> jclass -> meth -> char
val call_nonvirtual_float : obj -> jclass -> meth -> float
val call_nonvirtual_double : obj -> jclass -> meth -> float
val call_nonvirtual_string : obj -> jclass -> meth -> string
val call_nonvirtual_string_opt : obj -> jclass -> meth -> string option
val call_nonvirtual_object : obj -> jclass -> meth -> obj
val call_nonvirtual_value : obj -> jclass -> meth -> 'a
val call_nonvirtual_value_opt : obj -> jclass -> meth -> 'a option
val call_nonvirtual_array : obj -> jclass -> meth -> 'a jarray
val call_nonvirtual_array_opt : obj -> jclass -> meth -> 'a jarray option

(** Read the value of a field
	May crash if the representation is incorrect *)
val read_field_int : obj -> field -> int
val read_field_bool : obj -> field -> bool
val read_field_byte : obj -> field -> int
val read_field_short : obj -> field -> int
val read_field_int32 : obj -> field -> int32
val read_field_long : obj -> field -> int64
val read_field_char : obj -> field -> char
val read_field_float : obj -> field -> float
val read_field_double : obj -> field -> float
(** Raises `Failure` if the value is `null` *)
val read_field_string : obj -> field -> string
val read_field_string_opt : obj -> field -> string option
val read_field_object : obj -> field -> obj
(** Raises `Failure` if the value is `null` *)
val read_field_value : obj -> field -> 'a
val read_field_value_opt : obj -> field -> 'a option
val read_field_array : obj -> field -> 'a jarray
val read_field_array_opt : obj -> field -> 'a jarray option

(** Same as `read_field`, for static fields *)
val read_field_static_int : jclass -> field_static -> int
val read_field_static_bool : jclass -> field_static -> bool
val read_field_static_byte : jclass -> field_static -> int
val read_field_static_short : jclass -> field_static -> int
val read_field_static_int32 : jclass -> field_static -> int32
val read_field_static_long : jclass -> field_static -> int64
val read_field_static_char : jclass -> field_static -> char
val read_field_static_float : jclass -> field_static -> float
val read_field_static_double : jclass -> field_static -> float
(** Raises `Failure` if the value is `null` *)
val read_field_static_string : jclass -> field_static -> string
val read_field_static_string_opt : jclass -> field_static -> string option
val read_field_static_object : jclass -> field_static -> obj
(** Raises `Failure` if the value is `null` *)
val read_field_static_value : jclass -> field_static -> 'a
val read_field_static_value_opt : jclass -> field_static -> 'a option
val read_field_static_array : jclass -> field_static -> 'a jarray
val read_field_static_array_opt : jclass -> field_static -> 'a jarray option

(** Write to a field *)
val write_field_int : obj -> field -> int -> unit
val write_field_bool : obj -> field -> bool -> unit
val write_field_byte : obj -> field -> int -> unit
val write_field_short : obj -> field -> int -> unit
val write_field_int32 : obj -> field -> int32 -> unit
val write_field_long : obj -> field -> int64 -> unit
val write_field_char : obj -> field -> char -> unit
val write_field_float : obj -> field -> float -> unit
val write_field_double : obj -> field -> float -> unit
val write_field_string : obj -> field -> string -> unit
val write_field_string_opt : obj -> field -> string option -> unit
val write_field_object : obj -> field -> obj -> unit
val write_field_value : obj -> field -> 'a -> unit
val write_field_value_opt : obj -> field -> 'a option -> unit
val write_field_array : obj -> field -> 'a jarray -> unit
val write_field_array_opt : obj -> field -> 'a jarray option -> unit

(** Same as `write_field`, for static fields *)
val write_field_static_int : jclass -> field_static -> int -> unit
val write_field_static_bool : jclass -> field_static -> bool -> unit
val write_field_static_byte : jclass -> field_static -> int -> unit
val write_field_static_short : jclass -> field_static -> int -> unit
val write_field_static_int32 : jclass -> field_static -> int32 -> unit
val write_field_static_long : jclass -> field_static -> int64 -> unit
val write_field_static_char : jclass -> field_static -> char -> unit
val write_field_static_float : jclass -> field_static -> float -> unit
val write_field_static_double : jclass -> field_static -> float -> unit
val write_field_static_string : jclass -> field_static -> string -> unit
val write_field_static_string_opt : jclass -> field_static -> string option -> unit
val write_field_static_object : jclass -> field_static -> obj -> unit
val write_field_static_value : jclass -> field_static -> 'a -> unit
val write_field_static_value_opt : jclass -> field_static -> 'a option -> unit
val write_field_static_array : jclass -> field_static -> 'a jarray -> unit
val write_field_static_array_opt : jclass -> field_static -> 'a jarray option -> unit
