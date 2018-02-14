(** An instance of Throwable
	Does not support hash and marshalling *)
type t = Java.jthrowable

(** Throws a throwable object
	Implemented by throwing an internal exception, does not return *)
val throw : t -> 'a

(** `throw_new cls msg`
	Throws a new instance of `cls` with the message `msg` *)
val throw_new : Jclass.t -> string -> 'a

(** Convert to an obj *)
val to_obj : t -> 'a Java.obj

(** Some Throwable methods *)

(** Raises `Failure` if the message is `null` *)
val get_localized_message : t -> string

(** Raises `Failure` if the message is `null` *)
val get_message : t -> string

val print_stack_trace : t -> unit
