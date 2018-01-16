#include <stddef.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/printexc.h>
#include <caml/fail.h>
#include "camljava_utils.h"
#include "javacaml_utils.h"

static jclass
	NullPointerException,
	Callback,
	CallbackNotFoundException,
	Value,
	CamlException,
	InvalidMethodIdException,
	ArgumentStackOverflowException;

static jmethodID
	Callback_init,
	Value_init;

static jfieldID
	Callback_closure,
	Value_value;

#define THROW_NULLPTR(env, ARG_NAME) \
		((*env)->ThrowNew(env, NullPointerException, \
			"Called with null `" ARG_NAME "`"), \
		(void)0)

// ========================================================================== //
// Value
// juloo.javacaml.Value

// Return the value pointed to by the Value `v`
value ocaml_java__jvalue_get(JNIEnv *env, jobject v)
{
	long const v_ = (*env)->GetLongField(env, v, Value_value);

	return *(value*)v_;
}

// Create a new Value object that point to `v`
jobject ocaml_java__jvalue_new(JNIEnv *env, value v)
{
	value *const global = caml_stat_alloc(sizeof(value));

	caml_register_global_root(global);
	*global = v;
	return (*env)->NewObject(env, Value, Value_init, (jlong)global);
}

void Java_juloo_javacaml_Value_release(JNIEnv *env, jobject v)
{
	long const v_ = (*env)->GetLongField(env, v, Value_value);
	value *const global = (value*)v_;

	caml_remove_global_root(global);
}

// ========================================================================== //
// Function calling
// -
// A stack is used to store the function and its arguments before calling it.
// It is represented as an OCaml array
// -
// The first element of the stack is the function to call
// -
// The counter `stack_size` is used to keep track of the top of the stack
// The stack is emptied after a call.

#define STACK_MAX_SIZE 16

static value stack;
static int stack_size;

// Fill the stack with Val_unit
static void empty_stack(void)
{
	int i;

	for (i = 0; i < stack_size; i++)
		Store_field(stack, i, Val_unit);
}

// Throw a CamlException in reaction of `exn`
static void throw_caml_exception(JNIEnv *env, value exn)
{
	char *exn_message;

	// function from caml/printexc.h
	exn_message = caml_format_exception(exn);
	(*env)->ThrowNew(env, CamlException, exn_message);
	caml_stat_free(exn_message);
}

static void init_arg_stack(void)
{
	stack = caml_alloc(STACK_MAX_SIZE, 0);
	caml_register_global_root(&stack);
}

void Java_juloo_javacaml_Caml_function__Ljuloo_javacaml_Value_2(JNIEnv *env,
		jclass c, jobject v)
{
	if (IS_NULL(env, v))
		return THROW_NULLPTR(env, "function");
	Store_field(stack, 0, JVALUE_GET(env, v));
	stack_size = 1;
	(void)c;
}

void Java_juloo_javacaml_Caml_function__Ljuloo_javacaml_Callback_2(JNIEnv *env,
		jclass c, jobject callback)
{
	long func_;
	value func;

	if (IS_NULL(env, callback))
		return THROW_NULLPTR(env, "callback");
	func_ = (*env)->GetLongField(env, callback, Callback_closure);
	func = *(value*)func_;
	Store_field(stack, 0, func);
	stack_size = 1;
	(void)c;
}

void Java_juloo_javacaml_Caml_method(JNIEnv *env, jclass c, jobject v,
		jint method_id)
{
	value obj;
	value method;

	if (IS_NULL(env, v))
		return THROW_NULLPTR(env, "object");
	obj = JVALUE_GET(env, v);
	method = caml_get_public_method(obj, method_id);
	if (method == 0)
	{
		(*env)->ThrowNew(env, InvalidMethodIdException,
				"Method id does not reference any method");
		return ;
	}
	Store_field(stack, 0, method);
	Store_field(stack, 1, obj);
	stack_size = 2;
	(void)c;
}

// Generate a Caml.arg##NAME function
// `CONVERT` should convert from `TYPE` to an OCaml value
#define ARG(NAME, TYPE, CONVERT) \
void Java_juloo_javacaml_Caml_arg##NAME(JNIEnv *env, jclass c, TYPE v) \
{ \
	if (stack_size >= STACK_MAX_SIZE) \
	{ \
		(*env)->ThrowNew(env, ArgumentStackOverflowException, "Overflow"); \
		return ; \
	} \
	Store_field(stack, stack_size, CONVERT(env, v)); \
	stack_size++; \
	(void)c; \
}

