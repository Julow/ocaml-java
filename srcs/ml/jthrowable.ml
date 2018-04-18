type t = Java.jthrowable

exception Throwing

external _throw : t -> unit
	= "ocaml_java__jthrowable_throw"
external _throw_new : Jclass.t -> string -> unit
	= "ocaml_java__jthrowable_throw_new"

let throw t =
	_throw t;
	raise Throwing

let throw_new cls msg =
	_throw_new cls msg;
	raise Throwing

external to_obj : t -> _ Java.obj = "%identity"

type api = {
	get_localized_message : Jclass.meth;
	get_message : Jclass.meth;
	print_stack_trace : Jclass.meth
}

let api = lazy (
	let cls = Jclass.find_class "java/lang/Throwable" in
	let m = Jclass.get_meth cls in
	{
		get_localized_message = m "getLocalizedMessage" "()Ljava/lang/String;";
		get_message = m "getMessage" "()Ljava/lang/String;";
		print_stack_trace = m "printStackTrace" "()V"
	})

let get_localized_message t =
	let meth = (Lazy.force api).get_localized_message in
	Jcall.call_string (to_obj t) meth

let get_message t =
	let meth = (Lazy.force api).get_message in
	Jcall.call_string (to_obj t) meth

let print_stack_trace t =
	let meth = (Lazy.force api).print_stack_trace in
	Jcall.call_void (to_obj t) meth
