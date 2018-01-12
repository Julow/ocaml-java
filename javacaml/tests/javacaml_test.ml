let print_endline s = ()

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
	print_endline "OCaml loaded"
