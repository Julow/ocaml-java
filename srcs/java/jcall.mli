(** Unsafe interface for calling Java methods
	-
	The procedure to call a Java method is:
		- Query the class handle with Jclass.find_class
		- Query the method handle with Jclass.get_meth
		- Push the arguments with the push_ functions
		- Finally call the method with one of the call_ functions
	-
	Convertions:
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
	| String (non-null)	| string (encoding: UTF-8)
	| String			| string option
	| Object			| Java.obj
	| Value (non-null)	| 'a
	| Value				| 'a option
	| *[] (non-null)	| 'a jarray
	| *[]				| 'a jarray option *)

open Java
open Jclass

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
external push_object : 'a obj -> unit = "ocaml_java__push_object" [@@noalloc]
external push_value : 'a -> unit = "ocaml_java__push_value" [@@noalloc]
external push_value_opt : 'a option -> unit
	= "ocaml_java__push_value_opt" [@@noalloc]
external push_array : 'a jarray -> unit = "ocaml_java__push_array" [@@noalloc]
external push_array_opt : 'a jarray option -> unit
	= "ocaml_java__push_array_opt" [@@noalloc]

(** Instantiate a new object
	Assume enough argument are in the calling stack (see `push`)
	Raises `Exception` if the constructor thrown a Java exception
	May crash for the same reason as `call` *)
val new_ : jclass -> meth_constructor -> 'a obj

(** Perform a call
	Assume enough argument are in the calling stack (see `push`)
	Raises `Failure` if the object is null
	Raises `Exception` if the method throws a Java exception
	May crash if some argument are missing or have the wrong representation *)
val call_void : 'a obj -> meth -> unit
val call_int : 'a obj -> meth -> int
val call_bool : 'a obj -> meth -> bool
val call_byte : 'a obj -> meth -> int
val call_short : 'a obj -> meth -> int
val call_int32 : 'a obj -> meth -> int32
val call_long : 'a obj -> meth -> int64
val call_char : 'a obj -> meth -> char
val call_float : 'a obj -> meth -> float
val call_double : 'a obj -> meth -> float
(** Raises `Failure` if the result is null *)
val call_string : 'a obj -> meth -> string
val call_string_opt : 'a obj -> meth -> string option
val call_object : 'a obj -> meth -> 'b obj
(** Raises `Failure` if the result is null *)
val call_value : 'a obj -> meth -> 'b
val call_value_opt : 'a obj -> meth -> 'b option
val call_array : 'a obj -> meth -> 'b jarray
val call_array_opt : 'a obj -> meth -> 'b jarray option

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
val call_static_object : jclass -> meth_static -> 'a obj
val call_static_value : jclass -> meth_static -> 'a
val call_static_value_opt : jclass -> meth_static -> 'a option
val call_static_array : jclass -> meth_static -> 'a jarray
val call_static_array_opt : jclass -> meth_static -> 'a jarray option

(** Same as `call`, for non-virtual call
	Call the method of a specific class instead of the class of the object *)
val call_nonvirtual_void : 'a obj -> jclass -> meth -> unit
val call_nonvirtual_int : 'a obj -> jclass -> meth -> int
val call_nonvirtual_bool : 'a obj -> jclass -> meth -> bool
val call_nonvirtual_byte : 'a obj -> jclass -> meth -> int
val call_nonvirtual_short : 'a obj -> jclass -> meth -> int
val call_nonvirtual_int32 : 'a obj -> jclass -> meth -> int32
val call_nonvirtual_long : 'a obj -> jclass -> meth -> int64
val call_nonvirtual_char : 'a obj -> jclass -> meth -> char
val call_nonvirtual_float : 'a obj -> jclass -> meth -> float
val call_nonvirtual_double : 'a obj -> jclass -> meth -> float
val call_nonvirtual_string : 'a obj -> jclass -> meth -> string
val call_nonvirtual_string_opt : 'a obj -> jclass -> meth -> string option
val call_nonvirtual_object : 'a obj -> jclass -> meth -> 'b obj
val call_nonvirtual_value : 'a obj -> jclass -> meth -> 'b
val call_nonvirtual_value_opt : 'a obj -> jclass -> meth -> 'b option
val call_nonvirtual_array : 'a obj -> jclass -> meth -> 'b jarray
val call_nonvirtual_array_opt : 'a obj -> jclass -> meth -> 'b jarray option

(** Unsafe interface for reading and writing Java fields *)

(** Read the value of a field
	May crash if the representation is incorrect *)
val read_field_int : 'a obj -> field -> int
val read_field_bool : 'a obj -> field -> bool
val read_field_byte : 'a obj -> field -> int
val read_field_short : 'a obj -> field -> int
val read_field_int32 : 'a obj -> field -> int32
val read_field_long : 'a obj -> field -> int64
val read_field_char : 'a obj -> field -> char
val read_field_float : 'a obj -> field -> float
val read_field_double : 'a obj -> field -> float
(** Raises `Failure` if the value is `null` *)
val read_field_string : 'a obj -> field -> string
val read_field_string_opt : 'a obj -> field -> string option
val read_field_object : 'a obj -> field -> 'b obj
(** Raises `Failure` if the value is `null` *)
val read_field_value : 'a obj -> field -> 'b
val read_field_value_opt : 'a obj -> field -> 'b option
val read_field_array : 'a obj -> field -> 'b jarray
val read_field_array_opt : 'a obj -> field -> 'b jarray option

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
val read_field_static_object : jclass -> field_static -> 'a obj
(** Raises `Failure` if the value is `null` *)
val read_field_static_value : jclass -> field_static -> 'a
val read_field_static_value_opt : jclass -> field_static -> 'a option
val read_field_static_array : jclass -> field_static -> 'a jarray
val read_field_static_array_opt : jclass -> field_static -> 'a jarray option

(** Write to a field *)
val write_field_int : 'a obj -> field -> int -> unit
val write_field_bool : 'a obj -> field -> bool -> unit
val write_field_byte : 'a obj -> field -> int -> unit
val write_field_short : 'a obj -> field -> int -> unit
val write_field_int32 : 'a obj -> field -> int32 -> unit
val write_field_long : 'a obj -> field -> int64 -> unit
val write_field_char : 'a obj -> field -> char -> unit
val write_field_float : 'a obj -> field -> float -> unit
val write_field_double : 'a obj -> field -> float -> unit
val write_field_string : 'a obj -> field -> string -> unit
val write_field_string_opt : 'a obj -> field -> string option -> unit
val write_field_object : 'a obj -> field -> 'b obj -> unit
val write_field_value : 'a obj -> field -> 'b -> unit
val write_field_value_opt : 'a obj -> field -> 'b option -> unit
val write_field_array : 'a obj -> field -> 'b jarray -> unit
val write_field_array_opt : 'a obj -> field -> 'b jarray option -> unit

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
val write_field_static_object : jclass -> field_static -> 'a obj -> unit
val write_field_static_value : jclass -> field_static -> 'a -> unit
val write_field_static_value_opt : jclass -> field_static -> 'a option -> unit
val write_field_static_array : jclass -> field_static -> 'a jarray -> unit
val write_field_static_array_opt : jclass -> field_static -> 'a jarray option -> unit
