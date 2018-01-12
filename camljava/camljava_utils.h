#ifndef CAMLJAVA_UTILS_H
# define CAMLJAVA_UTILS_H

#include <caml/mlvalues.h>
#include <caml/custom.h>

// Utils functions
// meant to be shared between javacaml and camljava

// Initialisation function
// defined only if built with -DTARGET_JAVACAML
void ocaml_java__camljava_init(JNIEnv *_env);

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

extern struct custom_operations ocamljava__java_obj_custom_ops;

static value alloc_java_obj(JNIEnv *env, jobject object)
{
	value v;

	if (object == NULL)
		return Java_null_val;
	v = caml_alloc_custom(&ocamljava__java_obj_custom_ops, sizeof(jobject), 0, 1);
	object = (*env)->NewGlobalRef(env, object);
	*(jobject*)Data_custom_val(v) = object;
	return v;
}

#endif
