(*  *)

module Throwable =
struct

	open Java

	let m_getMessage,
		m_printStackTrace =
		let cls = lazy (Class.find_class "java/lang/Throwable") in
		lazy (Class.get_meth (Lazy.force cls) "getMessage" "()Ljava/lang/String;"),
		lazy (Class.get_meth (Lazy.force cls) "printStackTrace" "()V")

	let get_message t =
		meth t @@ Lazy.force m_getMessage;
		call_string ()

	let print_stack_trace t =
		meth t @@ Lazy.force m_printStackTrace;
		call_unit ()

end

let test () =
	let open Java.Class in

	let cls = find_class "camljava/test/Test" in

	let method_init = get_constructor cls "()V"
	and method_init_ab = get_constructor cls "(ILjava/lang/String;)V"
	and method_test = get_meth cls "test" "(II)I"
	and field_a = get_field cls "a" "I"
	and field_b = get_field cls "b" "Ljava/lang/String;"
	and method_static_test = get_meth_static cls "test" "(I)I"
	and method_static_field_a = get_field_static cls "test_f" "I"
	in

	let open Java in

	meth_static cls method_static_test;
	arg_int 1;
	assert (call_int () = ~-41);

	new_ cls method_init;
	let obj = call_obj () in

	meth obj method_test;
	arg_int 1;
	arg_int 4;
	assert (call_int () = 5);

	field obj field_a;
	assert (call_int () = 42);

	field obj field_b;
	assert (call_string () = "abc");

	field_static cls method_static_field_a;
	assert (call_int () = 42);

	new_ cls method_init_ab;
	arg_int 1;
	arg_string "2";
	let obj = call_obj () in

	let test tname sigt arg call expected =
		let get_m = Class.get_meth cls ("test_get_" ^ tname) ("()" ^ sigt)
		and id_m = Class.get_meth cls "test_id" ("(" ^ sigt ^ ")" ^ sigt) in
		meth obj get_m;
		let v = call () in
		(if v <> expected then
			failwith ("test_get failure: " ^ tname));
		meth obj id_m;
		arg v;
		let v' = call () in
		(if v <> v' then
			failwith ("test_id failure: " ^ tname))
	in
	test "int" "I" arg_int call_int 1;
	test "float" "F" arg_float call_float 2.0;
	test "double" "D" arg_double call_double 3.0;
	test "string" "Ljava/lang/String;" arg_string call_string "4";
	test "string" "Ljava/lang/String;"
		(function Some s -> arg_string s | None -> assert false)
		call_string_opt (Some "4");
	test "boolean" "Z" arg_bool call_bool true;
	test "char" "C" arg_char call_char '5';
	test "byte" "B" arg_int8 call_int8 6;
	test "short" "S" arg_int16 call_int16 7;
	test "int32" "I" arg_int32 call_int32 (Int32.of_int 8);
	test "int64" "J" arg_int64 call_int64 (Int64.of_int 9);
	Callback.register "get_int_pair" (fun () -> (1, 2));
	test "value" "Ljuloo/javacaml/Value;" arg_value call_value (1, 2);
	test "value" "Ljuloo/javacaml/Value;"
		(function Some v -> arg_value v | None -> assert false)
		call_value_opt (Some (1, 2));

	let id_obj_m = Class.get_meth cls "test_id" "(Ljava/lang/Object;)Ljava/lang/Object;" in

	let test_id arg call v =
		meth obj id_obj_m;
		arg v;
		assert (call () = v)
	in

	test_id arg_string call_string "abcdef";
	test_id arg_value call_value "abcdef";
	test_id arg_obj call_obj null;

	begin try
		test_id arg_obj call_value null;
		assert false
	with Failure _ -> ()
	end;

	begin try
		meth obj id_obj_m;
		arg_obj null;
		call_string ();
		assert false
	with Failure _ -> ()
	end;

	meth obj id_obj_m;
	arg_obj null;
	assert (call_string_opt () = None);

	meth obj id_obj_m;
	arg_obj null;
	assert (call_value_opt () = None);

	begin try
		meth obj (get_meth cls "raise" "()V");
		call_unit ();
		assert false
	with Java.Exception ex ->
		assert (Throwable.get_message ex = "test")
	end;

	assert (instanceof obj cls);
	assert (not (instanceof obj (Class.find_class "java/lang/String")));
	assert (sameobject obj obj);
	assert (sameobject null null);
	assert (not (sameobject obj null));
	assert (not (sameobject null obj));
	assert (sameobject (Obj.magic (objectclass obj)) (Obj.magic cls));
	begin try objectclass null; assert false with Failure _ -> () end;

	let m_rec_b = get_meth_static cls "test_rec_b" "(Ljava/lang/String;)Ljava/lang/String;" in

	let test_rec_a s =
		let s = s ^ "a" in
		if String.length s >= 64 then s
		else begin
			meth_static cls m_rec_b;
			arg_string s;
			call_string ()
		end
	in
	Callback.register "test_rec_a" test_rec_a;

	print_endline @@ test_rec_a "-> ";

	()

let () = Callback.register "camljava_do_test" test

let test_javacaml () =
	let cls = Java.Class.find_class "javacaml/test/Test" in
	let m_do_test = Java.Class.get_meth_static cls "do_test" "()V" in
	Java.meth_static cls m_do_test;
	Java.call_unit ()

let () =
	let jar_files = [
		"test.jar";
		"../../javacaml/tests/test.jar";
		"../../bin/ocaml-java.jar"
	] in
	(* quick check if executed from javacaml's tests *)
	if Sys.argv.(0) <> "" then begin
		Java.init [|
			"-Djava.class.path=" ^ String.concat ":" jar_files;
			"-ea"
		|];
		try
			test ();
			(* test_javacaml *) ()
		with Java.Exception e ->
			Throwable.print_stack_trace e;
			failwith ""
	end