// a little hack to throw a NullPointerException if the argument is null
#define CHECK_NULLPTR(env, v, conv) (IS_NULL(env, v) ? \
		(THROW_NULLPTR(env, "argument"), \
		stack_size--, \
		Val_unit) : conv(env, v))

#define ARG_TO_UNIT(env, v)		((void)v, Val_unit)
#define ARG_TO_INT(env, v)		Val_long(v)
#define ARG_TO_FLOAT(env, v)	caml_copy_double(v)
#define ARG_TO_STRING(env, v)	CHECK_NULLPTR(env, v, jstring_to_cstring)
#define ARG_TO_BOOL(env, v)		Val_bool(v)
#define ARG_TO_INT32(env, v)	caml_copy_int32(v)
#define ARG_TO_INT64(env, v)	caml_copy_int64(v)
#define ARG_TO_VALUE(env, v)	CHECK_NULLPTR(env, v, JVALUE_GET)
#define ARG_TO_OBJECT(env, v)	alloc_java_obj(env, v)
ARG(Unit, int /* dummy */, ARG_TO_UNIT)
ARG(Int, jint, ARG_TO_INT)
ARG(Float, jdouble, ARG_TO_FLOAT)
ARG(String, jstring, ARG_TO_STRING)
ARG(Bool, jboolean, ARG_TO_BOOL)
ARG(Int32, jint, ARG_TO_INT32)
ARG(Int64, jlong, ARG_TO_INT64)
ARG(Value, jobject, ARG_TO_VALUE)
ARG(Object, jobject, ARG_TO_OBJECT)

#undef ARG

// Generate a Caml.call##NAME function
// `CONVERT` should convert from the `value` returned to `TYPE`
// `CONVERT` must not allocate on the OCaml heap
// `DUMMY` is any value of TYPE, it is used to avoid a compiler warning
#define CALL(NAME, TYPE, CONVERT, DUMMY) \
TYPE Java_juloo_javacaml_Caml_call##NAME(JNIEnv *env, jclass c) \
{ \
	value result; \
\
	result = caml_callbackN_exn( \
		Field(stack, 0), stack_size - 1, &Field(stack, 1)); \
\
	empty_stack(); \
\
	if (Is_exception_result(result)) \
	{ \
		throw_caml_exception(env, Extract_exception(result)); \
		return DUMMY; \
	} \
	return CONVERT(env, result); \
	(void)c; \
}

#define CALL_OF_UNIT(env, v)	(void)0
#define CALL_OF_INT(env, v)		Int_val(v)
#define CALL_OF_FLOAT(env, v)	Double_val(v)
#define CALL_OF_STRING(env, v)	(*env)->NewStringUTF(env, String_val(v))
#define CALL_OF_BOOL(env, v)	Bool_val(v)
#define CALL_OF_INT32(env, v)	Int32_val(v)
#define CALL_OF_INT64(env, v)	Int64_val(v)
#define CALL_OF_VALUE(env, v)	JVALUE_NEW(env, v)
#define CALL_OF_OBJECT(env, v)	((v == Java_null_val) ? NULL : Java_obj_val(v))
CALL(Unit, void, CALL_OF_UNIT,)
CALL(Int, jint, CALL_OF_INT, 0)
CALL(Float, jdouble, CALL_OF_FLOAT, 0.0)
CALL(String, jstring, CALL_OF_STRING, NULL)
CALL(Bool, jboolean, CALL_OF_BOOL, 0)
CALL(Int32, jint, CALL_OF_INT32, 0)
CALL(Int64, jlong, CALL_OF_INT64, 0)
CALL(Value, jobject, CALL_OF_VALUE, NULL)
CALL(Object, jobject, CALL_OF_OBJECT, NULL)

#undef CALL

// ========================================================================== //
// getCallback

jobject Java_juloo_javacaml_Caml_getCallback(JNIEnv *env, jclass c,
		jstring name)
{
	char const *name_utf;
	value *closure;

	if (IS_NULL(env, name))
		return THROW_NULLPTR(env, "name"), NULL;
	name_utf = (*env)->GetStringUTFChars(env, name, NULL);
	closure = caml_named_value(name_utf);
	if (closure == NULL)
		(*env)->ThrowNew(env, CallbackNotFoundException, name_utf);
	(*env)->ReleaseStringUTFChars(env, name, name_utf);
	if (closure == NULL)
		return NULL; // dummy
	return (*env)->NewObject(env, Callback, Callback_init, (jlong)closure);
	(void)c;
}

// ========================================================================== //
// hashVariant

