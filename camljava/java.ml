type obj

type 'a jarray

type jclass

type jthrowable

type meth
type meth_static
type meth_constructor
type field
type field_static

exception Exception of jthrowable

external startup : string array -> unit = "ocaml_java__startup"
external shutdown : unit -> unit = "ocaml_java__shutdown"

let init opts =
	startup opts;
	at_exit shutdown

let null : obj = (Obj.magic 0)

let () =
	(* Used by javacaml *)
	Callback.register "Java.get_ocaml_backtraces" Printexc.(fun () ->
		match backtrace_slots (get_raw_backtrace ()) with
		| Some bt	->
			Array.map (fun slot ->
				match Slot.location slot with
				| Some loc	-> (loc.filename, loc.line_number)
				| None		-> ("Unknown location", -1)) bt
		| None		-> [||]
	);
	Callback.register_exception "Java.Exception" (Exception (Obj.magic 0))

external instanceof : obj -> jclass -> bool
	= "ocaml_java__instanceof" [@@noalloc]

external sameobject : obj -> obj -> bool
	= "ocaml_java__sameobject" [@@noalloc]

external objectclass : obj -> jclass = "ocaml_java__objectclass"

external new_ : jclass -> meth_constructor -> obj = "ocaml_java__new"

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
external push_array : 'a jarray -> unit
	= "ocaml_java__push_array" [@@noalloc]

external call_void : obj -> meth -> unit = "ocaml_java__call_void"
external call_int : obj -> meth -> int = "ocaml_java__call_int"
external call_bool : obj -> meth -> bool = "ocaml_java__call_bool"
external call_byte : obj -> meth -> int = "ocaml_java__call_byte"
external call_short : obj -> meth -> int = "ocaml_java__call_short"
external call_int32 : obj -> meth -> int32 = "ocaml_java__call_int32"
external call_long : obj -> meth -> int64 = "ocaml_java__call_long"
external call_char : obj -> meth -> char = "ocaml_java__call_char"
external call_float : obj -> meth -> float = "ocaml_java__call_float"
external call_double : obj -> meth -> float = "ocaml_java__call_double"
external call_string : obj -> meth -> string = "ocaml_java__call_string"
external call_string_opt : obj -> meth -> string option
	= "ocaml_java__call_string_opt"
external call_object : obj -> meth -> obj = "ocaml_java__call_object"
external call_value : obj -> meth -> 'a = "ocaml_java__call_value"
external call_value_opt : obj -> meth -> 'a option
	= "ocaml_java__call_value_opt"
external call_array : obj -> meth -> 'a jarray
	= "ocaml_java__call_array"

external call_static_void : jclass -> meth_static -> unit
	= "ocaml_java__call_static_void"
external call_static_int : jclass -> meth_static -> int
	= "ocaml_java__call_static_int"
external call_static_bool : jclass -> meth_static -> bool
	= "ocaml_java__call_static_bool"
external call_static_byte : jclass -> meth_static -> int
	= "ocaml_java__call_static_byte"
external call_static_short : jclass -> meth_static -> int
	= "ocaml_java__call_static_short"
external call_static_int32 : jclass -> meth_static -> int32
	= "ocaml_java__call_static_int32"
external call_static_long : jclass -> meth_static -> int64
	= "ocaml_java__call_static_long"
external call_static_char : jclass -> meth_static -> char
	= "ocaml_java__call_static_char"
external call_static_float : jclass -> meth_static -> float
	= "ocaml_java__call_static_float"
external call_static_double : jclass -> meth_static -> float
	= "ocaml_java__call_static_double"
external call_static_string : jclass -> meth_static -> string
	= "ocaml_java__call_static_string"
external call_static_string_opt : jclass -> meth_static -> string option
	= "ocaml_java__call_static_string_opt"
external call_static_object : jclass -> meth_static -> obj
	= "ocaml_java__call_static_object"
external call_static_value : jclass -> meth_static -> 'a
	= "ocaml_java__call_static_value"
external call_static_value_opt : jclass -> meth_static -> 'a option
	= "ocaml_java__call_static_value_opt"
external call_static_array : jclass -> meth_static -> 'a jarray
	= "ocaml_java__call_static_array"

external call_nonvirtual_void : obj -> jclass -> meth -> unit
	= "ocaml_java__call_nonvirtual_void"
