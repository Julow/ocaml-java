#include <stddef.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/alloc.h>

#define JNI_VERSION JNI_VERSION_1_4

static JNIEnv *env;

/*
** ========================================================================== **
** OCaml value that represent a `jobject` pointer or the `null` value
** -
** The `jobject` is registered as global ref
** and automatically released when it is garbage collected
** -
** Java_obj_val(v)		Returns the `jobject` pointer, must not be `null`
** Java_null_val		`null` value
** alloc_java_obj(obj)	Allocates the value, `obj` is registered as global ref
*/

#define Java_obj_val(v)	(*(jobject*)Data_custom_val(v))

#define Java_null_val	(Val_long(0))

static void java_obj_finalize(value v)
{
	if (v != Java_null_val)
		(*env)->DeleteGlobalRef(env, Java_obj_val(v));
}

static int java_obj_compare(value a, value b)
{
	intnat a_;
	intnat b_;

	a_ = (a == Java_null_val) ? 0 : (intnat)Java_obj_val(a);
	b_ = (b == Java_null_val) ? 0 : (intnat)Java_obj_val(b);
	return a_ - b_;
}

static struct custom_operations java_obj_custom_ops = {
	.identifier = "ocaml_java__obj",
	.finalize = java_obj_finalize,
	.compare = java_obj_compare,
	.compare_ext = custom_compare_ext_default,
	.hash = custom_hash_default,
	.serialize = custom_serialize_default,
	.deserialize = custom_deserialize_default
};

static value alloc_java_obj(jobject object)
{
	value v;

	if (object == NULL)
		return Java_null_val;
	v = alloc_custom(&java_obj_custom_ops, sizeof(jobject), 0, 1);
	object = (*env)->NewGlobalRef(env, object);
	*(jobject*)Data_custom_val(v) = object;
	return v;
}

/*
** ========================================================================== **
** Exceptions
*/

static value *java_exception;

// Check if a Java exception has been thrown
// if there is, raises Java.Exception
static void check_exceptions(void)
{
	jthrowable exn;

	exn = (*env)->ExceptionOccurred(env);
	if (exn == NULL) return ;
	(*env)->ExceptionClear(env);
	caml_raise_with_arg(*java_exception, alloc_java_obj(exn));
}

static void init_exception(void)
{
	java_exception = caml_named_value("Java.Exception");
}

/*
** ========================================================================== **
** Calling
** -
** `arg_stack` represents the argument stack
** `perform_type` stores the type of call
** `local_ref_stack` stores references to objects allocated in `arg_` functions
**  It is `NULL`-terminated
**  Local references are deleted after the method as been called
** -
** Perform types and begining of the stack:
**  - PERFORM_NONVIRTUAL_CALL (CallNonvirtual*Method*)
**    arg_stack (3): object, class, methodId
**  - PERFORM_STATIC_CALL (CallStatic*Method*)
**    arg_stack (2): class, methodId
**  - PERFORM_CALL (Call*Method*)
**    arg_stack (2): object, methodId
**  - PERFORM_INIT (NewObject*)
**    arg_stack (2): class, methodId
*/

#define ARG_STACK_MAX_SIZE	16
#define LOCALREF_STACK_MAX_SIZE	32

enum e_perform_type
{
	PERFORM_NONVIRTUAL_CALL,
	PERFORM_STATIC_CALL,
	PERFORM_CALL,
	PERFORM_INIT,
	PERFORM_FIELD,
	PERFORM_FIELD_STATIC,
};

static enum e_perform_type perform_type;
static jvalue arg_stack[ARG_STACK_MAX_SIZE];
static int arg_count;

// Local refs

static jobject local_ref_stack[LOCALREF_STACK_MAX_SIZE];
static int local_ref_count = 0;

static void clear_local_refs(void)
{
	int i;

	for (i = 0; i < local_ref_count; i++)
		(*env)->DeleteLocalRef(env, local_ref_stack[i]);
	local_ref_count = 0;
}

static void push_local_ref(jobject obj)
{
	if (local_ref_count >= LOCALREF_STACK_MAX_SIZE)
		caml_failwith("Local ref stack overflow");
	local_ref_stack[local_ref_count] = obj;
	local_ref_count++;
}

// Calling

value ocaml_java__calling_meth(value obj, value meth)
{
	if (obj == Java_null_val)
		caml_invalid_argument("Java.meth: `object` is null");
	arg_stack[0].l = Java_obj_val(obj);
	arg_stack[1].l = (jobject)Nativeint_val(meth);
	arg_count = 2;
	perform_type = PERFORM_CALL;
	return Val_unit;
}

value ocaml_java__calling_meth_static(value class_, value meth)
{
	arg_stack[0].l = Java_obj_val(class_);
	arg_stack[1].l = (jobject)Nativeint_val(meth);
	arg_count = 2;
	perform_type = PERFORM_STATIC_CALL;
	return Val_unit;
}

