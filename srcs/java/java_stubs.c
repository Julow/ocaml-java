#include "camljava_utils.h"
#include "classes.h"
#include "javacaml_utils.h"

#include <jni.h>
#include <stddef.h>

#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

static JNIEnv *env;

/*
** ========================================================================== **
** Exceptions
*/

static value *java_exception = NULL;

static value raise_java_exception(jthrowable exn)
{
	CAMLparam0();
	CAMLlocal1(thrbl);
	thrbl = alloc_java_obj(env, exn);
	(*env)->DeleteLocalRef(env, exn);
	if (java_exception == NULL)
	{
		java_exception = caml_named_value("Java.Exception");
		if (java_exception == NULL)
			caml_failwith("camljava not properly linked");
	}
	caml_raise_with_arg(*java_exception, thrbl);
	CAMLreturn(Val_unit);
}

// Check if a Java exception has been thrown
// if there is, raises Java.Exception
static void check_exceptions(void)
{
	jthrowable exn;

	exn = (*env)->ExceptionOccurred(env);
	if (exn == NULL) return ;
	(*env)->ExceptionClear(env);
	raise_java_exception(exn);
}

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
	jobject				obj_a;
	jobject const		obj_b = Java_obj_val_opt(b);
	jint				d;

	if (a == Java_null_val)
		caml_failwith("Java.compare: Null");
	obj_a = Java_obj_val(a);
	if (!(*env)->IsInstanceOf(env, obj_a, CLASS(Comparable)))
		caml_failwith("Java.compare: Must implements Comparable");
	d = (*env)->CallIntMethod(env, obj_a, METHOD(Comparable, compareTo), obj_b);
	check_exceptions();
	return d;
}

static intnat java_obj_hash(value obj)
{
	jobject			obj_;
	int				hash;

	if (obj == Java_null_val)
		return 0;
	obj_ = Java_obj_val(obj);
	hash = (*env)->CallIntMethod(env, obj_, METHOD(Object, hashCode));
	check_exceptions();
	return hash & 0x7FFFFF;
}

struct custom_operations ocamljava__java_obj_custom_ops = {
	.identifier = "ocaml_java__obj",
	.finalize = java_obj_finalize,
	.compare = java_obj_compare,
	.compare_ext = custom_compare_ext_default,
	.hash = java_obj_hash,
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
	jclass	cls;
	value	v;

	if (obj == Java_null_val)
		caml_failwith("Java.objectclass: null");
	cls = (*env)->GetObjectClass(env, Java_obj_val(obj));
	v = alloc_java_obj(env, cls);
	(*env)->DeleteLocalRef(env, cls);
	return v;
}

value ocaml_java__compare(value a, value b)
{
	return Val_long(java_obj_compare(a, b));
}

value ocaml_java__to_string(value obj)
{
	jstring		str;
	value		r;

	if (obj == Java_null_val)
		caml_failwith("Java.to_string: Null");
	str = (*env)->CallObjectMethod(env, Java_obj_val(obj),
			METHOD(Object, toString));
	check_exceptions();
	r = ocaml_java__of_jstring(env, str);
	(*env)->DeleteLocalRef(env, str);
	return r;
}

value ocaml_java__equals(value a, value b)
{
	int			eq;

	if (a == Java_null_val)
		caml_failwith("Java.equals: Null");
	eq = (*env)->CallBooleanMethod(env, Java_obj_val(a),
			METHOD(Object, equals), Java_obj_val_opt(b));
	check_exceptions();
	return Val_long(eq);
}

value ocaml_java__hash_code(value obj)
{
	return (Val_long(java_obj_hash(obj)));
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
	value v;

	c = (*env)->FindClass(env, String_val(name));
	if (c == NULL)
	{
		(*env)->ExceptionClear(env);
		caml_raise_not_found();
	}
	v = alloc_java_obj(env, c);
	(*env)->DeleteLocalRef(env, c);
	return v;
}

