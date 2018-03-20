let jar_files = [
	"test_javacaml.jar";
	"../bin/ocaml-java.jar"
]

let () = Printexc.record_backtrace true

let () =
	(* quick check if executed from javacaml's tests *)
	if Sys.argv.(0) <> "" then begin
		Java.init [|
			"-Djava.class.path=" ^ String.concat ":" jar_files;
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
	end
