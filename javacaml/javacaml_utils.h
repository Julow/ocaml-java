#ifndef JAVACAML_UTILS_H
# define JAVACAML_UTILS_H

#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

// Copy the content of `str` into a new OCaml string
static value jstring_to_cstring(JNIEnv *env, jstring str)
{
	char const *const str_utf = (*env)->GetStringUTFChars(env, str, NULL);
	value cstr;

	cstr = caml_copy_string(str_utf);
	(*env)->ReleaseStringUTFChars(env, str, str_utf);
	return cstr;
}

// Returns a new juloo.javacaml.Value pointing to `v`
jobject ocaml_java__jvalue_new(JNIEnv *env, value v);
value ocaml_java__jvalue_get(JNIEnv *env, jobject v);

#define JVALUE_NEW ocaml_java__jvalue_new
#define JVALUE_GET ocaml_java__jvalue_get

// Initialise javacaml
// defined only if built with -DTARGET_CAMLJAVA
void ocaml_java__javacaml_init(JNIEnv *env);

#endif
