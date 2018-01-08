package juloo.javacaml;

/**
 * Hold an OCaml value (anything: an int, an object, etc.)
 */
public class Value
{
	private long value;

	private Value(long v) { this.value = v; }

	private native void release();

	protected void finalize()
	{
		release();
	}
}