jlong Java_juloo_javacaml_Caml_hashVariant(JNIEnv *env, jclass c,
		jstring variantName)
{
	char const	*name_utf;
	value hash;

	if (IS_NULL(env, variantName))
		return THROW_NULLPTR(env, "variantName"), 0;
	name_utf = (*env)->GetStringUTFChars(env, variantName, NULL);
	hash = caml_hash_variant(name_utf);
	(*env)->ReleaseStringUTFChars(env, variantName, name_utf);
	return (jlong)hash;
	(void)c;
}

// ========================================================================== //
// init

static int init_classes(JNIEnv *env)
{
#define DEF(ST, FN, ...) do { \
	ST = (*env)->FN(env, ##__VA_ARGS__); \
	if (ST == NULL) return 0; \
} while (0)

#define C(PATH, NAME) do { \
	DEF(NAME, FindClass, PATH #NAME); \
	NAME = (*env)->NewGlobalRef(env, NAME); \
} while (0)
#define I(CLASS, SIG) DEF(CLASS##_init, GetMethodID, CLASS, "<init>", SIG)
#define F(CLASS, NAME, SIG) DEF(CLASS##_##NAME, GetFieldID, CLASS, #NAME, SIG)

	C("java/lang/", NullPointerException);
	C("juloo/javacaml/", Callback);
	I(Callback, "(J)V");
	F(Callback, closure, "J");
	C("juloo/javacaml/", CallbackNotFoundException);
	C("juloo/javacaml/", Value);
	I(Value, "(J)V");
	F(Value, value, "J");
	C("juloo/javacaml/", CamlException);
	C("juloo/javacaml/", InvalidMethodIdException);
	C("juloo/javacaml/", ArgumentStackOverflowException);

#undef C
#undef I
#undef F
#undef DEF
	return 1;
}

#ifdef TARGET_CAMLJAVA

// Caml.startup disabled
void Java_juloo_javacaml_Caml_startup(JNIEnv *env, jclass c)
{
	(void)env;
	(void)c;
}

#define N(NAME, SIGT, MANG)	\
	{ #NAME, SIGT, Java_juloo_javacaml_Caml_##NAME##MANG }

static JNINativeMethod native_methods[] = {
	N(startup, "()V",),
	N(getCallback, "(Ljava/lang/String;)Ljuloo/javacaml/Callback;",),
	N(hashVariant, "(Ljava/lang/String;)I",),
	N(function, "(Ljuloo/javacaml/Value;)V", __Ljuloo_javacaml_Value_2),
	N(function, "(Ljuloo/javacaml/Callback;)V", __Ljuloo_javacaml_Callback_2),
	N(method, "(Ljuloo/javacaml/Value;I)V",),
	N(argUnit, "()V",),
	N(argInt, "(I)V",),
	N(argFloat, "(D)V",),
	N(argString, "(Ljava/lang/String;)V",),
	N(argBool, "(Z)V",),
	N(argInt32, "(I)V",),
	N(argInt64, "(J)V",),
	N(argValue, "(Ljuloo/javacaml/Value;)V",),
	N(argObject, "(Ljava/lang/Object;)V",),
	N(callUnit, "()V",),
	N(callInt, "()I",),
	N(callFloat, "()D",),
	N(callString, "()Ljava/lang/String;",),
	N(callBool, "()Z",),
	N(callInt32, "()I",),
	N(callInt64, "()J",),
	N(callValue, "()Ljuloo/javacaml/Value;",),
	N(callObject, "()Ljava/lang/Object;",),
};

#undef N

#define COUNT(x) (sizeof(x) / sizeof(*x))

// Native methods must be registered if javacaml is not loaded directly
//  from Java's `System.loadLibrary`
static int register_natives(JNIEnv *env)
{
	jclass const caml_class = (*env)->FindClass(env, "juloo/javacaml/Caml");

	if (caml_class == NULL)
		return 0;
	return ((*env)->RegisterNatives(env, caml_class, native_methods,
			COUNT(native_methods)) == 0);
}

// Initialise the library from camljava
void ocaml_java__javacaml_init(JNIEnv *env)
{
	init_arg_stack();
	if (!init_classes(env))
	{
		// if init_classes fail, it means javacaml.jar is not loaded
		// clear exception since it is optional
		(*env)->ExceptionClear(env);
		return ;
	}
	if (!register_natives(env))
		caml_failwith("Failed to link javacaml");
}

#else

void Java_juloo_javacaml_Caml_startup(JNIEnv *env, jclass c)
{
	static char *argv[] = { "", NULL };
	if (!init_classes(env))
		return ;
	ocaml_java__camljava_init(env);
	caml_startup(argv);
	init_arg_stack();
	(void)c;
}

#endif
