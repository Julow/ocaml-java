#include <stddef.h>
#include <jni.h>
#include <caml/mlvalues.h>
#include <caml/callback.h>

static jclass
	NullPointerException,
	NamedValue,
	NamedValueNotFoundException;

static jmethodID
	NamedValue_init;

static jfieldID
	NamedValue_closure;

#define IS_NULL(env, obj) ((*env)->IsSameObject(env, obj, NULL))

// ========================================================================== //
// Caml.get_named_value

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
// Caml.init

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
	(void)c;
}
