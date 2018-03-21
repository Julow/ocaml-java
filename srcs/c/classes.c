#include <jni.h>
#include <stddef.h>
#include "classes.h"

static jobject wrap_global(JNIEnv *env, jobject local)
{
	jobject const global = (*env)->NewGlobalRef(env, local);
	(*env)->DeleteLocalRef(env, local);
	return global;
}

#define NO_WRAP(env, v) v

#define DECL_(TYPE, WRAP, NAME, CALL, ...) \
TYPE ocaml_java__##NAME(JNIEnv *env)								\
{																	\
	static TYPE cache = NULL;									\
	if (cache == NULL)												\
		cache = WRAP(env, (*env)->CALL(env, ##__VA_ARGS__));		\
	return cache;													\
}

#define DECL_CLASS(PKG, NAME) \
	DECL_(jclass, wrap_global, class_##NAME, FindClass, PKG #NAME)

#define DECL_METHOD(CLASS_NAME, NAME, SIGT) \
	DECL_(jmethodID, NO_WRAP, method_##CLASS_NAME##_##NAME, GetMethodID, \
		CLASS(CLASS_NAME), #NAME, SIGT)

#define DECL_INIT(CLASS_NAME, SIGT) \
	DECL_(jmethodID, NO_WRAP, init_##CLASS_NAME, GetMethodID, \
		CLASS(CLASS_NAME), "<init>", SIGT)

#define DECL_FIELD(CLASS_NAME, NAME, SIGT) \
	DECL_(jfieldID, NO_WRAP, field_##CLASS_NAME##_##NAME, GetFieldID, \
		CLASS(CLASS_NAME), #NAME, SIGT)

CLASSES_DECL(DECL_CLASS, DECL_INIT, DECL_FIELD, DECL_METHOD)
