
type obj

let null : obj = (Obj.magic 0)

type meth
type meth_static
type meth_constructor
type field
type field_static

exception Exception of obj

external startup : string array -> unit = "ocaml_java__startup"
external shutdown : unit -> unit = "ocaml_java__shutdown"

let init opts =
	startup opts;
	at_exit shutdown

let () =
	Callback.register_exception "Java.Exception" (Exception null)

module Class =
struct

	type t

	external find_class : string -> t = "ocaml_java__find_class"

	external get_meth : t -> string -> string -> meth
		= "ocaml_java__class_get_meth"

	external get_meth_static : t -> string -> string -> meth_static
		= "ocaml_java__class_get_meth_static"

	external get_constructor : t -> string -> meth_constructor
		= "ocaml_java__class_get_constructor"

	external get_field : t -> string -> string -> field
		= "ocaml_java__class_get_field"

	external get_field_static : t -> string -> string -> field_static
		= "ocaml_java__class_get_field_static"

end

external instanceof : obj -> Class.t -> bool = "ocaml_java__instanceof"

external sameobject : obj -> obj -> bool = "ocaml_java__sameobject"

external objectclass : obj -> Class.t = "ocaml_java__objectclass"

external meth : obj -> meth -> unit = "ocaml_java__calling_meth"

external meth_static : Class.t -> meth_static -> unit
	= "ocaml_java__calling_meth_static" [@@noalloc]

external meth_nonvirtual : obj -> Class.t -> meth -> unit
	= "ocaml_java__calling_meth_nonvirtual"

external new_ : Class.t -> meth_constructor -> unit
	= "ocaml_java__calling_init" [@@noalloc]

external field : obj -> field -> unit = "ocaml_java__calling_field"

external field_static : Class.t -> field_static -> unit
	= "ocaml_java__calling_field_static" [@@noalloc]

external arg_int : int -> unit = "ocaml_java__arg_int" [@@noalloc]
external arg_float : (float [@unboxed]) -> unit
	= "ocaml_java__arg_float" "ocaml_java__arg_float_unboxed"
	[@@noalloc]
external arg_double : (float [@unboxed]) -> unit
	= "ocaml_java__arg_double" "ocaml_java__arg_double_unboxed"
	[@@noalloc]
external arg_string : string -> unit = "ocaml_java__arg_string" [@@noalloc]
external arg_bool : bool -> unit = "ocaml_java__arg_bool" [@@noalloc]
external arg_char : char -> unit = "ocaml_java__arg_char" [@@noalloc]
external arg_int8 : int -> unit = "ocaml_java__arg_int8" [@@noalloc]
external arg_int16 : int -> unit = "ocaml_java__arg_int16" [@@noalloc]
external arg_int32 : (int32 [@unboxed]) -> unit
	= "ocaml_java__arg_int32" "ocaml_java__arg_int32_unboxed"
	[@@noalloc]
external arg_int64 : (int64 [@unboxed]) -> unit
	= "ocaml_java__arg_int64" "ocaml_java__arg_int64_unboxed"
	[@@noalloc]
external arg_obj : obj -> unit = "ocaml_java__arg_obj" [@@noalloc]
external arg_value : 'a -> unit = "ocaml_java__arg_value"

external call_unit : unit -> unit = "ocaml_java__call_unit"
external call_int : unit -> int = "ocaml_java__call_int"
external call_float : unit -> float = "ocaml_java__call_float"
external call_double : unit -> float = "ocaml_java__call_double"
external call_string : unit -> string = "ocaml_java__call_string"
external call_string_opt : unit -> string option = "ocaml_java__call_string_opt"
external call_bool : unit -> bool = "ocaml_java__call_bool"
external call_char : unit -> char = "ocaml_java__call_char"
external call_int8 : unit -> int = "ocaml_java__call_int8"
external call_int16 : unit -> int = "ocaml_java__call_int16"
external call_int32 : unit -> int32 = "ocaml_java__call_int32"
external call_int64 : unit -> int64 = "ocaml_java__call_int64"
external call_obj : unit -> obj = "ocaml_java__call_obj"
external call_value : unit -> 'a = "ocaml_java__call_value"
external call_value_opt : unit -> 'a option = "ocaml_java__call_value_opt"
