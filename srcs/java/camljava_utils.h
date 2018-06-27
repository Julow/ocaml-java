#ifndef CAMLJAVA_UTILS_H
# define CAMLJAVA_UTILS_H

#include <jni.h>

#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

// Option type
#define Val_none	Val_long(0)
#define Some_val(v)	Field(v, 0)

static inline value copy_some(value v)
{
	CAMLparam1(v);
	CAMLlocal1(some);
	some = caml_alloc(1, 0);
	Store_field(some, 0, v);
	CAMLreturn(some);
}

// Utils functions
// meant to be shared between javacaml and camljava

// Initialisation function
// defined only if built with -DTARGET_JAVACAML
void ocaml_java__camljava_init(JNIEnv *_env);

// Returns the JNIEnv used by camljava
JNIEnv *ocaml_java__camljava_env(void);

/*
** ========================================================================== **
** OCaml value that represent a `jobject` pointer or the `null` value
** -
** The `jobject` is registered as global ref
** and automatically released when it is garbage collected
** -
** Java_obj_val(v)		Returns the `jobject` pointer, must not be `null`
** Java_null_val		`null` value
** Java_obj_val_opt(v)	Returns the `jobject` pointer or `null`
** alloc_java_obj(obj)	Allocates the value, `obj` is registered as global ref
*/

#define Java_obj_val(v)	(*(jobject*)Data_custom_val(v))

#define Java_null_val	(Val_long(0))

#define Java_obj_val_opt(v)	(((v) == Java_null_val) ? NULL : Java_obj_val(v))

extern struct custom_operations ocamljava__java_obj_custom_ops;

static inline value alloc_java_obj(JNIEnv *env, jobject object)
{
	value v;

	if ((*env)->IsSameObject(env, object, NULL))
		return Java_null_val;
	v = caml_alloc_custom(&ocamljava__java_obj_custom_ops, sizeof(jobject), 0, 1);
	object = (*env)->NewGlobalRef(env, object);
	*(jobject*)Data_custom_val(v) = object;
	return v;
}

#endif
