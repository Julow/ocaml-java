let () =
	let w file_name fmt =
		Printf.kfprintf close_out (open_out file_name) fmt
	in
	match Sys.getenv "JAVA_HOME" with
	| exception Not_found ->
		failwith "Environment variable JAVA_HOME is not set."
	| java_home ->
		w "c_flags.sexp" "(-I \"%s/include\" -I \"%s/include/linux\")" java_home java_home;
		let lpath = java_home ^ "/jre/lib/amd64/server" in
		w "c_library_flags.sexp" "(-dllpath \"%s/libjvm.so\" \"-L%s\")" lpath lpath
