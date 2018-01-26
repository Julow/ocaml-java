type t = Java.jclass

external find_class : string -> t = "ocaml_java__find_class"

external get_meth : t -> string -> string -> Java.meth
	= "ocaml_java__class_get_meth"

external get_meth_static : t -> string -> string -> Java.meth_static
	= "ocaml_java__class_get_meth_static"

external get_constructor : t -> string -> Java.meth_constructor
	= "ocaml_java__class_get_constructor"

external get_field : t -> string -> string -> Java.field
	= "ocaml_java__class_get_field"

external get_field_static : t -> string -> string -> Java.field_static
	= "ocaml_java__class_get_field_static"
