
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

	external get_meth : t -> string -> string -> meth =
		"ocaml_java__class_get_meth"

	external get_meth_static : t -> string -> string -> meth_static =
		"ocaml_java__class_get_meth_static"

	external get_constructor : t -> string -> meth_constructor =
		"ocaml_java__class_get_constructor"

	external get_field : t -> string -> string -> field =
		"ocaml_java__class_get_field"

	external get_field_static : t -> string -> string -> field_static =
		"ocaml_java__class_get_field_static"

end

external meth : obj -> meth -> unit = "ocaml_java__calling_meth"

external meth_static : Class.t -> meth_static -> unit =
	"ocaml_java__calling_meth_static"

external meth_nonvirtual : obj -> Class.t -> meth -> unit =
	"ocaml_java__calling_meth_nonvirtual"

external new_ : Class.t -> meth_constructor -> unit = "ocaml_java__calling_init"

external field : obj -> field -> unit = "ocaml_java__calling_field"

external field_static : Class.t -> field_static -> unit =
	"ocaml_java__calling_field_static"

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
external arg_value : 'a -> unit = "ocaml_java__arg_value"

external call_unit : unit -> unit = "ocaml_java__call_unit"
external call_int : unit -> int = "ocaml_java__call_int"
external call_float : unit -> float = "ocaml_java__call_float"
external call_double : unit -> float = "ocaml_java__call_double"
external call_string : unit -> string = "ocaml_java__call_string"
external call_bool : unit -> bool = "ocaml_java__call_bool"
external call_char : unit -> char = "ocaml_java__call_char"
external call_int8 : unit -> int = "ocaml_java__call_int8"
external call_int16 : unit -> int = "ocaml_java__call_int16"
external call_int32 : unit -> int32 = "ocaml_java__call_int32"
external call_int64 : unit -> int64 = "ocaml_java__call_int64"
external call_obj : unit -> obj = "ocaml_java__call_obj"
external call_value : unit -> 'a = "ocaml_java__call_value"
