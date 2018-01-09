(** Interfaces Java
	Unsafe *)

(** Represent a java object
	Does not support hash and marshalling *)
type obj

(** The null value *)
let null : obj = (Obj.magic 0)

(** Spawn a JVM and initialise the library
	Takes an array of JVM options *)
external startup : string array -> unit = "ocaml_java__startup"
external shutdown : unit -> unit = "ocaml_java__shutdown"

let init opts =
	startup opts;
	at_exit shutdown

module Class =
struct

	type t

	(** `find_class s` returns the class named `s`
		Raises `Not_found` if the class does not exists *)
	external find_class : string -> t = "ocaml_java__find_class"

end
