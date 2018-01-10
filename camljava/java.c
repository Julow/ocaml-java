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

// Copy the content of `str` into a new OCaml string
static value jstring_to_cstring(JNIEnv *env, jstring str)
{
	char const *const str_utf = (*env)->GetStringUTFChars(env, str, NULL);
	value cstr;

	cstr = caml_copy_string(str_utf);
	(*env)->ReleaseStringUTFChars(env, str, str_utf);
	return cstr;
}

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
** Calling
** -
** `arg_stack` represents the argument stack
** `perform_type` stores the type of call
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

enum e_perform_type
{
	PERFORM_NONVIRTUAL_CALL,
	PERFORM_STATIC_CALL,
	PERFORM_CALL,
	PERFORM_INIT,
};

static enum e_perform_type perform_type;
static jvalue arg_stack[ARG_STACK_MAX_SIZE];
static int arg_count;

value ocaml_java__calling_member_method(value obj, value class_, value meth)
{
	if (obj == Java_null_val)
		caml_invalid_argument("Java.member_method: `object` is null");
	arg_stack[0].l = Java_obj_val(obj);
	arg_stack[1].l = Java_obj_val(class_);
	arg_stack[2].l = (jobject)Nativeint_val(meth);
	arg_count = 3;
	perform_type = PERFORM_NONVIRTUAL_CALL;
	return Val_unit;
}

value ocaml_java__calling_static_method(value class_, value meth)
{
	arg_stack[0].l = Java_obj_val(class_);
	arg_stack[1].l = (jobject)Nativeint_val(meth);
	arg_count = 2;
	perform_type = PERFORM_STATIC_CALL;
	return Val_unit;
}

value ocaml_java__calling_virtual_method(value obj, value meth)
{
	if (obj == Java_null_val)
		caml_invalid_argument("Java.virtual_method: `object` is null");
	arg_stack[0].l = Java_obj_val(obj);
	arg_stack[1].l = (jobject)Nativeint_val(meth);
	arg_count = 2;
	perform_type = PERFORM_CALL;
	return Val_unit;
}

value ocaml_java__calling_init_method(value class_, value meth)
{
	arg_stack[0].l = Java_obj_val(class_);
	arg_stack[1].l = (jobject)Nativeint_val(meth);
	arg_count = 2;
	perform_type = PERFORM_INIT;
	return Val_unit;
}

// Generate a Java.arg_ function with name `NAME`
// `DST` is the field in jvalue
// `CONV` is the function that convert from OCaml value to Java type
//  it must not allocate on the Java heap
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
ARG(bool, z, Bool_val)
ARG(char, c, Long_val)
ARG(int8, b, Long_val)
ARG(int16, s, Long_val)
ARG(int32, i, Int32_val)
ARG(int64, j, Int64_val)
ARG(obj, l, ARG_TO_OBJ)

#undef ARG

#define P_INIT_FAIL(v) \
	(caml_failwith("only call_obj can be used with init_method"), Val_unit)

// Generate a Java.call_ function with name `NAME`
// `CONV` is the function that convert from the java type to `value`
// `P_INIT_CONV` can be used to disable the `PERFORM_INIT` case
#define CALL(NAME, MNAME, CONV, P_INIT_CONV) \
value ocaml_java__call_##NAME(value unit)							\
{																	\
	switch (perform_type)											\
	{																\
	case PERFORM_NONVIRTUAL_CALL:									\
		return CONV((*env)->CallNonvirtual##MNAME##MethodA(env,		\
						arg_stack[0].l,								\
			(jclass)	arg_stack[1].l,								\
			(jmethodID)	arg_stack[2].l,								\
						arg_stack + 3));							\
	case PERFORM_STATIC_CALL:										\
		return CONV((*env)->CallStatic##MNAME##MethodA(env,			\
			(jclass)	arg_stack[0].l,								\
			(jmethodID)	arg_stack[1].l,								\
						arg_stack + 2));							\
	case PERFORM_CALL:												\
		return CONV((*env)->Call##MNAME##MethodA(env,				\
						arg_stack[0].l,								\
			(jmethodID)	arg_stack[1].l,								\
						arg_stack + 2));							\
	case PERFORM_INIT:												\
		return P_INIT_CONV((*env)->NewObjectA(env,					\
			(jclass)	arg_stack[0].l,								\
			(jmethodID)	arg_stack[1].l,								\
						arg_stack + 2));							\
	}																\
	return Val_unit;												\
}

#define CONV_UNIT(v)	((v), Val_unit)
#define CONV_STRING(v)	(jstring_to_cstring(env, (jstring)(v)))
CALL(unit, Void, CONV_UNIT, P_INIT_FAIL)
CALL(int, Int, Val_long, P_INIT_FAIL)
CALL(float, Float, caml_copy_double, P_INIT_FAIL)
CALL(double, Double, caml_copy_double, P_INIT_FAIL)
CALL(string, Object, CONV_STRING, P_INIT_FAIL)
CALL(bool, Boolean, Val_bool, P_INIT_FAIL)
CALL(char, Char, Val_long, P_INIT_FAIL)
CALL(int8, Byte, Val_long, P_INIT_FAIL)
CALL(int16, Short, Val_long, P_INIT_FAIL)
CALL(int32, Int, caml_copy_int32, P_INIT_FAIL)
CALL(int64, Long, caml_copy_int64, P_INIT_FAIL)
CALL(obj, Object, alloc_java_obj, alloc_java_obj)

#undef CALL

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

value ocaml_java__member_method(value class_, value name, value sig)
{
	return get_method(Java_obj_val(class_), String_val(name), String_val(sig));
}

value ocaml_java__static_method(value class_, value name, value sig)
{
	jmethodID id;

	id = (*env)->GetStaticMethodID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
		caml_raise_not_found();
	return caml_copy_nativeint((intnat)id);
}

value ocaml_java__virtual_method(value class_, value name, value sig)
{
	return get_method(Java_obj_val(class_), String_val(name), String_val(sig));
}

value ocaml_java__init_method(value class_, value sig)
{
	return get_method(Java_obj_val(class_), "<init>", String_val(sig));
}

value ocaml_java__member_field(value class_, value name, value sig)
{
	jfieldID id;

	id = (*env)->GetFieldID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
		caml_raise_not_found();
	return caml_copy_nativeint((intnat)id);
}

value ocaml_java__static_field(value class_, value name, value sig)
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
