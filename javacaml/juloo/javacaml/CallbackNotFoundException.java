package juloo.javacaml;

/**
 * Thrown by `Caml.getCallback`
 */
public class CallbackNotFoundException extends RuntimeException
{
	public CallbackNotFoundException(String name)
	{
		super("Callback `" + name + "` not found");
	}
}
