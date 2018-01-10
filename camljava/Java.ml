(** Interfaces Java
	Unsafe *)

(** Represent a java object
	Does not support hash and marshalling *)
type obj

(** The null value *)
let null : obj = (Obj.magic 0)

(** Methods and fields
	There is a type for each type of method/field
	member_method	(nonvirtual) Member method
	static_method	Static method
	virtual_method	Member method through inheritance
	init_method		Object constructor
	member_field	Object attribute
	static_field	Static field *)
type member_method
type static_method
type virtual_method
type init_method
type member_field
type static_field

(** Spawn a JVM and initialise the library
	Takes an array of JVM options *)
external startup : string array -> unit = "ocaml_java__startup"
external shutdown : unit -> unit = "ocaml_java__shutdown"

let init opts =
	startup opts;
	at_exit shutdown

module Class =
struct

	(** A Java class *)
	type t

	(** `find_class s` returns the class named `s`
		Raises `Not_found` if the class does not exists *)
	external find_class : string -> t = "ocaml_java__find_class"

	(** `member_method cls name sgt` returns the method
			named `name` with signature `sgt`
		Raises `Not_found` if the method does not exists with this signature *)
	external member_method : t -> string -> string -> member_method = "ocaml_java__member_method"

	(** Same as `member_method`, for static methods *)
	external static_method : t -> string -> string -> static_method = "ocaml_java__static_method"

	(** Same as `member_method`, for virtual member methods *)
	external virtual_method : t -> string -> string -> virtual_method = "ocaml_java__virtual_method"

	(** Same as `member_method` with name `"<init>"` *)
	external init_method : t -> string -> init_method = "ocaml_java__init_method"

	(** `member_field cls name sgt` returns the field named `name`
			with signature `sgt`
		Raises `Not_found` if the field does not exists with this signature *)
	external member_field : t -> string -> string -> member_field = "ocaml_java__member_field"

	(** Same as `member_field`, for static fields *)
	external static_field : t -> string -> string -> static_field = "ocaml_java__static_field"

end

(** Calling a function
	-
	Begins the calling of a function with a call to one of:
		- `member_method obj class_ meth` to call a nonvirtual method
		- `static_method class_ meth` to call a static method
		- `virtual_method obj meth` to call an instance method
		- `init_method class_ meth` to instantiate a new object
				(must be called with call_obj)
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

(** `member_method object meth` Begins the calling of the method `meth`
		of the object `object`
	Raises `Invalid_argument` if `object` is null *)
external member_method : obj -> Class.t -> member_method -> unit = "ocaml_java__calling_member_method"

(** Same as `member_method`, for static methods *)
external static_method : Class.t -> static_method -> unit = "ocaml_java__calling_static_method"

(** Same as `member_method`, for virtual methods *)
external virtual_method : obj -> virtual_method -> unit = "ocaml_java__calling_virtual_method"

(** Same as `member_method`, for init methods
	Must be called with `call_obj`,
	other call functions will raise `Failure` *)
external init_method : Class.t -> init_method -> unit = "ocaml_java__calling_init_method"

(** Adds an argument on the stack *)
external arg_int : int -> unit = "ocaml_java__arg_int"
external arg_float : float -> unit = "ocaml_java__arg_float"
external arg_double : float -> unit = "ocaml_java__arg_double"
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
external call_string : unit -> string = "ocaml_java__call_string"
external call_bool : unit -> bool = "ocaml_java__call_bool"
external call_char : unit -> char = "ocaml_java__call_char"
external call_int8 : unit -> int = "ocaml_java__call_int8"
external call_int16 : unit -> int = "ocaml_java__call_int16"
external call_int32 : unit -> int32 = "ocaml_java__call_int32"
external call_int64 : unit -> int64 = "ocaml_java__call_int64"
external call_obj : unit -> obj = "ocaml_java__call_obj"
