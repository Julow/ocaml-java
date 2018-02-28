#ifndef JAVACAML_UTILS_H
# define JAVACAML_UTILS_H

#include <jni.h>

#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

// Check if a `jobject` is `null`
#define IS_NULL(env, OBJ) ((*env)->IsSameObject(env, OBJ, NULL))

// Convertion from/to Java string
// OCaml strings are expected to be UTF-8 encoded strings
// `ocaml_java__of_jstring` allocs an OCaml string
// `ocaml_java__to_jstring` returns a local ref
value ocaml_java__of_jstring(JNIEnv *env, jstring str);
jstring ocaml_java__to_jstring(JNIEnv *env, value str);

// Returns a new juloo.javacaml.Value pointing to `v`
jobject ocaml_java__jvalue_new(JNIEnv *env, value v);
value ocaml_java__jvalue_get(JNIEnv *env, jobject v);

#define JVALUE_NEW ocaml_java__jvalue_new
#define JVALUE_GET ocaml_java__jvalue_get

// Initialise javacaml
// defined only if built with -DTARGET_CAMLJAVA
void ocaml_java__javacaml_init(JNIEnv *env);

#endif
