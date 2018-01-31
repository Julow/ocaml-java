#include <stddef.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/custom.h>
#include <caml/alloc.h>
#include "camljava_utils.h"
#include "javacaml_utils.h"

#define JNI_VERSION JNI_VERSION_1_4

static JNIEnv *env;

/*
** ========================================================================== **
** Java.obj
** Hold a reference to a Java object
*/

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

struct custom_operations ocamljava__java_obj_custom_ops = {
	.identifier = "ocaml_java__obj",
	.finalize = java_obj_finalize,
	.compare = java_obj_compare,
	.compare_ext = custom_compare_ext_default,
	.hash = custom_hash_default,
	.serialize = custom_serialize_default,
	.deserialize = custom_deserialize_default
};

value ocaml_java__instanceof(value obj, value cls)
{
	if (obj != Java_null_val
		&& (*env)->IsInstanceOf(env, Java_obj_val(obj), Java_obj_val(cls)))
		return Val_true;
	return Val_false;
}

value ocaml_java__sameobject(value a, value b)
{
	jobject const obj_a = Java_obj_val_opt(a);
	jobject const obj_b = Java_obj_val_opt(b);

	if ((*env)->IsSameObject(env, obj_a, obj_b))
		return Val_true;
	return Val_false;
}

value ocaml_java__objectclass(value obj)
{
	jclass cls;

	if (obj == Java_null_val)
		caml_failwith("Java.objectclass: null");
	cls = (*env)->GetObjectClass(env, Java_obj_val(obj));
	return alloc_java_obj(env, cls);
}

/*
** ========================================================================== **
** Exceptions
*/

static value *java_exception = NULL;

// Check if a Java exception has been thrown
// if there is, raises Java.Exception
static void check_exceptions(void)
{
	jthrowable exn;

	exn = (*env)->ExceptionOccurred(env);
	if (exn == NULL) return ;
	(*env)->ExceptionClear(env);
	if (java_exception == NULL)
	{
		java_exception = caml_named_value("Java.Exception");
		if (java_exception == NULL)
			caml_failwith("camljava not properly linked");
	}
	caml_raise_with_arg(*java_exception, alloc_java_obj(env, exn));
}

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
	{
		(*env)->ExceptionClear(env);
		caml_raise_not_found();
	}
	return alloc_java_obj(env, c);
}

static value get_method(jobject class_, char const *name, char const *sig)
{
	jmethodID id;

	id = (*env)->GetMethodID(env, class_, name, sig);
	if (id == NULL)
	{
		(*env)->ExceptionClear(env);
		caml_raise_not_found();
	}
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
	{
		(*env)->ExceptionClear(env);
		caml_raise_not_found();
	}
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
	{
		(*env)->ExceptionClear(env);
		caml_raise_not_found();
	}
	return caml_copy_nativeint((intnat)id);
}

value ocaml_java__class_get_field_static(value class_, value name, value sig)
{
	jfieldID id;

	id = (*env)->GetStaticFieldID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
	{
		(*env)->ExceptionClear(env);
		caml_raise_not_found();
	}
	return caml_copy_nativeint((intnat)id);
}

/*
** ========================================================================== **
** Init
*/

JNIEnv *ocaml_java__camljava_env(void)
{
	return env;
}

#ifdef TARGET_JAVACAML

void ocaml_java__camljava_init(JNIEnv *_env)
{
	env = _env;
}

value ocaml_java__startup(value opt_array)
{
	caml_failwith("Java.init: Unavailable when linked to javacaml");
	return Val_unit;
	(void)opt_array;
}

value ocaml_java__shutdown(value unit)
{
	return Val_unit;
	(void)unit;
}

#else

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

#endif

/*
** ========================================================================== **
** Calling
** -
** `arg_stack` represents the argument stack
** `local_ref_stack` stores references to objects allocated in `arg_` functions
**  Local references are deleted after the method as been called
*/

#define ARG_STACK_MAX_SIZE	16
#define LOCALREF_STACK_MAX_SIZE	32

static jvalue arg_stack[ARG_STACK_MAX_SIZE];
static int arg_count;

// // Local refs

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

/*
** ========================================================================== **
** Convertions for each types
*/

static value conv_of_string(jstring str)
{
	if (IS_NULL(env, str)) caml_failwith("Null string");
	return jstring_to_cstring(env, str);
}

