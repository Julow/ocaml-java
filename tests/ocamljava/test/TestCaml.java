package ocamljava.test;

import juloo.javacaml.Caml;
import juloo.javacaml.Value;

public class TestCaml
{
	public int a;
	public String b;

	public TestCaml()
	{
		this(42, "abc");
	}

	public TestCaml(int a, String b)
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

	public static void		set_test_array_int(int[] v) { test_array_int = v; }
	public static void		set_test_array_float(float[] v) { test_array_float = v; }
	public static void		set_test_array_double(double[] v) { test_array_double = v; }
	public static void		set_test_array_string(String[] v) { test_array_string = v; }
	public static void		set_test_array_boolean(boolean[] v) { test_array_boolean = v; }
	public static void		set_test_array_char(char[] v) { test_array_char = v; }
	public static void		set_test_array_byte(byte[] v) { test_array_byte = v; }
	public static void		set_test_array_short(short[] v) { test_array_short = v; }
	public static void		set_test_array_int32(int[] v) { test_array_int32 = v; }
	public static void		set_test_array_int64(long[] v) { test_array_int64 = v; }
	public static void		set_test_array_object(Object[] v) { test_array_object = v; }
	public static void		set_test_array_value(Value[] v) { test_array_value = v; }

	public static int[]		test_array_int;
	public static float[]	test_array_float;
	public static double[]	test_array_double;
	public static String[]	test_array_string;
	public static boolean[]	test_array_boolean;
	public static char[]	test_array_char;
	public static byte[]	test_array_byte;
	public static short[]	test_array_short;
	public static int[]		test_array_int32;
	public static long[]	test_array_int64;
	public static Object[]	test_array_object;
	public static Value[]	test_array_value;

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

	public static int[][]	test_array_array;

	public static void		set_array_array(int[][] a)
	{
		test_array_array = a;
	}

	public static int[][]	get_array_array()
	{
		return test_array_array;
	}

	public static int		sum(int[] a)
	{
		int sum = 0;
		for (int i = 0; i < a.length; i++)
			sum += a[i];
		return sum;
	}

	public static String	get_string()
	{
		return "!5Aa¥¼ÑñĄąĲĳΎΔδϠ߄ߐ߰ߋ߹᱕ᱝᱰ᱿㐅㒅㝬㿜가뮀윸힣🀀🀍🀒🀝𪜀𪮘𪾀𫜴😁😏✈🚑0⃣";
	}

	public static String	wrap_string(String s)
	{
		return "[" + s + "]";
	}

	public static void		runrun(Runnable r)
	{
		r.run();
	}

	public static int		numrun = 0;

	public static Runnable	getrun()
	{
		return new Runnable() {
			public void run()
			{
				numrun++;
			}
		};
	}
}
