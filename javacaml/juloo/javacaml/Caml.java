package juloo.javacaml;

public class Caml
{
	private Caml() {}

	/**
	 * Initialize the library and OCaml.
	 * Must be called once, before anything else
	 *
	 * > `caml_startup`
	 */
	public static native void startup();

	/**
	 * Like `startup`, without calling `caml_startup`
	 */
	public static native void init();

	/**
	 * Returns the value registered with `Callback.register` on the OCaml side.
	 *
	 * > `caml_named_value`
	 */
	public static native NamedValue getNamedValue(String name)
		throws NullPointerException, // if `name` is null
			NamedValueNotFoundException; // if `name` is not registered

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
	 * This function begins the calling of a function
	 *
	 * Use the `arg<Type>` functions to push the arguments
	 *
	 * Then, call the function with the `call_`* functions
	 */
	public static native void function(long value);

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
	 */
	public static native void argUnit();
	public static native void argInt(int v);
	public static native void argFloat(double v);
	public static native void argString(String v);
	public static native void argBool(boolean v);
	public static native void argInt32(int v);
	public static native void argInt64(long v);

	/**
	 * Stop the calling of a function and calls it.
	 * Same convertions as the `arg` functions
	 *
	 * Throws CamlException if an OCaml exception is raised
	 */
	public static native void callUnit() throws CamlException;
	public static native int callInt() throws CamlException;
	public static native double callFloat() throws CamlException;
	public static native String callString() throws CamlException;
	public static native boolean callBool() throws CamlException;
	public static native int callInt32() throws CamlException;
	public static native long callInt64() throws CamlException;

	/**
	 * Class that hold the value returned by get_value
	 * The `get` method returns the expected value
	 */
	public static class NamedValue
	{
		private long closure;
		protected NamedValue(long c) { closure = c; }
		public native long get();
	}

	public static class NamedValueNotFoundException extends Exception
	{
		public NamedValueNotFoundException(String name)
		{
			super("Named value `" + name + "` not found");
		}
	}

	public static class CamlException extends Exception
	{
		public CamlException(String msg)
		{
			super("Uncaught OCaml exception: `" + msg + "`");
		}
	}
}