static value conv_of_value(jobject v)
{
	if (IS_NULL(env, v)) caml_failwith("Null value");
	return JVALUE_GET(env, v);
}

static value conv_of_array(jarray a)
{
	if (IS_NULL(env, a)) caml_failwith("Null array");
	return alloc_java_obj(env, a);
}

static value conv_of_string_opt(jstring str)
{
	CAMLparam0();
	CAMLlocal1(cstr);
	if (IS_NULL(env, str)) CAMLreturn(Val_none);
	cstr = jstring_to_cstring(env, str);
	CAMLreturn(copy_some(cstr));
}

static value conv_of_value_opt(jobject v)
{
	CAMLparam0();
	CAMLlocal1(jvalue);
	if (IS_NULL(env, v)) CAMLreturn(Val_none);
	jvalue = JVALUE_GET(env, v);
	CAMLreturn(copy_some(jvalue));
}

static jobject conv_to_string(value v)
{
	jstring const js = (*env)->NewStringUTF(env, String_val(v));

	push_local_ref(js);
	return js;
}

static jobject conv_to_string_opt(value opt)
{
	if (opt == Val_none)
		return NULL;
	return conv_to_string(Some_val(opt));
}

static jobject conv_to_value(value v)
{
	jobject const obj = JVALUE_NEW(env, v);

	push_local_ref(obj);
	return obj;
}

static jobject conv_to_value_opt(value opt)
{
	if (opt == Val_none)
		return NULL;
	return conv_to_value(Some_val(opt));
}

#define CONV_OF_OBJ(v)		alloc_java_obj(env, v)

// Calls `GEN` for each primitive types:
//  int, bool, byte, short, int32, long, char, float, double
// with params:
//  NAME	an identifier for each primitive
//  JNAME	the type part in the JNI functions names
//  TYPE	the jni type
//  CONV_OF	`TYPE` to OCaml's `value` convertion
//  DST		field of the `jvalue` union
//  CONV_TO	OCaml's `value` to `TYPE` convertion
#define GEN_PRIM(GEN) \
	GEN(int,		Int,		jint,		Val_long,			i,	Long_val) \
	GEN(bool,		Boolean,	jboolean,	Val_bool,			z,	Long_val) \
	GEN(byte,		Byte,		jbyte,		Val_long,			b,	Long_val) \
	GEN(short,		Short,		jshort,		Val_long,			s,	Long_val) \
	GEN(char,		Char,		jchar,		Val_long,			c,	Long_val) \
	GEN(int32,		Int,		jint,		caml_copy_int32,	i,	Int32_val) \
	GEN(long,		Long,		jlong,		caml_copy_int64,	j,	Int64_val) \
	GEN(float,		Float,		jfloat,		caml_copy_double,	f,	Double_val) \
	GEN(double,		Double,		jdouble,	caml_copy_double,	d,	Double_val)

// Same as `GEN_PRIM` for object types:
//  string, stringopt, object, value, valueopt
#define GEN_OBJ(GEN) \
	GEN(string,		Object,		jobject,	conv_of_string,		l,	conv_to_string) \
	GEN(string_opt,	Object,		jobject,	conv_of_string_opt,	l,	conv_to_string_opt) \
	GEN(object,		Object,		jobject,	CONV_OF_OBJ,		l,	Java_obj_val_opt) \
	GEN(value,		Object,		jobject,	conv_of_value,		l,	conv_to_value) \
	GEN(value_opt,	Object,		jobject,	conv_of_value_opt,	l,	conv_to_value_opt) \
	GEN(array,		Object,		jarray,		conv_of_array,		l,	Java_obj_val)

// `GEN_PRIM` and `GEN_OBJ`
#define GEN(GEN) \
	GEN_PRIM(GEN) \
	GEN_OBJ(GEN)

/*
** ========================================================================== **
** Call API
*/

value ocaml_java__new(value cls, value meth)
{
	jclass		jcls;
	jmethodID	jmeth;
	jobject		obj;

	jcls = Java_obj_val(cls);
	jmeth = (jmethodID)Nativeint_val(meth);
	obj = (*env)->NewObjectA(env, jcls, jmeth, arg_stack);
	if (obj == NULL)
	{
		check_exceptions();
		caml_failwith("Java.new_");
	}
	return alloc_java_obj(env, obj);
}

