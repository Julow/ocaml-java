# OCaml <-> Java Interface

Interop with Java

Provides a low-level, unsafe interface between OCaml and Java
and high-level, typed OCaml interface using a PPX rewriter

Heavily inspired by [camljava](https://github.com/xavierleroy/camljava)

## Installation

Clone this repository, check where java is and run:

```sh
make JAVA_HOME="$JAVA_HOME"
```

Replace `$JAVA_HOME` with the path to Java's JDK

## Documentation

Modules interfaces:
- [Java](srcs/ml/java.mli) contains almost everything
- [Jclass](srcs/ml/jclass.mli) to query class/method/field handles
- [Jarray](srcs/ml/jarray.mli) to manipulate Java arrays
- [Jrunnable](srcs/ml/jrunnable.mli) to create and run [Runnable](https://docs.oracle.com/javase/8/docs/api/java/lang/Runnable.html) objects
- [Jthrowable](srcs/ml/jthrowable.mli) to throw and access Java exceptions

Java side:
- [Caml](srcs/java/juloo/javacaml/Caml.java), call OCaml functions/methods
- [Value](srcs/java/juloo/javacaml/Value.java) is the representation of an OCaml value on the Java side
