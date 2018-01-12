let jar_files = [
	"test.jar";
	"../../javacaml/tests/test.jar";
	"../../javacaml/bin/javacaml.jar";
]

let () =
	Java.init [|
		"-Djava.class.path=" ^ String.concat ":" jar_files;
		"-ea"
	|]

module Throwable =
struct

	open Java

	let m_getMessage,
		m_printStackTrace =
		let cls = Class.find_class "java/lang/Throwable" in
		Class.get_meth cls "getMessage" "()Ljava/lang/String;",
		Class.get_meth cls "printStackTrace" "()V"

	let get_message t =
		meth t m_getMessage;
		call_string ()

	let print_stack_trace t =
		meth t m_printStackTrace;
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
		assert (v = expected);
		meth obj id_m;
		arg v;
		let v' = call () in
		assert (v = v')
	in
	test "int" "I" arg_int call_int 1;
	test "float" "F" arg_float call_float 2.0;
	test "double" "D" arg_double call_double 3.0;
	test "string" "Ljava/lang/String;" arg_string call_string "4";
	test "boolean" "Z" arg_bool call_bool true;
	test "char" "C" arg_char call_char '5';
	test "byte" "B" arg_int8 call_int8 6;
	test "short" "S" arg_int16 call_int16 7;
	test "int32" "I" arg_int32 call_int32 (Int32.of_int 8);
	test "int64" "J" arg_int64 call_int64 (Int64.of_int 9);

	begin try
		meth obj (get_meth cls "raise" "()V");
		call_unit ();
		assert false
	with Java.Exception ex ->
		assert (Throwable.get_message ex = "test")
	end;

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

let test_javacaml () =
	let cls = Java.Class.find_class "javacaml/test/Test" in
	let m_do_test = Java.Class.get_meth_static cls "do_test" "()V" in
	Java.meth_static cls m_do_test;
	Java.call_unit ()

let () =
	try
		test ();
		test_javacaml ()
	with Java.Exception e ->
		Throwable.print_stack_trace e;
		failwith ""
