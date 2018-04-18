let print_endline s = ()

exception Ok

let a () = raise Ok
let b () = a ()
let c () = try b () with e -> raise e
let d () = c ()
let e () = try d () with Not_found -> ()
let f () = e ()
let rec g i = if i = 0 then f () else g (i - 1)
let h () = g 5

let test_obj = object
	method test = print_endline "OCaml method called"
	method test_int a b = a + b
end

let () =
	Callback.register "test_function" (fun () -> print_endline "OCaml function called");
	Callback.register "test_raise" (fun () -> failwith "failuuure");
	Callback.register "test_int" (+);
	Callback.register "test_float" (+.);
	Callback.register "test_string" (^);
	Callback.register "test_bool" (&&);
	Callback.register "test_int32" Int32.add;
	Callback.register "test_int64" Int64.add;
	Callback.register "get_value" (fun () -> ("a", "b"));
	Callback.register "test_a" fst;
	Callback.register "test_b" snd;
	Callback.register "get_obj" (fun () -> test_obj);
	Callback.register "is_null" (fun obj -> obj = Java.null);
	Callback.register "test_throw" (fun thwbl -> Jthrowable.throw thwbl);
	Callback.register "test_throw_new" (fun msg ->
		let cls = Jclass.find_class "java/lang/Exception" in
		Jthrowable.throw_new cls msg);
	Callback.register "test_backtrace" h;
	print_endline "OCaml loaded"

let () = Callback.register "camljava_do_test" Test_caml.run

let run () =
	let cls = Jclass.find_class "ocamljava/test/TestJava" in
	let m_do_test = Jclass.get_meth_static cls "do_test" "()V" in
	Jcall.call_static_void cls m_do_test
