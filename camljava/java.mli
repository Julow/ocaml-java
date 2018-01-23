(** Interfaces Java
	Unsafe *)

(** Represent a java object
	Does not support hash and marshalling *)
type obj

(** The null value *)
val null : obj

(** Methods and fields
	There is a type for each type of method/field
	meth				Member method
	meth_static			Static method
	meth_constructor	Object constructor
	field				Object attribute
	field_static		Static field *)
type meth
type meth_static
type meth_constructor
type field
type field_static

(** Raised when a java exception is thrown
	The parameter is the java Exception *)
exception Exception of obj

(** Initialize the JVM
	Takes the JVM options as parameter *)
val init : string array -> unit

module Class : sig

	(** A Java class *)
	type t

	(** `find_class s` returns the class named `s`
		Raises `Not_found` if the class does not exists *)
	external find_class : string -> t = "ocaml_java__find_class"

	(** `get_meth cls name sgt` returns the method
			named `name` with signature `sgt`
		Raises `Not_found` if the method does not exists with this signature *)
	external get_meth : t -> string -> string -> meth
		= "ocaml_java__class_get_meth"

	(** Same as `get_meth`, for static methods *)
	external get_meth_static : t -> string -> string -> meth_static
		= "ocaml_java__class_get_meth_static"

	(** Same as `get_meth`, for object constructor *)
	external get_constructor : t -> string -> meth_constructor
		= "ocaml_java__class_get_constructor"

	(** `get_field cls name sgt` returns the field named `name`
			with signature `sgt`
		Raises `Not_found` if the field does not exists with this signature *)
	external get_field : t -> string -> string -> field
		= "ocaml_java__class_get_field"

	(** Same as `get_field`, for static fields *)
	external get_field_static : t -> string -> string -> field_static
		= "ocaml_java__class_get_field_static"

end

(** `instanceof o cls`
	Returns `true` if `o` is an instance of the class `cls`
	and is not `null`
	or `false` otherwise *)
external instanceof : obj -> Class.t -> bool = "ocaml_java__instanceof"

(** `sameobject a b`
	Returns `true` if `a` and `b` refer to the same object or false otherwise
	Not the same as `(=)` because `(=)` only compare references
	while many difference references may point to the same object
	(eg. global or weak references) *)
external sameobject : obj -> obj -> bool = "ocaml_java__sameobject"

(** Returns the class of an object
	Raises `Failure` if the object is `null` *)
external objectclass : obj -> Class.t = "ocaml_java__objectclass"

(** The representation of an argument/field *)
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

(** Specify the return type *)
type _ jtype' =
	| Void : unit jtype'
	| Ret : 'a jtype -> 'a jtype'

(** Adds an argument on the calling stack *)
external push : 'a jtype -> 'a -> unit
	= "ocaml_java__push" [@@noalloc]

(** Perform a call
	Assume enough argument are in the calling stack (see `push`)
	Raises `Failure` if the object is null
	May crash if some argument are missing or have the wrong representation *)
external call : obj -> meth -> 'a jtype' -> 'a
	= "ocaml_java__call"

(** Same as `call`, for static methods *)
external call_static : Class.t -> meth_static -> 'a jtype' -> 'a
	= "ocaml_java__call_static"

(** Same as `call`, for non-virtual call
	Call the method of a specific class instead of the class of the object *)
external call_nonvirtual : obj -> Class.t -> meth -> 'a jtype' -> 'a
	= "ocaml_java__call_nonvirtual"

(** Instantiate a new object
	Assume enough argument are in the calling stack (see `push`)
	May crash for the same reason as `call` *)
external new_ : Class.t -> meth_constructor -> obj
	= "ocaml_java__new"

(** Read the value of a field
	May crash if the representation is incorrect *)
external read_field : obj -> field -> 'a jtype -> 'a
	= "ocaml_java__read_field"

(** Same as `read_field`, for static fields *)
external read_field_static : Class.t -> field_static -> 'a jtype -> 'a
	= "ocaml_java__read_field_static"

(** Write to a field *)
external write_field : obj -> field -> 'a jtype -> 'a -> unit
	= "ocaml_java__write_field" [@@noalloc]

(** Same as `write_field`, for static fields *)
external write_field_static : Class.t -> field_static -> 'a jtype -> 'a -> unit
	= "ocaml_java__write_field_static" [@@noalloc]
