# -

OCAMLJAVA_DIR = ../..

OCAMLJAVA_JAR = $(OCAMLJAVA_DIR)/bin/ocaml-java.jar
JAVACAML_A = $(OCAMLJAVA_DIR)/bin/libjavacaml.a

CAMLJAVA_TESTS_DIR = ../../camljava/tests

run: all
	CP=test.jar:$(OCAMLJAVA_JAR):$(CAMLJAVA_TESTS_DIR)/test.jar; \
	LD_LIBRARY_PATH=. java -ea -cp "$$CP" javacaml.test.Test

all: | libs
	make libtest.so test.jar

libtest.so: $(wildcard *.ml *.c) $(CAMLJAVA_TESTS_DIR)/test.ml
	ocamlfind ocamlopt -linkpkg -output-obj \
		-runtime-variant _pic \
		-ccopt "-shared" \
		-I $(OCAMLJAVA_DIR)/bin javacaml.cmxa \
		unix.cmxa -g \
		$^ -o $@

test.jar: $(wildcard javacaml/test/*.java)
	javac -cp $(OCAMLJAVA_JAR) $^
	jar cf $@ javacaml/test/*.class

libs:
	make -C $(OCAMLJAVA_DIR)

clean:
	rm -f $(wildcard *.o *.cmo *.cmi *.cmx *.so *.jar javacaml/test/*.class)
	make -C $(OCAMLJAVA_DIR) clean

re: clean
	make run

.PHONY: all run libs clean re
