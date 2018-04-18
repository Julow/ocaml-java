type t = Java.jclass

type meth
type meth_static
type meth_constructor
type field
type field_static

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
