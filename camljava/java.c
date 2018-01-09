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

#define Java_null_val	(Val_int(0))

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
	if (class_ == Java_null_val)
		caml_invalid_argument("Java.Class.member_method: class is `null`");
	return get_method(Java_obj_val(class_), String_val(name), String_val(sig));
}

value ocaml_java__static_method(value class_, value name, value sig)
{
	jmethodID id;

	if (class_ == Java_null_val)
		caml_invalid_argument("Java.Class.static_method: class is `null`");
	id = (*env)->GetStaticMethodID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
		caml_raise_not_found();
	return caml_copy_nativeint((intnat)id);
}

value ocaml_java__virtual_method(value class_, value name, value sig)
{
	if (class_ == Java_null_val)
		caml_invalid_argument("Java.Class.virtual_method: class is `null`");
	return get_method(Java_obj_val(class_), String_val(name), String_val(sig));
}

value ocaml_java__init_method(value class_, value sig)
{
	if (class_ == Java_null_val)
		caml_invalid_argument("Java.Class.init_method: class is `null`");
	return get_method(Java_obj_val(class_), "<init>", String_val(sig));
}

value ocaml_java__member_field(value class_, value name, value sig)
{
	jfieldID id;

	if (class_ == Java_null_val)
		caml_invalid_argument("Java.Class.member_field: class is `null`");
	id = (*env)->GetFieldID(env, Java_obj_val(class_),
			String_val(name), String_val(sig));
	if (id == NULL)
		caml_raise_not_found();
	return caml_copy_nativeint((intnat)id);
}

value ocaml_java__static_field(value class_, value name, value sig)
{
	jfieldID id;

	if (class_ == Java_null_val)
		caml_invalid_argument("Java.Class.static_field: class is `null`");
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
