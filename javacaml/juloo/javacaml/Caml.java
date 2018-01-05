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
	 *
	 * Throws NullPointerException if `name` is null,
	 *   NamedValueNotFoundException if `name` does not refer to any value
	 */
	public static native NamedValue getNamedValue(String name);

	/**
	 * Returns the hash value corresponding
	 *  to a variant constructor or a method `name`.
	 *
	 * The same name will always return the same value.
	 *
	 * > `caml_hash_variant`
	 *
	 * Throws NullPointerException if `name` is null
	 */
	public static native int hashVariant(String variantName);

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
}
