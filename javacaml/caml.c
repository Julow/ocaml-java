#include <stddef.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/printexc.h>

static jclass
	NullPointerException,
	Callback,
	CallbackNotFoundException,
	Value,
	CamlException,
	InvalidMethodIdException;

static jmethodID
	Callback_init,
	Value_init;

static jfieldID
	Callback_closure,
	Value_value;

#define IS_NULL(env, obj) ((*env)->IsSameObject(env, obj, NULL))

// Copy the content of `str` into a new OCaml string
static value jstring_to_cstring(JNIEnv *env, jstring str)
{
	char const *const str_utf = (*env)->GetStringUTFChars(env, str, NULL);
	value cstr;

	cstr = caml_copy_string(str_utf);
	(*env)->ReleaseStringUTFChars(env, str, str_utf);
	return cstr;
}

// ========================================================================== //
// Value
// juloo.javacaml.Value

static value jvalue_get(JNIEnv *env, jobject v)
{
	long const v_ = (*env)->GetLongField(env, v, Value_value);

	return *(value*)v_;
}

static jobject jvalue_new(JNIEnv *env, value v)
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
// It is represented as an OCaml array, at rest, filled with Val_unit
// -
// The first element of the stack is the function to be called,
// the remaining is its arguments
// -
// A counter (`stack_size`) is used to keep track of the top of the stack
// The stack is emptied after the call.

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

void Java_juloo_javacaml_Caml_function__Ljuloo_javacaml_Value_2(JNIEnv *env, jclass c, jobject v)
{
	Store_field(stack, 0, jvalue_get(env, v));
	stack_size = 1;
}

void Java_juloo_javacaml_Caml_function__Ljuloo_javacaml_Callback_2(JNIEnv *env, jclass c, jobject callback)
{
	long const func_ = (*env)->GetLongField(env, callback, Callback_closure);
	value const func = *(value*)func_;

	Store_field(stack, 0, func);
	stack_size = 1;
}

void Java_juloo_javacaml_Caml_method(JNIEnv *env, jclass c, jobject v, jint method_id)
{
	value const obj = jvalue_get(env, v);
	value const method = caml_get_public_method(obj, method_id);

	if (method == 0)
		(*env)->ThrowNew(env, InvalidMethodIdException,
				"Method id does not reference any method");
	Store_field(stack, 0, method);
	Store_field(stack, 1, obj);
	stack_size = 2;
}

// Generate a Caml.arg##NAME function
// `CONVERT` should convert from `TYPE` to an OCaml value
#define ARG(NAME, TYPE, CONVERT) \
void Java_juloo_javacaml_Caml_arg##NAME(JNIEnv *env, jclass c, TYPE v) \
{ \
	Store_field(stack, stack_size, CONVERT(env, v)); \
	stack_size++; \
}

#define ARG_TO_UNIT(env, v)		Val_unit
#define ARG_TO_INT(env, v)		Val_long(v)
#define ARG_TO_FLOAT(env, v)	caml_copy_double(v)
#define ARG_TO_STRING(env, v)	jstring_to_cstring(env, v)
#define ARG_TO_BOOL(env, v)		Val_bool(v)
#define ARG_TO_INT32(env, v)	caml_copy_int32(v)
#define ARG_TO_INT64(env, v)	caml_copy_int64(v)
#define ARG_TO_VALUE(env, v)	jvalue_get(env, v)
ARG(Unit, int /* dummy */, ARG_TO_UNIT)
ARG(Int, jint, ARG_TO_INT)
ARG(Float, jdouble, ARG_TO_FLOAT)
ARG(String, jstring, ARG_TO_STRING)
ARG(Bool, jboolean, ARG_TO_BOOL)
ARG(Int32, jint, ARG_TO_INT32)
ARG(Int64, jlong, ARG_TO_INT64)
ARG(Value, jobject, ARG_TO_VALUE)

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
}

#define CALL_OF_UNIT(env, v)	(void)0
#define CALL_OF_INT(env, v)		Int_val(v)
#define CALL_OF_FLOAT(env, v)	Double_val(v)
#define CALL_OF_STRING(env, v)	(*env)->NewStringUTF(env, String_val(v))
#define CALL_OF_BOOL(env, v)	Bool_val(v)
#define CALL_OF_INT32(env, v)	Int32_val(v)
#define CALL_OF_INT64(env, v)	Int64_val(v)
#define CALL_OF_VALUE(env, v)	jvalue_new(env, v)
CALL(Unit, void, CALL_OF_UNIT,)
CALL(Int, jint, CALL_OF_INT, 0)
CALL(Float, jdouble, CALL_OF_FLOAT, 0.0)
CALL(String, jstring, CALL_OF_STRING, NULL)
CALL(Bool, jboolean, CALL_OF_BOOL, 0)
CALL(Int32, jint, CALL_OF_INT32, 0)
CALL(Int64, jlong, CALL_OF_INT64, 0)
CALL(Value, jobject, CALL_OF_VALUE, NULL)

#undef CALL

// ========================================================================== //
// getCallback

static value *get_named_value(JNIEnv *env, jstring name)
{
	char const *const name_utf = (*env)->GetStringUTFChars(env, name, NULL);
	value *closure;

	closure = caml_named_value(name_utf);
	if (closure == NULL)
		(*env)->ThrowNew(env, CallbackNotFoundException, name_utf);
	(*env)->ReleaseStringUTFChars(env, name, name_utf);
	return closure;
}

jobject Java_juloo_javacaml_Caml_getCallback(JNIEnv *env, jclass c, jstring name)
{
	value *closure;

	if (IS_NULL(env, name))
	{
		(*env)->ThrowNew(env, NullPointerException, "Called with null `name`");
		return 0;
	}
	closure = get_named_value(env, name);
	if (closure == NULL)
		return 0; // dummy
	return (*env)->NewObject(env, Callback, Callback_init, (jlong)closure);
	(void)c;
}

// ========================================================================== //
// hashVariant

jlong Java_juloo_javacaml_Caml_hashVariant(JNIEnv *env, jclass c, jstring variantName)
{
	char const	*name_utf;
	value hash;

	if (IS_NULL(env, variantName))
	{
		(*env)->ThrowNew(env, NullPointerException, "Called with null `variantName`");
		return 0;
	}
	name_utf = (*env)->GetStringUTFChars(env, variantName, NULL);
	hash = caml_hash_variant(name_utf);
	(*env)->ReleaseStringUTFChars(env, variantName, name_utf);
	return (jlong)hash;
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

#undef C
#undef I
#undef F
#undef DEF
	return 1;
}

void Java_juloo_javacaml_Caml_init(JNIEnv *env, jclass c)
{
	if (!init_classes(env))
		return ;
	(void)c;
}

void Java_juloo_javacaml_Caml_startup(JNIEnv *env, jclass c)
{
	static char *argv[] = { "", NULL };
	if (!init_classes(env))
		return ;
	caml_startup(argv);
	init_arg_stack();
	(void)c;
}
