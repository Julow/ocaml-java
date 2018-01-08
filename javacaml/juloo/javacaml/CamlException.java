package juloo.javacaml;

/**
 * Thrown by the `Caml.call`* functions after an uncaught OCaml exception
 */
public class CamlException extends Exception
{
	public CamlException(String msg)
	{
		super("Uncaught OCaml exception: `" + msg + "`");
	}
}
