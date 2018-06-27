type t

external create : (unit -> unit) -> t = "ocaml_java__runnable_create"
external run : t -> unit = "ocaml_java__runnable_run"
external of_obj : 'a Java.obj -> t = "ocaml_java__runnable_of_obj"
external to_obj : t -> 'a Java.obj = "%identity"
