(** A Java array
	Does not support comparaison, hash and marshalling *)
type 'a t = 'a Java.jarray

(* Dummy types to avoid mixing up the type of the array *)
type jbyte
type jshort
type jdouble
type 'a jvalue

(** `create_int 4` Creates an array holding 4 ints
	All elements are initialized with a default value
	Warning: `string` and `value` arrays are filled with `null`,
		`get_string` and `get_value` will raises `Failure`
	Raises `Failure` if the allocation fail *)
val create_int : int -> int t
val create_bool : int -> bool t
val create_byte : int -> jbyte t
val create_short : int -> jshort t
val create_int32 : int -> int32 t
val create_long : int -> int64 t
val create_char : int -> char t
val create_float : int -> float t
val create_double : int -> jdouble t
val create_string : int -> string t
val create_object : Java.jclass -> 'a Java.obj -> int -> 'b Java.obj t
val create_value : int -> 'a jvalue t
val create_array : Java.jclass -> 'a t option -> int -> 'a t t

(** Returns the length of an array *)
external length : 'a t -> int = "ocaml_java__jarray_length"

(** Set an element
	Raises `Invalid_argument` if the index is out of bounds *)
val set_int : int t -> int -> int -> unit
val set_bool : bool t -> int -> bool -> unit
val set_byte : jbyte t -> int -> int -> unit
val set_short : jshort t -> int -> int -> unit
val set_int32 : int32 t -> int -> int32 -> unit
val set_long : int64 t -> int -> int64 -> unit
val set_char : char t -> int -> char -> unit
val set_float : float t -> int -> float -> unit
val set_double : jdouble t -> int -> float -> unit
val set_string : string t -> int -> string -> unit
val set_string_opt : string t -> int -> string option -> unit
val set_object : 'a Java.obj t -> int -> 'b Java.obj -> unit
val set_value : 'a jvalue t -> int -> 'a -> unit
val set_value_opt : 'a jvalue t -> int -> 'a option -> unit
val set_array : 'a t t -> int -> 'a t -> unit
val set_array_opt : 'a t t -> int -> 'a option t -> unit

(** Retrieve an element
	Raises `Invalid_argument` if the index is out of bounds
	Raises `Failure` if the element is `null`
		and the representation is `String`, `Value` or `Array ..` *)
val get_int : int t -> int -> int
val get_bool : bool t -> int -> bool
val get_byte : jbyte t -> int -> int
val get_short : jshort t -> int -> int
val get_int32 : int32 t -> int -> int32
val get_long : int64 t -> int -> int64
val get_char : char t -> int -> char
val get_float : float t -> int -> float
val get_double : jdouble t -> int -> float
val get_string : string t -> int -> string
val get_string_opt : string t -> int -> string option
val get_object : 'a Java.obj t -> int -> 'b Java.obj
val get_value : 'a jvalue t -> int -> 'a
val get_value_opt : 'a jvalue t -> int -> 'a option
val get_array : 'a t t -> int -> 'a t
val get_array_opt : 'a t t -> int -> 'a option t

(** Unsafe convertion from/to `Java.obj`
	Raises `Failure` if the object is null *)
val of_obj : 'a Java.obj -> 'b t
val to_obj : 'a t -> 'b Java.obj
