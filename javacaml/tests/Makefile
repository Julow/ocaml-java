# -

JAVACAML_DIR = ..

JAVACAML_JAR = $(JAVACAML_DIR)/bin/javacaml.jar
JAVACAML_A = $(JAVACAML_DIR)/bin/libjavacaml.a

run: all
	LD_LIBRARY_PATH=. java -ea -cp test.jar:$(JAVACAML_JAR) javacaml.test.Test

all: | libs
	make libtest.so test.jar

libtest.so: $(wildcard *.ml *.c)
	ocamlfind ocamlopt -linkpkg -output-obj \
		-runtime-variant _pic \
		-ccopt "-shared" \
		-cclib "-Wl,--whole-archive $(JAVACAML_A) -Wl,--no-whole-archive" \
		$^ -o $@

test.jar: $(wildcard javacaml/test/*.java)
	javac -cp $(JAVACAML_JAR) $^
	jar cf $@ javacaml/test/*.class

libs:
	make -C $(JAVACAML_DIR)

clean:
	rm -f $(wildcard *.o *.cmo *.cmi *.cmx *.so *.jar test/javacaml/*.class)
	make -C $(JAVACAML_DIR) clean

re: clean
	make run

.PHONY: all run libs clean re
