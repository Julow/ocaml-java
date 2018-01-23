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
		call t (Lazy.force m_getMessage) (Ret String)

	let print_stack_trace t =
		call t (Lazy.force m_printStackTrace) Void

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

	push Int 1;
	assert (call_static cls method_static_test (Ret Int) = ~-41);

	let obj = new_ cls method_init in

	push Int 1;
	push Int 4;
	assert (call obj method_test (Ret Int) = 5);

	assert (read_field obj field_a Int = 42);
	assert (read_field obj field_b String = "abc");
	assert (read_field_static cls method_static_field_a Int = 42);

	push Int 1;
	push String "2";
	let obj = new_ cls method_init_ab in

	let test tname sigt jtype expected =
		let get_m = Class.get_meth cls ("test_get_" ^ tname) ("()" ^ sigt)
		and id_m = Class.get_meth cls "test_id" ("(" ^ sigt ^ ")" ^ sigt) in
		let v = call obj get_m (Ret jtype) in
		(if v <> expected then
			failwith ("test_get failure: " ^ tname));
		push jtype v;
		let v' = call obj id_m (Ret jtype) in
		(if v <> v' then
			failwith ("test_id failure: " ^ tname))
	in
	test "int" "I" Int 1;
	test "float" "F" Float 2.0;
	test "double" "D" Double 3.0;
	test "string" "Ljava/lang/String;" String "4";
	test "string" "Ljava/lang/String;" String_opt (Some "4");
	test "boolean" "Z" Bool true;
	test "char" "C" Char '5';
	test "byte" "B" Byte 6;
	test "short" "S" Short 7;
	test "int32" "I" Int32 (Int32.of_int 8);
	test "int64" "J" Long (Int64.of_int 9);
	Callback.register "get_int_pair" (fun () -> (1, 2));
	test "value" "Ljuloo/javacaml/Value;" Value (1, 2);
	test "value" "Ljuloo/javacaml/Value;" Value_opt (Some (1, 2));

	let id_obj_m = Class.get_meth cls "test_id" "(Ljava/lang/Object;)Ljava/lang/Object;" in

	let test_id jtype v =
		push jtype v;
		assert (call obj id_obj_m (Ret jtype) = v)
	in

	test_id String "abcdef";
	test_id Value "abcdef";
	test_id Object null;

	begin try
		push Object null;
		ignore (call obj id_obj_m (Ret Value));
		assert false
	with Failure _ -> ()
	end;

	begin try
		push Object null;
		ignore (call obj id_obj_m (Ret String));
		assert false
	with Failure _ -> ()
	end;

	push Object null;
	assert (call obj id_obj_m (Ret String_opt) = None);

	push Object null;
	assert (call obj id_obj_m (Ret Value_opt) = None);

	begin try
		call obj (get_meth cls "raise" "()V") Void;
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
			push String s;
			call_static cls m_rec_b (Ret String)
		end
	in
	Callback.register "test_rec_a" test_rec_a;

	print_endline @@ test_rec_a "-> ";

	()

let () = Callback.register "camljava_do_test" test

let test_javacaml () =
	let cls = Java.Class.find_class "javacaml/test/Test" in
	let m_do_test = Java.Class.get_meth_static cls "do_test" "()V" in
	Java.call_static cls m_do_test Java.Void

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
