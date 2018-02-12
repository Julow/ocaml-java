(*  *)

let () =
	let jar_files = [
		"test.jar";
		"../../javacaml/tests/test.jar";
		"../../bin/ocaml-java.jar"
	] in
	(* quick check if executed from javacaml's tests *)
	if Sys.argv.(0) <> "" then
		Java.init [|
			"-Djava.class.path=" ^ String.concat ":" jar_files;
			"-ea";
			"-Xcheck:jni"
		|]

let () = Callback.register "get_int_pair" (fun () -> (1, 2))

let test () =
	let open Jclass in

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

	let test_id_all () =
		let test tname sigt push call get set get_static set_static arr_create arr_get arr_set
				expected set_v =
			let get_m = get_meth cls ("test_get_" ^ tname) ("()" ^ sigt)
			and id_m = get_meth cls "test_id" ("(" ^ sigt ^ ")" ^ sigt) in

			let v = call obj get_m in
			assert (v = expected);
			push v;
			let v' = call obj id_m in
			assert (v = v');

			let attr = get_field cls ("test_attr_" ^ tname) sigt
			and static = get_field_static cls ("test_static_" ^ tname) sigt
			and final = get_field_static cls ("test_const_" ^ tname) sigt in

			assert (get obj attr = expected);
			set obj attr set_v;
			assert (get obj attr = set_v);
			set obj attr (get_static cls final);
			assert (get obj attr = expected);

			assert (get_static cls static = expected);
			set_static cls static set_v;
			assert (get_static cls static = set_v);
			set_static cls static (get_static cls final);
			assert (get_static cls static = expected);

			let array_attr = get_field_static cls ("test_array_" ^ tname) ("[" ^ sigt)
			and set_array = get_meth_static cls ("set_test_array_" ^ tname) ("([" ^ sigt ^ ")V") in
			let len = 10 in
			let arr = arr_create 10 in

			let all_eq arr v = for i = 0 to len - 1 do assert (arr_get arr i = v) done in

			for i = 0 to len - 1 do arr_set arr i expected done;
			all_eq arr expected;

			let try_invalid_getset i =
				begin try ignore (arr_get arr i); assert false with Invalid_argument _ -> () end;
				begin try arr_set arr i expected; assert false with Invalid_argument _ -> () end
			in

			try_invalid_getset ~-1;
			try_invalid_getset len;

			push_array arr;
			call_static_void cls set_array;

			all_eq (read_field_static_array cls array_attr) expected;

			push_object null;
			call_static_void cls set_array;

			begin try
				ignore (read_field_static_array cls array_attr);
				assert false
			with Failure _ -> () end;

			()
		in

		test "int" "I" push_int call_int read_field_int write_field_int read_field_static_int
			write_field_static_int Jarray.create_int Jarray.get_int Jarray.set_int 1 ~-1;
		test "float" "F" push_float call_float read_field_float write_field_float read_field_static_float
			write_field_static_float Jarray.create_float Jarray.get_float Jarray.set_float 2.0 ~-.2.0;
		test "double" "D" push_double call_double read_field_double write_field_double
			read_field_static_double write_field_static_double Jarray.create_double Jarray.get_double
			Jarray.set_double 3.0 ~-.3.0;
		test "string" "Ljava/lang/String;" push_string call_string read_field_string write_field_string
			read_field_static_string write_field_static_string Jarray.create_string Jarray.get_string
			Jarray.set_string "4" "-4";
		test "string" "Ljava/lang/String;" push_string_opt call_string_opt read_field_string_opt
			write_field_string_opt read_field_static_string_opt write_field_static_string_opt
			Jarray.create_string Jarray.get_string_opt Jarray.set_string_opt (Some "4") None;
		test "boolean" "Z" push_bool call_bool read_field_bool write_field_bool read_field_static_bool
		write_field_static_bool Jarray.create_bool Jarray.get_bool Jarray.set_bool true false;
		test "char" "C" push_char call_char read_field_char write_field_char read_field_static_char
			write_field_static_char Jarray.create_char Jarray.get_char Jarray.set_char '5' 'x';
		test "byte" "B" push_byte call_byte read_field_byte write_field_byte read_field_static_byte
			write_field_static_byte Jarray.create_byte Jarray.get_byte Jarray.set_byte 6 ~-6;
		test "short" "S" push_short call_short read_field_short write_field_short read_field_static_short
			write_field_static_short Jarray.create_short Jarray.get_short Jarray.set_short 7 ~-7;
		test "int32" "I" push_int32 call_int32 read_field_int32 write_field_int32 read_field_static_int32
			write_field_static_int32 Jarray.create_int32 Jarray.get_int32 Jarray.set_int32 (Int32.of_int 8)
			(Int32.of_int ~-8);
		test "int64" "J" push_long call_long read_field_long write_field_long read_field_static_long
			write_field_static_long Jarray.create_long Jarray.get_long Jarray.set_long (Int64.of_int 9)
			(Int64.of_int ~-9);
		test "value" "Ljuloo/javacaml/Value;" push_value call_value read_field_value write_field_value
			read_field_static_value write_field_static_value Jarray.create_value Jarray.get_value
			Jarray.set_value (1, 2) (~-1, ~-2);
		test "value" "Ljuloo/javacaml/Value;" push_value_opt call_value_opt read_field_value_opt
			write_field_value_opt read_field_static_value_opt write_field_static_value_opt
			Jarray.create_value Jarray.get_value_opt Jarray.set_value_opt (Some (1, 2)) None
	in

	test_id_all ();

	let samples = 3 in
	let sum = ref 0. in
	for i = 0 to samples - 1 do
		let t = Unix.gettimeofday () in
		for i = 0 to 500 do test_id_all () done;
		let t = Unix.gettimeofday () -. t in
		sum := t +. !sum
	done;
	Printf.printf "Test times: %f\n" (!sum /. (float samples));

	for i = 0 to 500 do
		begin try ignore @@ find_class "unknown"; assert false with Not_found -> () end;
		begin try ignore @@ get_meth cls "unknown" "()V"; assert false with Not_found -> () end;
		begin try ignore @@ get_meth_static cls "unknown" "()V"; assert false with Not_found -> () end;
		begin try ignore @@ get_constructor cls "(IIII)V"; assert false with Not_found -> () end;
		begin try ignore @@ get_field cls "unknown" "()V"; assert false with Not_found -> () end;
		begin try ignore @@ get_field_static cls "unknown" "()V"; assert false with Not_found -> () end
	done;

	let id_obj_m = get_meth cls "test_id" "(Ljava/lang/Object;)Ljava/lang/Object;" in

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
		assert (Jthrowable.get_message ex = "test");
		assert (Jthrowable.get_localized_message ex = "test")
	end;

	let arr () = Jarray.(of_obj (to_obj (create_object cls null 1))) in

	for i = 0 to 500 do
		begin try ignore (Jarray.get_string (arr ()) 0); assert false with Failure _ -> () end;
		assert (Jarray.get_string_opt (arr ()) 0 = None);
		begin try ignore (Jarray.get_value (arr ()) 0); assert false with Failure _ -> () end;
		assert (Jarray.get_value_opt (arr ()) 0 = None);
		begin try ignore (Jarray.get_array (arr ()) 0); assert false with Failure _ -> () end
	done;

	assert (instanceof obj cls);
	assert (not (instanceof obj (find_class "java/lang/String")));
	assert (sameobject obj obj);
	assert (sameobject null null);
	assert (not (sameobject obj null));
	assert (not (sameobject null obj));
	assert (sameobject (Obj.magic (objectclass obj)) (Obj.magic cls));
	begin try ignore (objectclass null); assert false with Failure _ -> () end;

	let m_rec_b = get_meth_static cls "test_rec_b" "(Ljava/lang/String;)Ljava/lang/String;" in

	let test_rec_a s =
		let s = s ^ "a" in
		if String.length s >= 120 then s
		else begin
			push_string s;
			call_static_string cls m_rec_b
		end
	in
	Callback.register "test_rec_a" test_rec_a;

	print_endline @@ test_rec_a "-> ";

	()

class%java test "camljava.test.Test" =
object

	val a : int = "a"
	val b : string = "b"

	initializer (create_default : _)
	initializer (create : int -> string -> _)

	method test : int -> int -> int = "test"
	method raise : unit = "raise"

	method [@static] test_rec_b : string -> string = "test_rec_b"

	val [@static] mutable test_f : int = "test_f"
	method [@static] test_static : int -> int = "test"

end

module Java_lang =
struct

	class%java string_builder "java.lang.StringBuilder" =
	object

		initializer (create : _)

		method append_char : char -> string_builder = "append"
		method append_int : int -> string_builder = "append"
		method append_string : string -> string_builder = "append"

		method to_string : jstring = "toString"

	end

	and jstring "java.lang.String" =
	object

		initializer (create : string -> _)
		initializer (empty : _)
		initializer (of_builder : string_builder -> _)

		method char_at : int -> char = "charAt"

		method [@static] of_bool : bool -> jstring = "valueOf"
		method [@static] of_int : int -> jstring = "valueOf"
		method [@static] of_char : char -> jstring = "valueOf"

		method to_string : string = "toString"

	end

	class%java jfloat "java.lang.Float" =
	object

		initializer (create : double -> _)

		method to_string : string = "toString"

		method float_value : float = "floatValue"

		method [@static] of_string : jstring -> jfloat = "valueOf"

	end

end

let test_ppx () =
	let _ = Test.create_default () in
	let obj = Test.create 11 "x" in
	assert (Test.get'a obj = 11);
	assert (Test.get'b obj = "x");
	assert (Test.test obj 5 6 = 11);
	begin try Test.raise obj; assert false with Java.Exception _ -> () end;
	let test_rec_a s =
		if String.length s >= 10 then s
		else Test.test_rec_b s
	in
	Callback.register "test_rec_a" test_rec_a;
	assert (Test.test_rec_b "~" = "~bbbbbbbbb");
	let save = Test.get'test_f () in
	Test.set'test_f 0;
	assert (Test.test_static 5 = 5);
	Test.set'test_f save;
	let open Java_lang in
	let builder = String_builder.create () in
	ignore (String_builder.append_char builder '0');
	ignore (String_builder.append_string builder ".4");
	ignore (String_builder.append_int builder 2);
	let str = String_builder.to_string builder in
	assert (Jstring.char_at str 0 = '0');
	assert (Jstring.to_string str = "0.42");
	assert (Jstring.to_string (Jstring.of_bool true) = "true");
	assert (Jstring.to_string (Jstring.of_int 783213) = "783213");
	assert (Jstring.to_string (Jstring.of_char '`') = "`");
	let flt = Jfloat.of_string (Jstring.of_builder builder) in
	assert (Jfloat.to_string flt = "0.42");
	()

let () = Callback.register "camljava_do_test" test

let test_javacaml () =
	let cls = Jclass.find_class "javacaml/test/Test" in
	let m_do_test = Jclass.get_meth_static cls "do_test" "()V" in
	Java.call_static_void cls m_do_test

let () =
	if Sys.argv.(0) <> "" then begin
		try
			for i = 0 to 10 do
				test ();
				test_javacaml ();
				test_ppx ()
			done
		with Java.Exception e ->
			Jthrowable.print_stack_trace e;
			failwith ""
	end
