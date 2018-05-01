#include <jni.h>

#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

void	ocaml_java__camljava_setenv(JNIEnv *e);
void	ocaml_java__javacaml_init();
int		ocaml_java__javacaml_natives(JNIEnv *env);

static JavaVM *jvm;

#define JNI_VERSION JNI_VERSION_1_4

// (ml) Java.startup
value ocaml_java__startup(value opt_array)
{
	CAMLparam1(opt_array);
	int const		opt_count = caml_array_length(opt_array);
	JavaVMOption	*options;
	JavaVMInitArgs	vm_args;
	JNIEnv			*env;
	int				success;
	int				i;

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
	ocaml_java__camljava_setenv(env);
	ocaml_java__javacaml_init();
	if (!ocaml_java__javacaml_natives(env))
		caml_failwith("Failed to link javacaml");
	CAMLreturn(Val_unit);
}

// (ml) Java.shutdown
value ocaml_java__shutdown(value unit)
{
	(*jvm)->DestroyJavaVM(jvm);
	return Val_unit;
	(void)unit;
}

// (java) Caml.startup
void Java_juloo_javacaml_Caml_startup(JNIEnv *env, jclass c)
{
	(void)env;
	(void)c;
}
