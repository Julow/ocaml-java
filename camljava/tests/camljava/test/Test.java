package camljava.test;

import juloo.javacaml.Caml;
import juloo.javacaml.Value;

public class Test
{
	public int a;
	public String b;

	public Test()
	{
		this(42, "abc");
	}

	public Test(int a, String b)
	{
		this.a = a;
		this.b = b;

		test_attr_int = test_get_int();
		test_attr_float = test_get_float();
		test_attr_double = test_get_double();
		test_attr_string = test_get_string();
		test_attr_boolean = test_get_boolean();
		test_attr_char = test_get_char();
		test_attr_byte = test_get_byte();
		test_attr_short = test_get_short();
		test_attr_int32 = test_get_int32();
		test_attr_int64 = test_get_int64();
		test_attr_object = test_get_object();
		test_attr_value = test_get_value();
	}

	public int test(int a, int b)
	{
		return a + b;
	}

	public int test_get_int() { return 1; }
	public float test_get_float() { return 2.0f; }
	public double test_get_double() { return 3.0; }
	public String test_get_string() { return "4"; }
	public boolean test_get_boolean() { return true; }
	public char test_get_char() { return '5'; }
	public byte test_get_byte() { return 6; }
	public short test_get_short() { return 7; }
	public int test_get_int32() { return 8; }
	public long test_get_int64() { return 9; }
	public Object test_get_object() { return new Object(); }
	public Value test_get_value() {
		Caml.function(Caml.getCallback("get_int_pair"));
		Caml.argUnit();
		return Caml.callValue();
	}

	public int test_id(int v) { return v; }
	public float test_id(float v) { return v; }
	public double test_id(double v) { return v; }
	public String test_id(String v) { return v; }
	public boolean test_id(boolean v) { return v; }
	public char test_id(char v) { return v; }
	public byte test_id(byte v) { return v; }
	public short test_id(short v) { return v; }
	public long test_id(long v) { return v; }
	public Object test_id(Object v) { return v; }
	public Value test_id(Value v) { return v; }

	public void raise() throws Exception
	{
		throw new Exception("test");
	}

	public static String test_rec_b(String s)
	{
		String s_ = s + "b";

		Caml.function(Caml.getCallback("test_rec_a"));
		Caml.argString(s_);
		return Caml.callString();
	}

	public static int test_f = 42;

	public static int test(int a)
	{
		return a - test_f;
	}

	public int		test_attr_int;
	public float	test_attr_float;
	public double	test_attr_double;
	public String	test_attr_string;
	public boolean	test_attr_boolean;
	public char		test_attr_char;
	public byte		test_attr_byte;
	public short	test_attr_short;
	public int		test_attr_int32;
	public long		test_attr_int64;
	public Object	test_attr_object;
	public Value	test_attr_value;


	public static int		test_static_int = 1;
	public static float		test_static_float = 2.0f;
	public static double	test_static_double = 3.0;
	public static String	test_static_string = "4";
	public static boolean	test_static_boolean = true;
	public static char		test_static_char = '5';
	public static byte		test_static_byte = 6;
	public static short		test_static_short = 7;
	public static int		test_static_int32 = 8;
	public static long		test_static_int64 = 9;
	public static Object	test_static_object = new Object();
	public static Value		test_static_value;

	public static final int		test_const_int = 1;
	public static final float	test_const_float = 2.0f;
	public static final double	test_const_double = 3.0;
	public static final String	test_const_string = "4";
	public static final boolean	test_const_boolean = true;
	public static final char	test_const_char = '5';
	public static final byte	test_const_byte = 6;
	public static final short	test_const_short = 7;
	public static final int		test_const_int32 = 8;
	public static final long	test_const_int64 = 9;
	public static final Object	test_const_object = new Object();
	public static final Value	test_const_value;

	static {
		Caml.function(Caml.getCallback("get_int_pair"));
		Caml.argUnit();
		test_const_value = Caml.callValue();
		test_static_value = test_const_value;
	}
}
