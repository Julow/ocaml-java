#include <jni.h>

/*
** ========================================================================== **
** Classes
** -
** Returns the handle object for a class, constructor, field or method
** Lazily initialising it
*/

#define CLASS(CLASS)			ocaml_java__class_##CLASS(env)
#define CONSTR(CLASS)			ocaml_java__init_##CLASS(env)
#define FIELD(CLASS, NAME)		ocaml_java__field_##CLASS##_##NAME(env)
#define METHOD(CLASS, NAME)		ocaml_java__method_##CLASS##_##NAME(env)

/*
** ========================================================================== **
** Declarations
** -
*/

#define CLASSES_DECL(_CLASS, _INIT, _FIELD, _METHOD) \
	_CLASS("java/lang/", NullPointerException) \
	_CLASS("java/lang/", StackTraceElement) \
		_INIT(StackTraceElement, "(Ljava/lang/String;Ljava/lang/String;" \
			"Ljava/lang/String;I)V") \
	_CLASS("java/lang/", Comparable) \
		_METHOD(Comparable, compareTo, "(Ljava/lang/Object;)I") \
	_CLASS("java/lang/", Runnable) \
		_METHOD(Runnable, run, "()V") \
	_CLASS("java/lang/", String) \
	_CLASS("java/lang/", Object) \
		_METHOD(Object, toString, "()Ljava/lang/String;") \
		_METHOD(Object, equals, "(Ljava/lang/Object;)Z") \
		_METHOD(Object, hashCode, "()I") \
	_CLASS("juloo/javacaml/", Callback) \
		_INIT(Callback, "(J)V") \
		_FIELD(Callback, closure, "J") \
	_CLASS("juloo/javacaml/", Value) \
		_INIT(Value, "(J)V") \
		_FIELD(Value, value, "J") \
	_CLASS("juloo/javacaml/", RunnableValue) \
		_INIT(RunnableValue, "(J)V") \
	_CLASS("juloo/javacaml/", CamlException) \
		_INIT(CamlException, "(Ljava/lang/String;Ljava/lang/Throwable;" \
			"[Ljava/lang/StackTraceElement;)V") \
	_CLASS("juloo/javacaml/", CallbackNotFoundException) \
	_CLASS("juloo/javacaml/", InvalidMethodIdException) \
	_CLASS("juloo/javacaml/", ArgumentStackOverflowException) \
	_CLASS("juloo/javacaml/", ThreadException)

/*
** ========================================================================== **
*/

#define DECL_CLASS(K, C)		jclass ocaml_java__class_##C(JNIEnv*);
#define DECL_INIT(C, S)			jmethodID ocaml_java__init_##C(JNIEnv*);
#define DECL_FIELD(C, N, S)		jfieldID ocaml_java__field_##C##_##N(JNIEnv*);
#define DECL_METHOD(C, N, S)	jmethodID ocaml_java__method_##C##_##N(JNIEnv*);

CLASSES_DECL(DECL_CLASS, DECL_INIT, DECL_FIELD, DECL_METHOD)

#undef DECL_CLASS
#undef DECL_INIT
#undef DECL_FIELD
#undef DECL_METHOD
#undef _ID
