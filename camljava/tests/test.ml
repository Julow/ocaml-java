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
		call_string t (Lazy.force m_getMessage)

	let print_stack_trace t =
		call_void t (Lazy.force m_printStackTrace)

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

	push_int 1;
	assert (call_static_int cls method_static_test = ~-41);

	let obj = new_ cls method_init in

	push_int 1;
	push_int 4;
	assert (call_int obj method_test = 5);

	assert (read_field_int obj field_a = 42);
	assert (read_field_string obj field_b = "abc");
	assert (read_field_static_int cls method_static_field_a = 42);

	push_int 1;
	push_string "2";
	let obj = new_ cls method_init_ab in

	let test tname sigt push call expected =
		let get_m = Class.get_meth cls ("test_get_" ^ tname) ("()" ^ sigt)
		and id_m = Class.get_meth cls "test_id" ("(" ^ sigt ^ ")" ^ sigt) in
		let v = call obj get_m in
		(if v <> expected then
			failwith ("test_get failure: " ^ tname));
		push v;
		let v' = call obj id_m in
		(if v <> v' then
			failwith ("test_id failure: " ^ tname))
	in
	test "int" "I" push_int call_int 1;
	test "float" "F" push_float call_float 2.0;
	test "double" "D" push_double call_double 3.0;
	test "string" "Ljava/lang/String;" push_string call_string "4";
	test "string" "Ljava/lang/String;" push_string_opt call_string_opt (Some "4");
	test "boolean" "Z" push_bool call_bool true;
	test "char" "C" push_char call_char '5';
	test "byte" "B" push_byte call_byte 6;
	test "short" "S" push_short call_short 7;
	test "int32" "I" push_int32 call_int32 (Int32.of_int 8);
	test "int64" "J" push_long call_long (Int64.of_int 9);
	Callback.register "get_int_pair" (fun () -> (1, 2));
	test "value" "Ljuloo/javacaml/Value;" push_value call_value (1, 2);
	test "value" "Ljuloo/javacaml/Value;" push_value_opt call_value_opt (Some (1, 2));

	let id_obj_m = Class.get_meth cls "test_id" "(Ljava/lang/Object;)Ljava/lang/Object;" in

	let test_id push call v =
		push v;
		assert (call obj id_obj_m = v)
	in

	test_id push_string call_string "abcdef";
	test_id push_value call_value "abcdef";
	test_id push_object call_object null;

	begin try
		push_object null;
		ignore (call_value obj id_obj_m);
		assert false
	with Failure _ -> ()
	end;

	begin try
		push_object null;
		ignore (call_string obj id_obj_m);
		assert false
	with Failure _ -> ()
	end;

	push_object null;
	assert (call_string_opt obj id_obj_m = None);

	push_object null;
	assert (call_value_opt obj id_obj_m = None);

	begin try
		call_void obj (get_meth cls "raise" "()V");
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
	begin try ignore (objectclass null); assert false with Failure _ -> () end;

	let m_rec_b = get_meth_static cls "test_rec_b" "(Ljava/lang/String;)Ljava/lang/String;" in

	let test_rec_a s =
		let s = s ^ "a" in
		if String.length s >= 64 then s
		else begin
			push_string s;
			call_static_string cls m_rec_b
		end
	in
	Callback.register "test_rec_a" test_rec_a;

	print_endline @@ test_rec_a "-> ";

	()

let () = Callback.register "camljava_do_test" test

let test_javacaml () =
	let cls = Java.Class.find_class "javacaml/test/Test" in
	let m_do_test = Java.Class.get_meth_static cls "do_test" "()V" in
	Java.call_static_void cls m_do_test

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
