type 'a t = 'a Java.jarray

type jbyte
type jshort
type jdouble
type 'a jvalue

external create_int : int -> int t = "ocaml_java__jarray_create_int"
external create_bool : int -> bool t = "ocaml_java__jarray_create_bool"
external create_byte : int -> jbyte t = "ocaml_java__jarray_create_byte"
external create_short : int -> jshort t = "ocaml_java__jarray_create_short"
external create_int32 : int -> int32 t = "ocaml_java__jarray_create_int32"
external create_long : int -> int64 t = "ocaml_java__jarray_create_long"
external create_char : int -> char t = "ocaml_java__jarray_create_char"
external create_float : int -> float t = "ocaml_java__jarray_create_float"
external create_double : int -> jdouble t = "ocaml_java__jarray_create_double"
external create_string : int -> string t = "ocaml_java__jarray_create_string"
external create_object : Java.jclass -> _ Java.obj -> int -> _ Java.obj t
	= "ocaml_java__jarray_create_object"
external create_value : int -> 'a jvalue t = "ocaml_java__jarray_create_value"
external create_array : Java.jclass -> 'a t option -> int -> 'a t t
	= "ocaml_java__jarray_create_array"

external length : 'a t -> int = "ocaml_java__jarray_length"

external set_int : int t -> int -> int -> unit
	= "ocaml_java__jarray_set_int"
external set_bool : bool t -> int -> bool -> unit
	= "ocaml_java__jarray_set_bool"
external set_byte : jbyte t -> int -> int -> unit
	= "ocaml_java__jarray_set_byte"
external set_short : jshort t -> int -> int -> unit
	= "ocaml_java__jarray_set_short"
external set_int32 : int32 t -> int -> int32 -> unit
	= "ocaml_java__jarray_set_int32"
external set_long : int64 t -> int -> int64 -> unit
	= "ocaml_java__jarray_set_long"
external set_char : char t -> int -> char -> unit
	= "ocaml_java__jarray_set_char"
external set_float : float t -> int -> float -> unit
	= "ocaml_java__jarray_set_float"
external set_double : jdouble t -> int -> float -> unit
	= "ocaml_java__jarray_set_double"
external set_string : string t -> int -> string -> unit
	= "ocaml_java__jarray_set_string"
external set_string_opt : string t -> int -> string option -> unit
	= "ocaml_java__jarray_set_string_opt"
external set_object : _ Java.obj t -> int -> _ Java.obj -> unit
	= "ocaml_java__jarray_set_object"
external set_value : 'a jvalue t -> int -> 'a -> unit
	= "ocaml_java__jarray_set_value"
external set_value_opt : 'a jvalue t -> int -> 'a option -> unit
	= "ocaml_java__jarray_set_value_opt"
external set_array : 'a t t -> int -> 'a t -> unit
	= "ocaml_java__jarray_set_array"
external set_array_opt : 'a t t -> int -> 'a option t -> unit
	= "ocaml_java__jarray_set_array_opt"

external get_int : int t -> int -> int = "ocaml_java__jarray_get_int"
external get_bool : bool t -> int -> bool = "ocaml_java__jarray_get_bool"
external get_byte : jbyte t -> int -> int = "ocaml_java__jarray_get_byte"
external get_short : jshort t -> int -> int = "ocaml_java__jarray_get_short"
external get_int32 : int32 t -> int -> int32 = "ocaml_java__jarray_get_int32"
external get_long : int64 t -> int -> int64 = "ocaml_java__jarray_get_long"
external get_char : char t -> int -> char = "ocaml_java__jarray_get_char"
external get_float : float t -> int -> float = "ocaml_java__jarray_get_float"
external get_double : jdouble t -> int -> float
	= "ocaml_java__jarray_get_double"
external get_string : string t -> int -> string
	= "ocaml_java__jarray_get_string"
external get_string_opt : string t -> int -> string option
	= "ocaml_java__jarray_get_string_opt"
external get_object : _ Java.obj t -> int -> _ Java.obj
	= "ocaml_java__jarray_get_object"
external get_value : 'a jvalue t -> int -> 'a = "ocaml_java__jarray_get_value"
external get_value_opt : 'a jvalue t -> int -> 'a option
	= "ocaml_java__jarray_get_value_opt"
external get_array : 'a t t -> int -> 'a t
	= "ocaml_java__jarray_get_array"
external get_array_opt : 'a t t -> int -> 'a option t
	= "ocaml_java__jarray_get_array_opt"

external _of_obj : _ Java.obj -> 'a t = "%identity"
let of_obj obj =
	if obj == Java.null then failwith "Jarray.of_obj: null";
	_of_obj obj

external to_obj : 'a t -> _ Java.obj = "%identity"
