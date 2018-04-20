let run () =
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
		for i = 0 to 10 do
			Test_caml.run ();
			Test_java.run ();
			Test_ppx.run ()
		done
	with Java.Exception e ->
		Jthrowable.print_stack_trace e;
		failwith ""

let () =
	Printexc.record_backtrace true;
	(* quick check if executed from java *)
	(if Sys.argv.(0) <> "" then run ())
