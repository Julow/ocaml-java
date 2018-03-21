package juloo.javacaml;

/**
 * Hold a value of type (unit -> unit)
 * Can be instantiated with `Jrunnable.create`
 */
public class RunnableValue extends Value
	implements Runnable
{
	protected RunnableValue(long v) { super(v); }

	@Override
	public void run()
	{
		Caml.function(this);
		Caml.argUnit();
		Caml.callUnit();
	}
}
