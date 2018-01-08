# -

run: all
	LD_LIBRARY_PATH=. java -ea -cp test.jar:../javacaml/javacaml.jar test.Test

all: | libs
	make libtest.so test.jar

libtest.so: $(wildcard *.ml *.c)
	ocamlfind ocamlopt -linkpkg -output-obj \
		-runtime-variant _pic \
		-ccopt "-shared" \
		-cclib "-Wl,--whole-archive ../javacaml/libjavacaml.a -Wl,--no-whole-archive" \
		$^ -o $@

test.jar: $(wildcard test/*.java)
	javac -cp ../javacaml/javacaml.jar $^
	jar cf $@ test/*.class

libs:
	make -C ../javacaml

clean:
	rm -f $(wildcard *.o *.cmo *.cmi *.cmx *.so *.jar test/*.class)
	make -C ../javacaml clean

re: clean
	make run

.PHONY: all run libs clean re