value ocaml_java__class_get_meth(value class_, value name, value sig)
{
	jmethodID id;

	id = (*env)->GetMethodID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
	{
		(*env)->ExceptionClear(env);
		caml_raise_not_found();
	}
	return caml_copy_nativeint((intnat)id);
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

JNIEnv	*ocaml_java__camljava_env(void)
{
	return env;
}

void	ocaml_java__camljava_setenv(JNIEnv *e)
{
	env = e;
}

/*
** ========================================================================== **
** Calling
** -
** `arg_stack` represents the argument stack
** `local_ref_stack` stores references to objects allocated in `arg_` functions
** `local_ref_cleared` is set to true before calling a method
** 		so that the next call to `push_local_ref` assumes the stack is empty
*/

#define ARG_STACK_MAX_SIZE	16
#define LOCALREF_STACK_MAX_SIZE	32

static jvalue arg_stack[ARG_STACK_MAX_SIZE];
static int arg_count = 0;

// // Local refs

static jobject local_ref_stack[LOCALREF_STACK_MAX_SIZE];
static int local_ref_count = 0;
static int local_ref_cleared = 0;

// Clear the local_ref_stack
// Should be called after calls
static void clear_local_refs(void)
{
	int i;

	for (i = 0; i < local_ref_count; i++)
		(*env)->DeleteLocalRef(env, local_ref_stack[i]);
	local_ref_count = 0;
	local_ref_cleared = 0;
}

// Adds a local ref onto the stack
static void push_local_ref(jobject obj)
{
	if (local_ref_cleared)
	{
		local_ref_count = 0;
		local_ref_cleared = 0;
	}
	local_ref_stack[local_ref_count] = obj;
	local_ref_count++;
}

// Must be called before calling a java method
// Reset the arg_stack and mark the local_ref_stack to be cleared later
static void begin_call(void)
{
	local_ref_cleared = 1;
	arg_count = 0;
}

/*
** ========================================================================== **
** Convertions for each types
** -
** `conv_of` functions delete local refs they get as parameters
** `conv_to` functions put the local refs they allocate in the local_ref_stack
*/

static value conv_of_string(jstring str)
{
	value v;

	if (IS_NULL(env, str)) caml_failwith("Null string");
	v = ocaml_java__of_jstring(env, str);
	(*env)->DeleteLocalRef(env, str);
	return v;
}

static value conv_of_value(jobject v)
{
	value jvalue;

	if (IS_NULL(env, v)) caml_failwith("Null value");
	jvalue = JVALUE_GET(env, v);
	(*env)->DeleteLocalRef(env, v);
	return jvalue;
}

static value conv_of_array(jarray a)
{
	value v;

	if (IS_NULL(env, a)) caml_failwith("Null array");
	v = alloc_java_obj(env, a);
	(*env)->DeleteLocalRef(env, a);
	return v;
}

static value conv_of_string_opt(jstring str)
{
	CAMLparam0();
	CAMLlocal1(cstr);
	if (IS_NULL(env, str)) CAMLreturn(Val_none);
	cstr = ocaml_java__of_jstring(env, str);
	(*env)->DeleteLocalRef(env, str);
	CAMLreturn(copy_some(cstr));
}

static value conv_of_value_opt(jobject v)
{
	CAMLparam0();
	CAMLlocal1(jvalue);
	if (IS_NULL(env, v)) CAMLreturn(Val_none);
	jvalue = JVALUE_GET(env, v);
	(*env)->DeleteLocalRef(env, v);
	CAMLreturn(copy_some(jvalue));
}

static value conv_of_array_opt(jarray a)
{
	CAMLparam0();
	CAMLlocal1(v);
	if (IS_NULL(env, a)) CAMLreturn(Val_none);
	v = alloc_java_obj(env, a);
	(*env)->DeleteLocalRef(env, a);
	CAMLreturn(copy_some(v));
}

static value conv_of_obj(jobject obj)
{
	value v;

	v = alloc_java_obj(env, obj);
	(*env)->DeleteLocalRef(env, obj);
	return v;
}

static jobject conv_to_string(value v)
{
	jstring const js = ocaml_java__to_jstring(env, v);

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

static jarray conv_to_array_opt(value opt)
{
	if (opt == Val_none)
		return NULL;
	return Java_obj_val(Some_val(opt));
}

// Calls `GEN` for each primitive types:
//  int, bool, byte, short, int32, long, char, float, double
// with params:
//  NAME	an identifier for each primitive
//  JNAME	the type part in the JNI functions names
//  TYPE	the jni type
//  CONV_OF	`TYPE` to OCaml's `value` convertion
//  DST		field of the `jvalue` union
//  CONV_TO	OCaml's `value` to `TYPE` convertion
#define GEN_PRIM_INT(GEN) \
	GEN(int,		Int,		jint,		Val_long,			i,	Long_val) \
	GEN(bool,		Boolean,	jboolean,	Val_bool,			z,	Long_val) \
	GEN(byte,		Byte,		jbyte,		Val_long,			b,	Long_val) \
	GEN(short,		Short,		jshort,		Val_long,			s,	Long_val) \
	GEN(char,		Char,		jchar,		Val_long,			c,	Long_val) \
	GEN(int32,		Int,		jint,		caml_copy_int32,	i,	Int32_val) \
	GEN(long,		Long,		jlong,		caml_copy_int64,	j,	Int64_val)
#define GEN_PRIM_FLOAT(GEN) \
	GEN(float,		Float,		jfloat,		caml_copy_double,	f,	Double_val) \
	GEN(double,		Double,		jdouble,	caml_copy_double,	d,	Double_val)

#define GEN_PRIM(GEN) \
	GEN_PRIM_INT(GEN) \
	GEN_PRIM_FLOAT(GEN)

// Same as `GEN_PRIM` for object types:
//  string, stringopt, object, value, valueopt
#define GEN_OBJ(GEN) \
	GEN(string,		Object,		jobject,	conv_of_string,		l,	conv_to_string) \
	GEN(string_opt,	Object,		jobject,	conv_of_string_opt,	l,	conv_to_string_opt) \
	GEN(object,		Object,		jobject,	conv_of_obj,		l,	Java_obj_val_opt) \
	GEN(value,		Object,		jobject,	conv_of_value,		l,	conv_to_value) \
	GEN(value_opt,	Object,		jobject,	conv_of_value_opt,	l,	conv_to_value_opt) \
	GEN(array,		Object,		jarray,		conv_of_array,		l,	Java_obj_val) \
	GEN(array_opt,	Object,		jarray,		conv_of_array_opt,	l,	conv_to_array_opt)

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
	value		v;

	jcls = Java_obj_val(cls);
	jmeth = (jmethodID)Nativeint_val(meth);
	begin_call();
	obj = (*env)->NewObjectA(env, jcls, jmeth, arg_stack);
	clear_local_refs();
	if (obj == NULL)
	{
		check_exceptions();
		caml_failwith("Jcall.new_: Allocation failed");
	}
	v = alloc_java_obj(env, obj);
	(*env)->DeleteLocalRef(env, obj);
	return v;
}

// Generates call{,_static,_nonvirtual}_* functions
// `CONV_OF` is a function that convert a native type to OCaml's value
#define GEN_CALL_(NAME, JNAME, RESULT, CONV_OF) \
value ocaml_java__call_##NAME(value obj, value meth)						\
{																			\
	if (obj == Java_null_val)												\
		caml_failwith("Jcall.call: null");									\
	begin_call();															\
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
	begin_call();															\
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
		caml_failwith("Jcall.call_nonvirtual: null");						\
	begin_call();															\
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
value ocaml_java__read_field_##NAME(value obj, value field)					\
{																			\
	if (obj == Java_null_val)												\
		caml_failwith("Jcall.read_field: null");							\
	return CONV_OF((*env)->Get##JNAME##Field(env,							\
			Java_obj_val(obj),												\
			(jfieldID)Nativeint_val(field)));								\
}																			\
value ocaml_java__read_field_static_##NAME(value cls, value field)			\
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
		caml_failwith("Jcall.write_field: null");								\
	(*env)->Set##JNAME##Field(env,												\
		Java_obj_val(obj),														\
		(jfieldID)Nativeint_val(field),											\
		CONV_TO(v));															\
	clear_local_refs();															\
	return Val_unit;															\
}																				\
value ocaml_java__write_field_static_##NAME(value cls,					\
	value field, value v)														\
{																				\
	(*env)->SetStatic##JNAME##Field(env,										\
		Java_obj_val(cls),														\
		(jfieldID)Nativeint_val(field),											\
		CONV_TO(v));															\
	clear_local_refs();															\
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
	jarray const	a = (*env)->NewObjectArray(env, length, cls, obj);
	value			v;

	v = alloc_java_obj(env, a);
	(*env)->DeleteLocalRef(env, a);
	return v;
}