value ocaml_java__calling_meth_nonvirtual(value obj, value class_, value meth)
{
	if (obj == Java_null_val)
		caml_invalid_argument("Java.meth_nonvirtual: `object` is null");
	arg_stack[0].l = Java_obj_val(obj);
	arg_stack[1].l = Java_obj_val(class_);
	arg_stack[2].l = (jobject)Nativeint_val(meth);
	arg_count = 3;
	perform_type = PERFORM_NONVIRTUAL_CALL;
	return Val_unit;
}

value ocaml_java__calling_init(value class_, value meth)
{
	arg_stack[0].l = Java_obj_val(class_);
	arg_stack[1].l = (jobject)Nativeint_val(meth);
	arg_count = 2;
	perform_type = PERFORM_INIT;
	return Val_unit;
}

value ocaml_java__calling_field(value obj, value field)
{
	if (obj == Java_null_val)
		caml_invalid_argument("Java.field: `object` is null");
	arg_stack[0].l = Java_obj_val(obj);
	arg_stack[1].l = (jobject)Nativeint_val(field);
	arg_count = 2;
	perform_type = PERFORM_FIELD;
	return Val_unit;
}

value ocaml_java__calling_field_static(value class_, value field)
{
	arg_stack[0].l = Java_obj_val(class_);
	arg_stack[1].l = (jobject)Nativeint_val(field);
	arg_count = 2;
	perform_type = PERFORM_FIELD_STATIC;
	return Val_unit;
}

// Arg

static jobject arg_string(value v)
{
	jstring const js = (*env)->NewStringUTF(env, String_val(v));

	push_local_ref(js);
	return js;
}

// Generate a Java.arg_ function with name `NAME`
// `DST` is the field in jvalue
// `CONV` is the function that convert from OCaml value to Java type
//  object allocated on the Java heap must be added to local_ref_stack
#define ARG(NAME, DST, CONV) \
value ocaml_java__arg_##NAME(value v)		\
{											\
	arg_stack[arg_count].DST = CONV(v);		\
	arg_count++;							\
	return Val_unit;						\
}

#define ARG_TO_OBJ(v) ((v == Java_null_val) ? NULL : Java_obj_val(v))
ARG(int, i, Long_val)
ARG(float, f, Double_val)
ARG(double, d, Double_val)
ARG(string, l, arg_string)
ARG(bool, z, Bool_val)
ARG(char, c, Long_val)
ARG(int8, b, Long_val)
ARG(int16, s, Long_val)
ARG(int32, i, Int32_val)
ARG(int64, j, Int64_val)
ARG(obj, l, ARG_TO_OBJ)

#undef ARG

// Call

#define ENABLED(a) a
#define DISABLED_(a)
#define DISABLED(msg) (caml_failwith(msg), 0) DISABLED_

// Generate a Java.call_ function with name `NAME`
// `CONV` is the function that convert from the java type to `value`
// `INIT_ENABLED` and `FIELD_ENABLED` can be used to disable the
//   `PERFORM_INIT`, `PERFORM_FIELD` and `PERFORM_FIELD_STATIC` cases
#define CALL(NAME, JTYPE, MNAME, CONV, INIT_ENABLED, FIELD_ENABLED, FIX) \
value ocaml_java__call_##NAME(value unit)							\
{																	\
	JTYPE res = 0;													\
	switch (perform_type)											\
	{																\
	case PERFORM_NONVIRTUAL_CALL:									\
		res = FIX (*env)->CallNonvirtual##MNAME##MethodA(env,		\
						arg_stack[0].l,								\
			(jclass)	arg_stack[1].l,								\
			(jmethodID)	arg_stack[2].l,								\
						arg_stack + 3);								\
		break ;														\
	case PERFORM_STATIC_CALL:										\
		res = FIX (*env)->CallStatic##MNAME##MethodA(env,			\
			(jclass)	arg_stack[0].l,								\
			(jmethodID)	arg_stack[1].l,								\
						arg_stack + 2);								\
		break ;														\
	case PERFORM_CALL:												\
		res = FIX (*env)->Call##MNAME##MethodA(env,					\
						arg_stack[0].l,								\
			(jmethodID)	arg_stack[1].l,								\
						arg_stack + 2);								\
		break ;														\
	case PERFORM_INIT:												\
		res = FIX INIT_ENABLED((*env)->NewObjectA(env,				\
			(jclass)	arg_stack[0].l,								\
			(jmethodID)	arg_stack[1].l,								\
						arg_stack + 2));							\
		break ;														\
	case PERFORM_FIELD:												\
		res = FIX FIELD_ENABLED((*env)->Get##MNAME##Field(env,		\
						arg_stack[0].l,								\
			(jfieldID)	arg_stack[1].l));							\
		break ;														\
	case PERFORM_FIELD_STATIC:										\
		res = FIX FIELD_ENABLED((*env)->GetStatic##MNAME##Field(env, \
			(jclass)	arg_stack[0].l,								\
			(jfieldID)	arg_stack[1].l));							\
		break ;														\
	}																\
	clear_local_refs();												\
	check_exceptions();												\
	return CONV(res);												\
	(void)unit;														\
}

