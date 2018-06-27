(** A Java class *)
type t = Java.jclass

exception Class_not_found of string
exception Method_not_found of string * string
exception Field_not_found of string * string

(** Methods, constructors and fields *)
type meth
type meth_static
type meth_constructor
type field
type field_static

(** `find_class s` returns the class named `s`
	Raises `Class_not_found` if the class does not exists *)
val find_class : string -> t

(** `get_meth cls name sgt` returns the method
		named `name` with signature `sgt`
	Raises `Method_not_found`
		if the method does not exists with this signature *)
val get_meth : t -> string -> string -> meth

(** Same as `get_meth`, for static methods *)
val get_meth_static : t -> string -> string -> meth_static

(** Same as `get_meth`, for object constructor *)
val get_constructor : t -> string -> meth_constructor

(** `get_field cls name sgt` returns the field named `name`
		with signature `sgt`
	Raises `Field_not_found` if the field does not exists with this signature *)
val get_field : t -> string -> string -> field

(** Same as `get_field`, for static fields *)
val get_field_static : t -> string -> string -> field_static