#define GEN_JARRAY_CREATE_PRIM(NAME, JNAME, ...) \
value ocaml_java__jarray_create_##NAME(value length)						\
{																			\
	jarray const	a = (*env)->New##JNAME##Array(env, Long_val(length));	\
	value const		v = alloc_java_obj(env, a);								\
																			\
	(*env)->DeleteLocalRef(env, a);											\
	return v;																\
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
	return new_object_array(CLASS(String), NULL, Long_val(length));
}

value ocaml_java__jarray_create_value(value length)
{
	return new_object_array(CLASS(Value), NULL, Long_val(length));
}

value ocaml_java__jarray_create_array(value cls, value obj, value length)
{
	jobject const obj_ = (obj == Val_none) ? NULL : Java_obj_val(Some_val(obj));
	return new_object_array(Java_obj_val(cls), obj_, Long_val(length));
}

value ocaml_java__jarray_length(value array)
{
	return Val_long((*env)->GetArrayLength(env, Java_obj_val(array)));
}

static void	check_out_of_bound_exception(void)
{
	if ((*env)->ExceptionCheck(env))
	{
		(*env)->ExceptionClear(env);
		caml_invalid_argument("index out of bound");
	}
}

#define GEN_JARRAY_SET_PRIM(NAME, JNAME, TYPE, CONV_OF, DST, CONV_TO) \
value ocaml_java__jarray_set_##NAME(value array, value index, value v)		\
{																			\
	TYPE const buf = CONV_TO(v);											\
	(*env)->Set##JNAME##ArrayRegion(env, Java_obj_val(array),				\
			Long_val(index), 1, &buf);										\
	clear_local_refs();														\
	check_out_of_bound_exception();											\
	return Val_unit;														\
}

