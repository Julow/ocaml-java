#include <stddef.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/printexc.h>

static jclass
	NullPointerException,
	NamedValue,
	NamedValueNotFoundException,
	CamlException;

static jmethodID
	NamedValue_init;

static jfieldID
	NamedValue_closure;

#define IS_NULL(env, obj) ((*env)->IsSameObject(env, obj, NULL))

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

void Java_juloo_javacaml_Caml_function(JNIEnv *env, jclass c, jlong func)
{
	Store_field(stack, 0, (value)func);
	stack_size = 1;
}

// Generate a Caml.arg##NAME function
// `CONVERT` should convert from `TYPE` to an OCaml value
#define ARG(NAME, TYPE, CONVERT) \
void Java_juloo_javacaml_Caml_arg##NAME(JNIEnv *env, jclass c, TYPE v) \
{ \
	Store_field(stack, stack_size, CONVERT(v)); \
	stack_size++; \
}

#define CONVERT_UNIT(v) Val_unit
ARG(Unit, int /* dummy */, CONVERT_UNIT)
ARG(Int, jint, Val_long)

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
	return CONVERT(result); \
}

CALL(Unit, void, (void),)
CALL(Int, jint, (jint)Int_val, 0)

#undef CALL

// ========================================================================== //
// getNamedValue

static value *get_named_value(JNIEnv *env, jstring name)
{
	char const *const name_utf = (*env)->GetStringUTFChars(env, name, NULL);
	value *closure;

	closure = caml_named_value(name_utf);
	if (closure == NULL)
		(*env)->ThrowNew(env, NamedValueNotFoundException, name_utf);
	(*env)->ReleaseStringUTFChars(env, name, name_utf);
	return closure;
}

jobject Java_juloo_javacaml_Caml_getNamedValue(JNIEnv *env, jclass c, jstring name)
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
	return (*env)->NewObject(env, NamedValue, NamedValue_init, (jlong)closure);
	(void)c;
}

jlong Java_juloo_javacaml_Caml_00024NamedValue_get(JNIEnv *env, jobject obj)
{
	jlong const c = (*env)->GetLongField(env, obj, NamedValue_closure);
	return (jlong)*(value*)c;
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
	C("juloo/javacaml/Caml$", NamedValue);
	I(NamedValue, "(J)V");
	F(NamedValue, closure, "J");
	C("juloo/javacaml/Caml$", NamedValueNotFoundException);
	C("juloo/javacaml/Caml$", CamlException);

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
