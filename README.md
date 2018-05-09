# OCaml <-> Java Interface

Interop with Java

Provides a low-level, unsafe interface between OCaml and Java
and high-level, typed OCaml interface using a [PPX rewriter](ppx).

This is still a work in progress.

Heavily inspired by [camljava](https://github.com/xavierleroy/camljava)

## Example

A simple example that use the Java's DateFormat class

```ocaml
let () = Java.init [| "-Djava.class.path=bin/ocaml-java.jar" |]

class%java date "java.util.Date" = object end

class%java format "java.text.Format" = object end

class%java date_format "java.text.DateFormat" =
object
	inherit format
	method format : date -> string = "format"
	method parse : string -> date = "parse"
	method [@static] get_instance : date_format = "getInstance"
end

let () =
	let format = Date_format.get_instance () in
	let date_string = "09/13/1996 9:45 AM GMT+1" in
	let date = Date_format.parse format date_string in
	print_endline (Date_format.format format date)
```

Example `jbuild` file:

```
(jbuild_version 1)
(executable
 ((name test)
  (libraries (ocamljava.camljava))
  (preprocess (pps (ocamljava.ppx)))))
```

## Documentation

Modules interfaces:
- [Java](srcs/ml/java.mli)
- [Jcall](srcs/ml/jcall.mli), unsafe low-level api for calling Java methods
- [Jclass](srcs/ml/jclass.mli) to query class/method/field handles
- [Jarray](srcs/ml/jarray.mli) to manipulate Java arrays
- [Jrunnable](srcs/ml/jrunnable.mli) to create and run [Runnable](https://docs.oracle.com/javase/8/docs/api/java/lang/Runnable.html) objects
- [Jthrowable](srcs/ml/jthrowable.mli) to throw and access Java exceptions

Ppx: [README](ppx/README.md)

Java side: [Caml](srcs/java/juloo/javacaml/Caml.java)
