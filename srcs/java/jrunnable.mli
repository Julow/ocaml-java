(** An instance of Runnable
	Does not support marshalling and hashing *)
type t

(** Create an instance of Runnable that will call the given function *)
val create : (unit -> unit) -> t

(** Call the `run` method *)
val run : t -> unit

(** Coerce from Java.obj
	Raise `Failure` if the object is not an instance of Runnable or null *)
val of_obj : 'a Java.obj -> t

(** Coerce to Java.obj *)
val to_obj : t -> 'a Java.obj