// Generates call{,_static,_nonvirtual}_* functions
// `CONV_OF` is a function that convert a native type to OCaml's value
#define GEN_CALL_(NAME, JNAME, RESULT, CONV_OF) \
value ocaml_java__call_##NAME(value obj, value meth)						\
{																			\
	if (obj == Java_null_val)												\
		caml_failwith("Java.call: null");									\
	arg_count = 0;															\
	RESULT (*env)->Call##JNAME##MethodA(env,								\
		Java_obj_val(obj),													\
		(jmethodID)Nativeint_val(meth),										\
		arg_stack);															\
	clear_local_refs();														\
	check_exceptions();														\
	return CONV_OF;															\
}																			\
value ocaml_java__call_static_##NAME(value cls, value meth)					\
{																			\
	arg_count = 0;															\
	RESULT (*env)->CallStatic##JNAME##MethodA(env,							\
		Java_obj_val(cls),													\
		(jmethodID)Nativeint_val(meth),										\
		arg_stack);															\
	clear_local_refs();														\
	check_exceptions();														\
	return CONV_OF;															\
}																			\
value ocaml_java__call_nonvirtual_##NAME(value obj,							\
	value cls, value meth)													\
{																			\
	if (obj == Java_null_val)												\
		caml_failwith("Java.call_nonvirtual: null");						\
	arg_count = 0;															\
	RESULT (*env)->CallNonvirtual##JNAME##MethodA(env,						\
		Java_obj_val(obj),													\
		Java_obj_val(cls),													\
		(jmethodID)Nativeint_val(meth),										\
		arg_stack);															\
	clear_local_refs();														\
	check_exceptions();														\
	return CONV_OF;															\
}

#define GEN_CALL(NAME, JNAME, TYPE, CONV_OF) \
	GEN_CALL_(NAME, JNAME, TYPE res =, CONV_OF(res))

// Generates read_field{,_static}_* functions
#define GEN_READ(NAME, JNAME, CONV_OF) \
value ocaml_java__read_field_##NAME(value obj, value field)							\
{																			\
	if (obj == Java_null_val)												\
		caml_failwith("Java.read_field: null");								\
	return CONV_OF((*env)->Get##JNAME##Field(env,							\
			Java_obj_val(obj),												\
			(jfieldID)Nativeint_val(field)));								\
}																			\
value ocaml_java__read_field_static_##NAME(value cls, value field)					\
{																			\
	return CONV_OF((*env)->GetStatic##JNAME##Field(env,						\
			Java_obj_val(cls),												\
			(jfieldID)Nativeint_val(field)));								\
}

// Generates push_* functions
// `CONV_TO` is a function that takes an OCaml value and generates a native type
// `DST` is the jvalue's field
#define GEN_PUSH(NAME, JNAME, DST, CONV_TO) \
value ocaml_java__push_##NAME(value v)			\
{												\
	arg_stack[arg_count].DST = CONV_TO(v);		\
	arg_count++;								\
	return Val_unit;							\
}

#define GEN_PUSH_UNBOXED(NAME, TYPE, DST) \
value ocaml_java__push_##NAME##_unboxed(TYPE v)		\
{													\
	arg_stack[arg_count].DST = v;					\
	arg_count++;									\
	return Val_unit;								\
}

// Generates write_field{,_static}_* functions
#define GEN_WRITE(NAME, JNAME, DST, CONV_TO) \
value ocaml_java__write_field_##NAME(value obj, value field, value v)			\
{																				\
	if (obj == Java_null_val)													\
		caml_failwith("Java.write_field: null");								\
	(*env)->Set##JNAME##Field(env,												\
		Java_obj_val(obj),														\
		(jfieldID)Nativeint_val(field),											\
		CONV_TO(v));															\
	return Val_unit;															\
}																				\
value ocaml_java__write_field_static_##NAME(value cls,					\
	value field, value v)														\
{																				\
	(*env)->SetStatic##JNAME##Field(env,										\
		Java_obj_val(cls),														\
		(jfieldID)Nativeint_val(field),											\
		CONV_TO(v));															\
	return Val_unit;															\
}

#define GEN_CALL_READ_PUSH_WRITE(NAME, JNAME, TYPE, CONV_OF, DST, CONV_TO) \
	GEN_CALL(NAME, JNAME, TYPE, CONV_OF) \
	GEN_READ(NAME, JNAME, CONV_OF) \
	GEN_PUSH(NAME, JNAME, DST, CONV_TO) \
	GEN_WRITE(NAME, JNAME, DST, CONV_TO)

