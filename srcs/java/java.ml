type 'a obj

type 'a jarray

type jclass

type jthrowable

exception Exception of jthrowable

external startup : string array -> unit = "ocaml_java__startup"
external shutdown : unit -> unit = "ocaml_java__shutdown"

let init opts =
	startup opts;
	at_exit shutdown

let null = Obj.magic 0

let () =
	(* Used by javacaml to handle uncaught exceptions *)
	Callback.register "Java.get_ocaml_backtraces" Printexc.(fun () ->
		match backtrace_slots (get_raw_backtrace ()) with
		| Some bt	->
			Array.map (fun slot ->
				match Slot.location slot with
				| Some loc	-> (loc.filename, loc.line_number)
				| None		-> ("Unknown location", -1)) bt
		| None		-> [||]
	);
	Callback.register "Java.get_cause" (function
		| Exception thr	-> Some thr
		| _				-> None);
	Callback.register_exception "Java.Exception" (Exception (Obj.magic 0))

external instanceof : _ obj -> jclass -> bool
	= "ocaml_java__instanceof" [@@noalloc]

external sameobject : _ obj -> _ obj -> bool
	= "ocaml_java__sameobject" [@@noalloc]

external objectclass : _ obj -> jclass = "ocaml_java__objectclass"

external compare : 'a obj -> 'a obj -> int = "ocaml_java__compare"

external to_string : 'a obj -> string = "ocaml_java__to_string"
external equals : 'a obj -> 'a obj -> bool = "ocaml_java__equals"
external hash_code : 'a obj -> int = "ocaml_java__hash_code"
