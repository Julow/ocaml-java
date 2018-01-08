package juloo.javacaml;

/**
 * Hold an OCaml callback
 * Can be obtained with `Caml.getCallback`
 */
public class Callback
{
	private long closure;
	private Callback(long c) { closure = c; }
}