GEN(GEN_CALL_READ_PUSH_WRITE)
GEN_CALL_(void, Void, (void), Val_unit)
GEN_PUSH_UNBOXED(float, double, f)
GEN_PUSH_UNBOXED(double, double, d)


#undef GEN_CALL_
#undef GEN_CALL
#undef GEN_READ
#undef GEN_PUSH
#undef GEN_WRITE

/*
** ========================================================================== **
** Jarray API
*/

static value new_object_array(jclass cls, jobject obj, jint length)
{
	return alloc_java_obj(env,
			(*env)->NewObjectArray(env, length, cls, obj));
}

#define GEN_JARRAY_CREATE_PRIM(NAME, JNAME, ...) \
value ocaml_java__jarray_create_##NAME(value length)		\
{															\
	return alloc_java_obj(env,								\
		(*env)->New##JNAME##Array(env, Long_val(length)));	\
}

GEN_PRIM(GEN_JARRAY_CREATE_PRIM)

value ocaml_java__jarray_create_object(value cls, value obj, value length)
{
	return new_object_array(Java_obj_val(cls),
			Java_obj_val_opt(obj),
			Long_val(length));
}

value ocaml_java__jarray_create_string(value length)
{
	jclass const string_cls = (*env)->FindClass(env, "java/lang/String");
	return new_object_array(string_cls, NULL, Long_val(length));
}

value ocaml_java__jarray_create_value(value length)
{
	jclass const string_cls = (*env)->FindClass(env, "juloo/javacaml/Value");
	return new_object_array(string_cls, NULL, Long_val(length));
}

value ocaml_java__jarray_length(value array)
{
	return Val_long((*env)->GetArrayLength(env, Java_obj_val(array)));
}

static void	check_out_of_bound_exception(void)
{
	if ((*env)->ExceptionOccurred(env) == NULL)
		return ;
	(*env)->ExceptionClear(env);
	caml_invalid_argument("index out of bound");
}

#define GEN_JARRAY_SET_PRIM(NAME, JNAME, TYPE, CONV_OF, DST, CONV_TO) \
value ocaml_java__jarray_set_##NAME(value array, value index, value v)		\
{																			\
	TYPE const buf = CONV_TO(v);											\
	(*env)->Set##JNAME##ArrayRegion(env, Java_obj_val(array),				\
			Long_val(index), 1, &buf);										\
	check_out_of_bound_exception();											\
	return Val_unit;														\
}

#define GEN_JARRAY_SET_OBJ(NAME, JNAME, TYPE, CONV_OF, DST, CONV_TO) \
value ocaml_java__jarray_set_##NAME(value array, value index, value v)		\
{																			\
	(*env)->SetObjectArrayElement(env, Java_obj_val(array),					\
			Long_val(index), CONV_TO(v));									\
	check_out_of_bound_exception();											\
	return Val_unit;														\
}

#define GEN_JARRAY_GET_PRIM(NAME, JNAME, TYPE, CONV_OF, ...) \
value ocaml_java__jarray_get_##NAME(value array, value index)				\
{																			\
	TYPE buf;																\
	(*env)->Get##JNAME##ArrayRegion(env, Java_obj_val(array),				\
			Long_val(index), 1, &buf);										\
	check_out_of_bound_exception();											\
	return CONV_OF(buf);													\
}

#define GEN_JARRAY_GET_OBJ(NAME, JNAME, TYPE, CONV_OF, ...) \
value ocaml_java__jarray_get_##NAME(value array, value index)				\
{																			\
	jobject obj;															\
																			\
	obj = (*env)->GetObjectArrayElement(env,								\
			Java_obj_val(array), Long_val(index));							\
	check_out_of_bound_exception();											\
	return CONV_OF(obj);													\
}

GEN_PRIM(GEN_JARRAY_SET_PRIM)
GEN_OBJ(GEN_JARRAY_SET_OBJ)
GEN_PRIM(GEN_JARRAY_GET_PRIM)
GEN_OBJ(GEN_JARRAY_GET_OBJ)

/*
** ========================================================================== **
** Jthrowable API
*/

value ocaml_java__jthrowable_throw(value thrwbl)
{
	(*env)->Throw(env, Java_obj_val(thrwbl));
	return Val_unit;
}

value ocaml_java__jthrowable_throw_new(value cls, value msg)
{
	(*env)->ThrowNew(env, Java_obj_val(cls), String_val(msg));
	return Val_unit;
}
