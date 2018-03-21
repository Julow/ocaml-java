package juloo.javacaml;

/**
 * Hold an OCaml value (anything: an int, an object, etc.)
 */
public class Value
{
	protected long value;

	protected Value(long v) { this.value = v; }

	protected native void release();

	protected void finalize()
	{
		release();
	}
}
