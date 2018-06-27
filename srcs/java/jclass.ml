type t = Java.jclass

exception Class_not_found of string
exception Method_not_found of string * string
exception Field_not_found of string * string

type meth
type meth_static
type meth_constructor = meth
type field
type field_static

external _find_class : string -> t = "ocaml_java__find_class"

external _get_meth : t -> string -> string -> meth
	= "ocaml_java__class_get_meth"

external _get_meth_static : t -> string -> string -> meth_static
	= "ocaml_java__class_get_meth_static"

external _get_field : t -> string -> string -> field
	= "ocaml_java__class_get_field"

external _get_field_static : t -> string -> string -> field_static
	= "ocaml_java__class_get_field_static"

let find_class name =
	try _find_class name
	with Not_found -> raise (Class_not_found name)

let get_meth cls name sigt =
	try _get_meth cls name sigt
	with Not_found -> raise (Method_not_found (name, sigt))

let get_meth_static cls name sigt =
	try _get_meth_static cls name sigt
	with Not_found -> raise (Method_not_found (name, sigt))

let get_constructor cls sigt = get_meth cls "<init>" sigt

let get_field cls name sigt =
	try _get_field cls name sigt
	with Not_found -> raise (Field_not_found (name, sigt))

let get_field_static cls name sigt =
	try _get_field_static cls name sigt
	with Not_found -> raise (Field_not_found (name, sigt))
