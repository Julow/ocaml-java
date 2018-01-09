(** Interfaces Java
	Unsafe *)

(** Spawn a JVM and initialise the library
	Takes an array of JVM options *)
external startup : string array -> unit = "ocaml_java__startup"
external shutdown : unit -> unit = "ocaml_java__shutdown"

let init opts =
	startup opts;
	at_exit shutdown
