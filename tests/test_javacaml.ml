let () =
	Printexc.record_backtrace true;
	Test_java.init ();
	Callback.register "camljava_do_test" Test_caml.run
