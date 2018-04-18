(** Interfaces Java *)

(** Represent a java object
	The `'a` (phantom) parameter is to embed custom types
	Does not support marshalling
	Polymorphic hash is implemented by calling Java's Object.hashCode
	Polymorphic compare is implemented using Java's Comparable interface
		It has a few differences with `compare`:
		- Objects with the exact same reference are considered equals
		- Comparing with `null` will compare only the reference *)
type 'a obj

(** Java array
	See the `Jarray` module *)
type 'a jarray

(* Java class
	See the `Jclass` module *)
type jclass

(* Java throwable objects *)
type jthrowable

(** Raised when a java exception is thrown
	The parameter is the java Exception *)
exception Exception of jthrowable

(** Initialize the JVM
	Takes the JVM options as parameter *)
val init : string array -> unit

(** The null value *)
val null : 'a obj

(** `instanceof o cls`
	Returns `true` if `o` is an instance of the class `cls`
	and is not `null`
	or `false` otherwise *)
external instanceof : 'a obj -> jclass -> bool
	= "ocaml_java__instanceof" [@@noalloc]

(** `sameobject a b`
	Returns `true` if `a` and `b` refer to the same object or false otherwise *)
external sameobject : 'a obj -> 'b obj -> bool
	= "ocaml_java__sameobject" [@@noalloc]

(** Returns the class of an object
	Raises `Failure` if the object is `null` *)
val objectclass : 'a obj -> jclass

(** Compare two objects by calling `compareTo` from the Comparable interface
	Raises `Failure` if the first argument is null
		or does not implements the Comparable interface
	Raises `Exception` if the `compareTo` method thrown an exception *)
val compare : 'a obj -> 'a obj -> int

(** Binding for `Object.toString()`
	Raises `Failure` if the object is `null` *)
val to_string : 'a obj -> string

(** Binding for `Object.equals(o)`
	Raises `Failure` if the first argument is `null` *)
val equals : 'a obj -> 'a obj -> bool

(** Binding for `Object.hashCode()`
	Raises `Failure` if the object is `null` *)
val hash_code : 'a obj -> int
