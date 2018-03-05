(** A Java class *)
type t = Java.jclass

(** `find_class s` returns the class named `s`
	Raises `Not_found` if the class does not exists *)
val find_class : string -> t

(** `get_meth cls name sgt` returns the method
		named `name` with signature `sgt`
	Raises `Not_found` if the method does not exists with this signature *)
val get_meth : t -> string -> string -> Java.meth

(** Same as `get_meth`, for static methods *)
val get_meth_static : t -> string -> string -> Java.meth_static

(** Same as `get_meth`, for object constructor *)
val get_constructor : t -> string -> Java.meth_constructor

(** `get_field cls name sgt` returns the field named `name`
		with signature `sgt`
	Raises `Not_found` if the field does not exists with this signature *)
val get_field : t -> string -> string -> Java.field

(** Same as `get_field`, for static fields *)
val get_field_static : t -> string -> string -> Java.field_static
