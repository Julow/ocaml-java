package juloo.javacaml;

/**
 * Thrown by the `Caml.call`* functions after an uncaught OCaml exception
 */
public class CamlException extends RuntimeException
{
	public CamlException(String msg, Throwable cause, StackTraceElement[] caml_stack)
	{
		super("Uncaught OCaml exception: `" + msg + "`");
		setStackTrace(concat_stacks(caml_stack, getStackTrace()));
		if (cause != null)
			initCause(cause);
	}

	static StackTraceElement[] concat_stacks(StackTraceElement[] a,
			StackTraceElement[] b)
	{
		StackTraceElement[] c = new StackTraceElement[a.length + b.length];
		System.arraycopy(a, 0, c, 0, a.length);
		System.arraycopy(b, 0, c, a.length, b.length);
		return c;
	}
}
