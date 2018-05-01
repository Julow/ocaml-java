let () =
	Printexc.record_backtrace true;
	let class_path = match Array.to_list Sys.argv with
		| _ :: (_ :: _ as cp)	-> String.concat ":" cp
		| _						-> failwith "Missing argument: class path"
	in
	Java.init [|
		"-Djava.class.path=" ^ class_path;
		"-ea";
		"-Xcheck:jni"
	|];
	try
		Test_caml.run ();
		Test_caml.run ();
		Test_java.init ();
		Test_java.run ()
	with Java.Exception e ->
		Jthrowable.print_stack_trace e;
		failwith ""
