package test;

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

	public void raise() throws Exception
	{
		throw new Exception("test");
	}

	public static int test_f = 42;

	public static int test(int a)
	{
		return a - test_f;
	}
}
