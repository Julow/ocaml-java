class%java a "a.A" =
object
	method a : unit = "a"
end

class%java test "test.Test" =
object

	val a : a = "a"
	val mutable b : test option value option = "b"

	method a : a -> a = "a"
	method b : unit = "b"
	method c : int -> bool -> byte -> short -> int32 -> long
		-> char -> float -> double -> string -> string option
		-> (a * b -> c) value -> (a b c * [> `D of e]) value option
		-> unit = "c"
	method d : test -> test = "d"
	method e : test option -> test option = "e"

end