external call_nonvirtual_int : obj -> jclass -> meth -> int
	= "ocaml_java__call_nonvirtual_int"
external call_nonvirtual_bool : obj -> jclass -> meth -> bool
	= "ocaml_java__call_nonvirtual_bool"
external call_nonvirtual_byte : obj -> jclass -> meth -> int
	= "ocaml_java__call_nonvirtual_byte"
external call_nonvirtual_short : obj -> jclass -> meth -> int
	= "ocaml_java__call_nonvirtual_short"
external call_nonvirtual_int32 : obj -> jclass -> meth -> int32
	= "ocaml_java__call_nonvirtual_int32"
external call_nonvirtual_long : obj -> jclass -> meth -> int64
	= "ocaml_java__call_nonvirtual_long"
external call_nonvirtual_char : obj -> jclass -> meth -> char
	= "ocaml_java__call_nonvirtual_char"
external call_nonvirtual_float : obj -> jclass -> meth -> float
	= "ocaml_java__call_nonvirtual_float"
external call_nonvirtual_double : obj -> jclass -> meth -> float
	= "ocaml_java__call_nonvirtual_double"
external call_nonvirtual_string : obj -> jclass -> meth -> string
	= "ocaml_java__call_nonvirtual_string"
external call_nonvirtual_string_opt : obj -> jclass -> meth -> string option
	= "ocaml_java__call_nonvirtual_string_opt"
external call_nonvirtual_object : obj -> jclass -> meth -> obj
	= "ocaml_java__call_nonvirtual_object"
external call_nonvirtual_value : obj -> jclass -> meth -> 'a
	= "ocaml_java__call_nonvirtual_value"
external call_nonvirtual_value_opt : obj -> jclass -> meth -> 'a option
	= "ocaml_java__call_nonvirtual_value_opt"
external call_nonvirtual_array : obj -> jclass -> meth -> 'a jarray
	= "ocaml_java__call_nonvirtual_array"

external read_field_int : obj -> field -> int
	= "ocaml_java__read_field_int"
external read_field_bool : obj -> field -> bool
	= "ocaml_java__read_field_bool"
external read_field_byte : obj -> field -> int
	= "ocaml_java__read_field_byte"
external read_field_short : obj -> field -> int
	= "ocaml_java__read_field_short"
external read_field_int32 : obj -> field -> int32
	= "ocaml_java__read_field_int32"
external read_field_long : obj -> field -> int64
	= "ocaml_java__read_field_long"
external read_field_char : obj -> field -> char
	= "ocaml_java__read_field_char"
external read_field_float : obj -> field -> float
	= "ocaml_java__read_field_float"
external read_field_double : obj -> field -> float
	= "ocaml_java__read_field_double"
external read_field_string : obj -> field -> string
	= "ocaml_java__read_field_string"
external read_field_string_opt : obj -> field -> string option
	= "ocaml_java__read_field_string_opt"
external read_field_object : obj -> field -> obj
	= "ocaml_java__read_field_object"
external read_field_value : obj -> field -> 'a
	= "ocaml_java__read_field_value"
external read_field_value_opt : obj -> field -> 'a option
	= "ocaml_java__read_field_value_opt"
external read_field_array : obj -> field -> 'a jarray
	= "ocaml_java__read_field_array"

external read_field_static_int : jclass -> field_static -> int
	= "ocaml_java__read_field_static_int" [@@noalloc]
external read_field_static_bool : jclass -> field_static -> bool
	= "ocaml_java__read_field_static_bool" [@@noalloc]
external read_field_static_byte : jclass -> field_static -> int
	= "ocaml_java__read_field_static_byte" [@@noalloc]
external read_field_static_short : jclass -> field_static -> int
	= "ocaml_java__read_field_static_short" [@@noalloc]
external read_field_static_int32 : jclass -> field_static -> int32
	= "ocaml_java__read_field_static_int32"
external read_field_static_long : jclass -> field_static -> int64
	= "ocaml_java__read_field_static_long"
external read_field_static_char : jclass -> field_static -> char
	= "ocaml_java__read_field_static_char" [@@noalloc]
external read_field_static_float : jclass -> field_static -> float
	= "ocaml_java__read_field_static_float"