#define GEN_JARRAY_SET_OBJ(NAME, JNAME, TYPE, CONV_OF, DST, CONV_TO) \
value ocaml_java__jarray_set_##NAME(value array, value index, value v)		\
{																			\
	(*env)->SetObjectArrayElement(env, Java_obj_val(array),					\
			Long_val(index), CONV_TO(v));									\
	clear_local_refs();														\
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
	jobject	obj;															\
																			\
	obj = (*env)->GetObjectArrayElement(env,								\
			Java_obj_val(array), Long_val(index));							\
	check_out_of_bound_exception();											\
	return CONV_OF(obj);													\
}

#define GEN_ARRAY_CONV_INT(NAME, JNAME, TYPE, CONV_OF, DST, CONV_TO) \
static void array_conv_##NAME(value src, mlsize_t length, TYPE *dst)		\
{																			\
	mlsize_t i;																\
	for (i = 0; i < length; i++)											\
		dst[i] = CONV_TO(Field(src, i));									\
}

#define GEN_ARRAY_CONV_FLOAT(NAME, JNAME, TYPE, CONV_OF, DST, CONV_TO) \
static void array_conv_##NAME(value src, mlsize_t length, TYPE *dst)		\
{																			\
	mlsize_t i;																\
	for (i = 0; i < length; i++)											\
		dst[i] = Double_field(src, i);										\
}

GEN_PRIM_INT(GEN_ARRAY_CONV_INT)
GEN_PRIM_FLOAT(GEN_ARRAY_CONV_FLOAT)

#define GEN_JARRAY_OF(NAME, JNAME, TYPE, CONV_OF, DST, CONV_TO) \
value ocaml_java__jarray_of_##NAME(value src)								\
{																			\
	mlsize_t const	len = caml_array_length(src);							\
	jarray			dst;													\
	TYPE			*buff;													\
	value			res;													\
																			\
	dst = (*env)->New##JNAME##Array(env, len);								\
	buff = (*env)->Get##JNAME##ArrayElements(env, dst, NULL);				\
	array_conv_##NAME(src, len, buff);										\
	(*env)->Release##JNAME##ArrayElements(env, dst, buff, 0);				\
	res = alloc_java_obj(env, dst);											\
	(*env)->DeleteLocalRef(env, dst);										\
	return res;																\
}

GEN_PRIM(GEN_JARRAY_SET_PRIM)
GEN_OBJ(GEN_JARRAY_SET_OBJ)
GEN_PRIM(GEN_JARRAY_GET_PRIM)
GEN_OBJ(GEN_JARRAY_GET_OBJ)
GEN_PRIM(GEN_JARRAY_OF)

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

/*
** ========================================================================== **
** Jrunnable API
*/

// Very similar to ocaml_java__jvalue_new
value ocaml_java__runnable_create(value run)
{
	value *const	global = caml_stat_alloc(sizeof(value));
	jobject			obj;

	caml_register_global_root(global);
	*global = run;
	obj = (*env)->NewObject(env, CLASS(RunnableValue), CONSTR(RunnableValue),
		(jlong)global);
	return alloc_java_obj(env, obj);
}

value ocaml_java__runnable_run(value t)
{
	jobject const obj = Java_obj_val(t);

	(*env)->CallVoidMethod(env, obj, METHOD(Runnable, run));
	check_exceptions();
	return Val_unit;
}

value ocaml_java__runnable_of_obj(value obj)
{
	if (obj == Java_null_val
		|| !(*env)->IsInstanceOf(env, Java_obj_val(obj), CLASS(Runnable)))
		caml_failwith("Jrunnable.of_obj");
	return obj;
}