static value conv_string(jstring str)
{
	char const *str_utf;
	value cstr;

	if (str == NULL)
		caml_failwith("Null string");
	str_utf = (*env)->GetStringUTFChars(env, str, NULL);
	cstr = caml_copy_string(str_utf);
	(*env)->ReleaseStringUTFChars(env, str, str_utf);
	return cstr;
}

#define P_INIT_DISABLED(n) DISABLED("Java.new_: Java.call_" n)

#define CONV_UNIT(v)		Val_unit
CALL(unit, int /* dummy */, Void, CONV_UNIT, P_INIT_DISABLED("unit"),
	DISABLED("Java.field: Java.call_unit"), 0;(void)res;(void))
CALL(int, jint, Int, Val_long, P_INIT_DISABLED("int"), ENABLED,)
CALL(float, jfloat, Float, caml_copy_double, P_INIT_DISABLED("float"), ENABLED,)
CALL(double, jdouble, Double, caml_copy_double, P_INIT_DISABLED("double"), ENABLED,)
CALL(string, jobject, Object, conv_string,
	(jobject)(long)P_INIT_DISABLED("string"), ENABLED,)
CALL(bool, jboolean, Boolean, Val_bool, P_INIT_DISABLED("bool"), ENABLED,)
CALL(char, jchar, Char, Val_long, P_INIT_DISABLED("char"), ENABLED,)
CALL(int8, jbyte, Byte, Val_long, P_INIT_DISABLED("int8"), ENABLED,)
CALL(int16, jshort, Short, Val_long, P_INIT_DISABLED("int16"), ENABLED,)
CALL(int32, jint, Int, caml_copy_int32, P_INIT_DISABLED("int32"), ENABLED,)
CALL(int64, jlong, Long, caml_copy_int64, P_INIT_DISABLED("int64"), ENABLED,)
CALL(obj, jobject, Object, alloc_java_obj, ENABLED, ENABLED,)

#undef CALL
#undef ENABLED
#undef DISABLED
#undef DISABLED_

/*
** ========================================================================== **
** Class
** -
** Method Ids are represented as nativeint
*/

value ocaml_java__find_class(value name)
{
	jclass c;

	c = (*env)->FindClass(env, String_val(name));
	if (c == NULL)
		caml_raise_not_found();
	return alloc_java_obj(c);
}

static value get_method(jobject class_, char const *name, char const *sig)
{
	jmethodID id;

	id = (*env)->GetMethodID(env, class_, name, sig);
	if (id == NULL)
		caml_raise_not_found();
	return caml_copy_nativeint((intnat)id);
}

value ocaml_java__class_get_meth(value class_, value name, value sig)
{
	return get_method(Java_obj_val(class_), String_val(name), String_val(sig));
}

value ocaml_java__class_get_meth_static(value class_, value name, value sig)
{
	jmethodID id;

	id = (*env)->GetStaticMethodID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
		caml_raise_not_found();
	return caml_copy_nativeint((intnat)id);
}

value ocaml_java__class_get_constructor(value class_, value sig)
{
	return get_method(Java_obj_val(class_), "<init>", String_val(sig));
}

value ocaml_java__class_get_field(value class_, value name, value sig)
{
	jfieldID id;

	id = (*env)->GetFieldID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
		caml_raise_not_found();
	return caml_copy_nativeint((intnat)id);
}

value ocaml_java__class_get_field_static(value class_, value name, value sig)
{
	jfieldID id;

	id = (*env)->GetStaticFieldID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
		caml_raise_not_found();
	return caml_copy_nativeint((intnat)id);
}

/*
** ========================================================================== **
** Init
*/

static JavaVM *jvm;

void ocaml_java__javacaml_init(JNIEnv *env);

value ocaml_java__startup(value opt_array)
{
	CAMLparam1(opt_array);
	int const opt_count = caml_array_length(opt_array);
	JavaVMOption *options;
	JavaVMInitArgs vm_args;
	int success;
	int i;

	options = caml_stat_alloc(sizeof(JavaVMOption) * opt_count);
	for (i = 0; i < opt_count; i++)
		options[i].optionString = String_val(Field(opt_array, i));
	vm_args.version = JNI_VERSION;
	vm_args.options = options;
	vm_args.nOptions = opt_count;
	vm_args.ignoreUnrecognized = JNI_FALSE;
	success = JNI_CreateJavaVM(&jvm, (void**)&env, &vm_args);
	caml_stat_free(options);
	if (success != JNI_OK)
		caml_failwith("Java.init");
	init_exception();
	ocaml_java__javacaml_init(env);
	printf("jvm created\n");
	CAMLreturn(Val_unit);
}

value ocaml_java__shutdown(value unit)
{
	(*jvm)->DestroyJavaVM(jvm);
	printf("jvm destroyed\n");
	return Val_unit;
	(void)unit;
}
