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
		Raises `Not_found` if the method does not exists with this signature
		Raises `Invalid_argument` if the first argument is `null` *)
	external member_method : t -> string -> string -> member_method = "ocaml_java__member_method"

	(** Same as `member_method`, for static methods *)
	external static_method : t -> string -> string -> static_method = "ocaml_java__static_method"

	(** Same as `member_method`, for virtual member methods *)
	external virtual_method : t -> string -> string -> virtual_method = "ocaml_java__virtual_method"

	(** Same as `member_method` with name `"<init>"` *)
	external init_method : t -> string -> init_method = "ocaml_java__init_method"

	(** `member_field cls name sgt` returns the field named `name`
			with signature `sgt`
		Raises `Not_found` if the field does not exists with this signature
		Raises `Invalid_argument` if the first argument is `null` *)
	external member_field : t -> string -> string -> member_field = "ocaml_java__member_field"

	(** Same as `member_field`, for static fields *)
	external static_field : t -> string -> string -> static_field = "ocaml_java__static_field"

end
