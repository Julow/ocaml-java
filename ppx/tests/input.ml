class%java a "a.A" =
object
	method a : unit = "a"
end

class%java test "test.Test" =
object

	inherit a
	inherit b
	inherit c

	val a : a = "a"
	val mutable b : test option value option = "b"
	val [@static] mutable c : int = "c"

	method a : a -> a = "a"
	method b : unit = "b"
	method c : int -> bool -> byte -> short -> int32 -> long
		-> char -> float -> double -> string -> string option
		-> (a * b -> c) value -> (a b c * [> `D of e]) value option
		-> unit = "c"
	method d : test -> test = "d"
	method [@static] f : test -> unit = "f"
	method [@static] g : Abc.def -> Ghi.Jkl.mno -> pqr = "g"

	method h : int array -> int array array option -> int Java.obj array = "h"
	method i : int array value array array array array option
		-> byte array -> short array option -> double array array = "i"
	method j : _ Java.obj -> int = "j"

	initializer (create_default : _)
	initializer (create : a -> test value -> int -> _)

end

class%java string_builder "java.lang.StringBuilder" =
object
	initializer (create : _)
	method to_string : jstring = "toString"
end

and jstring "java.lang.String" =
object
	initializer (of_builder : string_builder -> _)
	method to_string : string = "toString"
end

class%java jfloat "java.lang.Float" =
object
	method float_value : float = "floatValue"
	method [@static] of_string : jstring -> jfloat = "valueOf"
end
