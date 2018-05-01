class%java test "ocamljava.test.TestCaml" =
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

	val [@static] mutable array_array : int array array option = "test_array_array"
	method [@static] set_array_array : int array array -> unit = "set_array_array"
	method [@static] get_array_array : int array array = "get_array_array"
	method [@static] sum : int array -> int = "sum"

	method [@static] get_string : string = "get_string"
	method [@static] wrap_string : string -> string = "wrap_string"

	val [@static] mutable numrun : int = "numrun"
	method [@static] runrun : runnable -> unit = "runrun"
	method [@static] getrun : runnable = "getrun"

end

module Java_lang =
struct

	class%java jobject "java.lang.Object" =
	object
		method equals : jobject -> bool = "equals"
		method to_string : jstring = "toString"
	end

	and string_builder "java.lang.StringBuilder" =
	object
		inherit jobject
		initializer (create : _)
		method append_char : char -> string_builder = "append"
		method append_int : int -> string_builder = "append"
		method append_string : string -> string_builder = "append"
	end

	and jstring "java.lang.String" =
	object
		inherit jobject
		initializer (create : string -> _)
		initializer (empty : _)
		initializer (of_builder : string_builder -> _)
		method char_at : int -> char = "charAt"
		method contains : char_sequence -> bool = "contains"
		method sub_sequence : int -> int -> char_sequence = "subSequence"
		method [@static] of_bool : bool -> jstring = "valueOf"
		method [@static] of_int : int -> jstring = "valueOf"
		method [@static] of_char : char -> jstring = "valueOf"
		method to_string : string = "toString"
	end

	class%java jfloat "java.lang.Float" =
	object
		inherit jobject
		initializer (create : double -> _)
		method to_string : string = "toString"
		method float_value : float = "floatValue"
		method [@static] of_string : jstring -> jfloat = "valueOf"
	end

end

let test_charsequence () =
	let open Java_lang in
	let s = Jstring.create "0123456789" in
	assert (Jstring.contains s "234");
	assert (not (Jstring.contains s "432"));
	assert (Jstring.sub_sequence s 5 8 = "567")

let test_runnable () =
	Test.set'numrun 0;
	let r = Test.getrun () in
	Test.runrun r;
	assert (Test.get'numrun () = 1)

let run () =
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
	let str = Jobject.to_string builder in
	assert (Jstring.char_at str 0 = '0');
	assert (Jstring.to_string str = "0.42");
	assert (Jobject.equals str (Jstring.create "0.42"));
	assert (Jstring.to_string (Jstring.of_bool true) = "true");
	assert (Jstring.to_string (Jstring.of_int 783213) = "783213");
	assert (Jstring.to_string (Jstring.of_char '`') = "`");
	let flt = Jfloat.of_string (Jstring.of_builder builder) in
	assert (Jfloat.to_string flt = "0.42");

	let len = 10 in
	let a = Jarray.create_array (Jclass.find_class "[I") None len in
	for i = 0 to len - 1 do
		let a' = Jarray.create_int len in
		for i = 0 to len - 1 do Jarray.set_int a' i (i*2) done;
		Jarray.set_array a i a'
	done;
	assert (Test.get'array_array () = None);
	begin try ignore (Test.get_array_array ()); assert false with Failure _ -> () end;
	Test.set_array_array a;
	begin match Test.get'array_array () with Some _ -> () | None -> assert false end;
	let sums = Jarray.create_int len in
	for i = 0 to len - 1 do
		let a = Jarray.get_array a i in
		Jarray.set_int sums i (Test.sum a)
	done;
	assert (Test.sum sums = 900);
	Test.set'array_array None;

	let s = "!5Aa¥¼ÑñĄąĲĳΎΔδϠ߄ߐ߰ߋ߹᱕ᱝᱰ᱿㐅㒅㝬㿜가뮀윸힣🀀🀍🀒🀝𪜀𪮘𪾀𫜴😁😏✈🚑0⃣" in
	let s' = "\x21\x35\x41\x61\xC2\xA5\xC2\xBC\xC3\x91\xC3\xB1\xC4\x84\xC4\x85\xC4\xB2\xC4\xB3\xCE\x8E\xCE\x94\xCE\xB4\xCF\xA0\xDF\x84\xDF\x90\xDF\xB0\xDF\x8B\xDF\xB9\xE1\xB1\x95\xE1\xB1\x9D\xE1\xB1\xB0\xE1\xB1\xBF\xE3\x90\x85\xE3\x92\x85\xE3\x9D\xAC\xE3\xBF\x9C\xEA\xB0\x80\xEB\xAE\x80\xEC\x9C\xB8\xED\x9E\xA3\xED\xA0\xBC\xED\xB0\x80\xED\xA0\xBC\xED\xB0\x8D\xED\xA0\xBC\xED\xB0\x92\xED\xA0\xBC\xED\xB0\x9D\xED\xA1\xA9\xED\xBC\x80\xED\xA1\xAA\xED\xBE\x98\xED\xA1\xAB\xED\xBE\x80\xED\xA1\xAD\xED\xBC\xB4\xED\xA0\xBD\xED\xB8\x81\xED\xA0\xBD\xED\xB8\x8F\xE2\x9C\x88\xED\xA0\xBD\xED\xBA\x91\x30\xE2\x83\xA3" in
	(if s <> s' then print_endline "wtf");
	let test_string s =
		assert ("[[" ^ s ^ "]]" = (Test.wrap_string (Test.wrap_string s)))
	in
	test_string (Test.get_string ());
	test_string s';

	test_charsequence ();
	test_runnable ();

	()
