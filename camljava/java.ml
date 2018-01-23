type obj

let null : obj = (Obj.magic 0)

type meth
type meth_static
type meth_constructor
type field
type field_static

exception Exception of obj

external startup : string array -> unit = "ocaml_java__startup"
external shutdown : unit -> unit = "ocaml_java__shutdown"

let init opts =
	startup opts;
	at_exit shutdown

let () =
	Callback.register_exception "Java.Exception" (Exception null)

module Class =
struct

	type t

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

end

external instanceof : obj -> Class.t -> bool = "ocaml_java__instanceof"

external sameobject : obj -> obj -> bool = "ocaml_java__sameobject"

external objectclass : obj -> Class.t = "ocaml_java__objectclass"

type _ jtype =
	| Int : int jtype
	| Bool : bool jtype
	| Byte : int jtype
	| Short : int jtype
	| Int32 : int32 jtype
	| Long : int64 jtype
	| Char : char jtype
	| Float : float jtype
	| Double : float jtype
	| String : string jtype
	| String_opt : string option jtype
	| Object : obj jtype
	| Value : 'a jtype
	| Value_opt : 'a option jtype

type _ jtype' =
	| Void : unit jtype'
	| Ret : 'a jtype -> 'a jtype'

external push : 'a jtype -> 'a -> unit
	= "ocaml_java__push" [@@noalloc]

external call : obj -> meth -> 'a jtype' -> 'a
	= "ocaml_java__call"
external call_static : Class.t -> meth_static -> 'a jtype' -> 'a
	= "ocaml_java__call_static"
external call_nonvirtual : obj -> Class.t -> meth -> 'a jtype' -> 'a
	= "ocaml_java__call_nonvirtual"

external new_ : Class.t -> meth_constructor -> obj
	= "ocaml_java__new"

external read_field : obj -> field -> 'a jtype -> 'a
	= "ocaml_java__read_field"
external read_field_static : Class.t -> field_static -> 'a jtype -> 'a
	= "ocaml_java__read_field_static"

external write_field : obj -> field -> 'a jtype -> 'a -> unit
	= "ocaml_java__write_field" [@@noalloc]
external write_field_static : Class.t -> field_static -> 'a jtype -> 'a -> unit
	= "ocaml_java__write_field_static" [@@noalloc]