external read_field_static_double : jclass -> field_static -> float
	= "ocaml_java__read_field_static_double"
external read_field_static_string : jclass -> field_static -> string
	= "ocaml_java__read_field_static_string"
external read_field_static_string_opt : jclass -> field_static -> string option
	= "ocaml_java__read_field_static_string_opt"
external read_field_static_object : jclass -> field_static -> obj
	= "ocaml_java__read_field_static_object"
external read_field_static_value : jclass -> field_static -> 'a
	= "ocaml_java__read_field_static_value"
external read_field_static_value_opt : jclass -> field_static -> 'a option
	= "ocaml_java__read_field_static_value_opt"
external read_field_static_array : jclass -> field_static -> 'a jarray
	= "ocaml_java__read_field_static_array"

external write_field_int : obj -> field -> int -> unit
	= "ocaml_java__write_field_int"
external write_field_bool : obj -> field -> bool -> unit
	= "ocaml_java__write_field_bool"
external write_field_byte : obj -> field -> int -> unit
	= "ocaml_java__write_field_byte"
external write_field_short : obj -> field -> int -> unit
	= "ocaml_java__write_field_short"
external write_field_int32 : obj -> field -> int32 -> unit
	= "ocaml_java__write_field_int32"
external write_field_long : obj -> field -> int64 -> unit
	= "ocaml_java__write_field_long"
external write_field_char : obj -> field -> char -> unit
	= "ocaml_java__write_field_char"
external write_field_float : obj -> field -> float -> unit
	= "ocaml_java__write_field_float"
external write_field_double : obj -> field -> float -> unit
	= "ocaml_java__write_field_double"
external write_field_string : obj -> field -> string -> unit
	= "ocaml_java__write_field_string"
external write_field_string_opt : obj -> field -> string option -> unit
	= "ocaml_java__write_field_string_opt"
external write_field_object : obj -> field -> obj -> unit
	= "ocaml_java__write_field_object"
external write_field_value : obj -> field -> 'a -> unit
	= "ocaml_java__write_field_value"
external write_field_value_opt : obj -> field -> 'a option -> unit
	= "ocaml_java__write_field_value_opt"
external write_field_array : obj -> field -> 'a jarray -> unit
	= "ocaml_java__write_field_array"

external write_field_static_int : jclass -> field_static -> int -> unit
	= "ocaml_java__write_field_static_int" [@@noalloc]
external write_field_static_bool : jclass -> field_static -> bool -> unit
	= "ocaml_java__write_field_static_bool" [@@noalloc]
external write_field_static_byte : jclass -> field_static -> int -> unit
	= "ocaml_java__write_field_static_byte" [@@noalloc]
external write_field_static_short : jclass -> field_static -> int -> unit
	= "ocaml_java__write_field_static_short" [@@noalloc]
external write_field_static_int32 : jclass -> field_static -> int32 -> unit
	= "ocaml_java__write_field_static_int32" [@@noalloc]
external write_field_static_long : jclass -> field_static -> int64 -> unit
	= "ocaml_java__write_field_static_long" [@@noalloc]
external write_field_static_char : jclass -> field_static -> char -> unit
	= "ocaml_java__write_field_static_char" [@@noalloc]
external write_field_static_float : jclass -> field_static -> float -> unit
	= "ocaml_java__write_field_static_float" [@@noalloc]
external write_field_static_double : jclass -> field_static -> float -> unit
	= "ocaml_java__write_field_static_double" [@@noalloc]
external write_field_static_string : jclass -> field_static -> string -> unit
	= "ocaml_java__write_field_static_string" [@@noalloc]
external write_field_static_string_opt : jclass -> field_static -> string option -> unit
	= "ocaml_java__write_field_static_string_opt" [@@noalloc]
external write_field_static_object : jclass -> field_static -> obj -> unit
	= "ocaml_java__write_field_static_object" [@@noalloc]
external write_field_static_value : jclass -> field_static -> 'a -> unit
	= "ocaml_java__write_field_static_value" [@@noalloc]
external write_field_static_value_opt : jclass -> field_static -> 'a option -> unit
	= "ocaml_java__write_field_static_value_opt" [@@noalloc]
external write_field_static_array : jclass -> field_static -> 'a jarray -> unit
	= "ocaml_java__write_field_static_array" [@@noalloc]
