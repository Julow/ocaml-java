package javacaml.test;

import juloo.javacaml.Caml;
import juloo.javacaml.Callback;
import juloo.javacaml.Value;
import juloo.javacaml.CallbackNotFoundException;
import juloo.javacaml.CamlException;
import juloo.javacaml.InvalidMethodIdException;

public class Test
{
	private static void test()
	{
// getCallback
		Caml.getCallback("test_function");
		try { Caml.getCallback(null); assert false; }
		catch (NullPointerException e) {}
		try { Caml.getCallback("not found"); assert false; }
		catch (CallbackNotFoundException e) {}
// hashVariant
		Caml.hashVariant("test");
		try { Caml.hashVariant(null); assert false; }
		catch (NullPointerException e) {}

// function
		Caml.function(Caml.getCallback("test_function"));
		Caml.argUnit();
		Caml.callUnit();

		try { Caml.function((Value)null); assert false; }
		catch (NullPointerException e) {}
		try { Caml.function((Callback)null); assert false; }
		catch (NullPointerException e) {}
		try { Caml.argString(null); assert false; }
		catch (NullPointerException e) {}
		try { Caml.argValue(null); assert false; }
		catch (NullPointerException e) {}

// CamlException
		try
		{
			Caml.function(Caml.getCallback("test_raise"));
			Caml.argUnit();
			Caml.callUnit();
			assert false;
		} catch (CamlException e) {}

// arg*/call*
		Caml.function(Caml.getCallback("test_int"));
		Caml.argInt(12);
		Caml.argInt(3);
		assert Caml.callInt() == 15;

		Caml.function(Caml.getCallback("test_float"));
		Caml.argFloat(1.0);
		Caml.argFloat(1.0);
		assert Caml.callFloat() == 2.0;

		Caml.function(Caml.getCallback("test_string"));
		Caml.argString("ab");
		Caml.argString("cd");
		assert Caml.callString().equals("abcd");

		Caml.function(Caml.getCallback("test_bool"));
		Caml.argBool(true);
		Caml.argBool(true);
		assert Caml.callBool();

		Caml.function(Caml.getCallback("test_bool"));
		Caml.argBool(true);
		Caml.argBool(false);
		assert !Caml.callBool();

		Caml.function(Caml.getCallback("test_bool"));
		Caml.argBool(true);
		Caml.argBool(false);
		assert !Caml.callBool();

		Caml.function(Caml.getCallback("test_int32"));
		Caml.argInt32(40);
		Caml.argInt32(55);
		assert Caml.callInt32() == 95;

		Caml.function(Caml.getCallback("test_int64"));
		Caml.argInt64(14);
		Caml.argInt64(3);
		assert Caml.callInt64() == 17;

// argValue/callValue
		Caml.function(Caml.getCallback("get_value"));
		Caml.argUnit();
		Value v = Caml.callValue();

		Caml.function(Caml.getCallback("test_a"));
		Caml.argValue(v);
		assert Caml.callString().equals("a");

		Caml.function(Caml.getCallback("test_b"));
		Caml.argValue(v);
		assert Caml.callString().equals("b");

		Caml.function(Caml.getCallback("test_a"));
		Caml.argValue(v);
		Value a = Caml.callValue();
		Caml.function(Caml.getCallback("test_b"));
		Caml.argValue(v);
		Value b = Caml.callValue();
		Caml.function(Caml.getCallback("test_string"));
		Caml.argValue(a);
		Caml.argValue(b);
		assert Caml.callString().equals("ab");

// method
		Caml.function(Caml.getCallback("get_obj"));
		Caml.argUnit();
		Value obj = Caml.callValue();

		Caml.method(obj, Caml.hashVariant("test"));
		Caml.callUnit();

		Caml.method(obj, Caml.hashVariant("test_int"));
		Caml.argInt(1);
		Caml.argInt(2);
		assert Caml.callInt() == 3;

		try { Caml.method(obj, Caml.hashVariant("invalid")); assert false; }
		catch (InvalidMethodIdException e) {}
		try { Caml.method(null, 0); assert false; }
		catch (NullPointerException e) {}

// currying
		Caml.function(Caml.getCallback("test_int"));
		Caml.argInt(1);
		Value plusOne = Caml.callValue();

		Caml.function(plusOne);
		Caml.argInt(1);
		assert Caml.callInt() == 2;

		System.out.println("Javacaml Ok");
	}

	public static void do_test() throws Exception
	{
		try
		{
			assert false;
			throw new Exception("Cannot test, asserts are disabled");
		}
		catch (AssertionError e) {}
		test();
	}

	public static void main(String[] args)
	{
		try
		{
			System.loadLibrary("test");
			Caml.startup();
			do_test();
		}
		catch (Exception e)
		{
			System.out.println("ERROR");
			e.printStackTrace();
			assert false;
		}
	}
}
