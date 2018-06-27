#include <jni.h>

#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

void	ocaml_java__camljava_setenv(JNIEnv *e);
void	ocaml_java__javacaml_init();

// (ml) Java.startup
value	ocaml_java__startup(value opt_array)
{
	caml_failwith("Java.init: Unavailable when linked to javacaml");
	return Val_unit;
	(void)opt_array;
}

// (ml) Java.shutdown
value	ocaml_java__shutdown(value unit)
{
	return Val_unit;
	(void)unit;
}

// Use caml_startup_exn if available
# if OCAML_VERSION_MAJOR >= 4 && OCAML_VERSION_MINOR >= 5
static void init_ocaml(JNIEnv *env, char **argv)
{
	value const res = caml_startup_exn(argv);

	if (Is_exception_result(res))
		throw_caml_exception(env, Extract_exception(res));
}
# else
#  define init_ocaml(env, argv) caml_startup(argv)
# endif

// (java) Caml.startup
void Java_juloo_javacaml_Caml_startup(JNIEnv *env, jclass c)
{
	static char *argv[] = { "", NULL };

	ocaml_java__camljava_setenv(env);
	init_ocaml(env, argv);
	ocaml_java__javacaml_init();
	(void)c;
}
