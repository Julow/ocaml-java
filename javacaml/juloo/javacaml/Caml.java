package juloo.javacaml;

/**
 * Interfaces OCaml
 * Unsafe
 */
public class Caml
{
	private Caml() {}

	/**
	 * Initialize the library and OCaml.
	 * Must be called once, before anything else
	 *
	 * Throws CamlException if an OCaml exception is raised
	 * May throws any exception (with Jthrowable.throw/throw_new)
	 *
	 * With OCaml version < 4.05,
	 *  the program will exit if an exception is raised
	 *
	 * > `caml_startup`
	 */
	public static native void startup();

	/**
	 * Returns the value registered with `Callback.register` on the OCaml side.
	 *
	 * > `caml_named_value`
	 */
	public static native Callback getCallback(String name)
		throws NullPointerException, // if `name` is null
			CallbackNotFoundException; // if `name` is not registered

	/**
	 * Returns the hash value corresponding
	 *  to a variant constructor or a method `name`.
	 *
	 * The same name will always return the same value.
	 *
	 * > `caml_hash_variant`
	 */
	public static native int hashVariant(String variantName)
		throws NullPointerException; // if `name` is null

	/**
	 * Begin the calling of a function
	 *
	 * To call a function:
	 *  Caml.arg<Type>: Push an argument
	 *  Caml.call<Type>: Perform the call and collect the result
	 *
	 * The arguments types must match the OCaml function
	 * and there must not be more arguments than expected
	 *  otherwise, a crash may happen
	 * If an argument is missing, currying occur:
	 *  the result is a function taking the remaining arguments
	 *
	 * OCaml exception are handled and re-thrown on the Java side
	 */
	public static native void function(Value function)
		throws NullPointerException; // if `function` is null
	public static native void function(Callback callback)
		throws NullPointerException; // if `callback` is null

	/**
	 * Begin the calling of a method
	 * Same as function() but for an object's method
	 *
	 * The `methodId` can be obtained with `Caml.hashVariant`
	 */
	public static native void method(Value object, int methodId)
		throws NullPointerException, // if `object` is null
			InvalidMethodIdException;
				// if `methodId` does not refer to any object's method

	/**
	 * Adds an argument onto the argument stack
	 *
	 * | Function		| Java type		| OCaml type
	 * | ---			| ---			| ---
	 * | argUnit		| 				| unit
	 * | argInt			| int			| int (tagged 31-bit)
	 * | argFloat		| double		| float
	 * | argString		| String		| string (no decoding)
	 * | argBool		| boolean		| bool
	 * | argInt32		| int			| int32
	 * | argInt64		| long			| int64
	 * | argValue		| Value			| *
	 * | argObject		| Object		| Java.obj
	 */
	public static native void argUnit()
		throws ArgumentStackOverflowException;
	public static native void argInt(int v)
		throws ArgumentStackOverflowException;
	public static native void argFloat(double v)
		throws ArgumentStackOverflowException;
	public static native void argString(String v)
		throws NullPointerException, // if `v` is null
			ArgumentStackOverflowException;
	public static native void argBool(boolean v)
		throws ArgumentStackOverflowException;
	public static native void argInt32(int v)
		throws ArgumentStackOverflowException;
	public static native void argInt64(long v)
		throws ArgumentStackOverflowException;
	public static native void argValue(Value v)
		throws NullPointerException, // if `v` is null
			ArgumentStackOverflowException;
	public static native void argObject(Object v)
		throws ArgumentStackOverflowException;

	/**
	 * Stop the calling of a function and calls it.
	 * Same convertions as the `arg` functions
	 *
	 * Throws CamlException if an OCaml exception is raised
	 * May throws any exception (with Jthrowable.throw/throw_new)
	 */
	public static native void callUnit() throws CamlException;
	public static native int callInt() throws CamlException;
	public static native double callFloat() throws CamlException;
	public static native String callString() throws CamlException;
	public static native boolean callBool() throws CamlException;
	public static native int callInt32() throws CamlException;
	public static native long callInt64() throws CamlException;
	public static native Value callValue() throws CamlException;
	public static native Object callObject() throws CamlException;
}
