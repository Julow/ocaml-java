# -

JAVACAML_DIR = ..
CAMLJAVA_DIR = ../../camljava

JAVACAML_JAR = $(JAVACAML_DIR)/bin/javacaml.jar
JAVACAML_A = $(JAVACAML_DIR)/bin/libjavacaml.a

CAMLJAVA_TESTS_DIR = ../../camljava/tests

run: all
	CP=test.jar:$(JAVACAML_JAR):$(CAMLJAVA_TESTS_DIR)/test.jar; \
	LD_LIBRARY_PATH=. java -ea -cp "$$CP" javacaml.test.Test

all: | libs
	make libtest.so test.jar

libtest.so: $(wildcard *.ml *.c) \
	$(CAMLJAVA_DIR)/java.mli $(CAMLJAVA_DIR)/java.ml \
	$(CAMLJAVA_TESTS_DIR)/test.ml
	ocamlfind ocamlopt -linkpkg -output-obj \
		-runtime-variant _pic \
		-ccopt "-shared" \
		-cclib "-Wl,--whole-archive $(JAVACAML_A) -Wl,--no-whole-archive" \
		-I $(CAMLJAVA_DIR) \
		$^ -o $@

test.jar: $(wildcard javacaml/test/*.java)
	javac -cp $(JAVACAML_JAR) $^
	jar cf $@ javacaml/test/*.class

libs:
	make -C $(JAVACAML_DIR)

clean:
	rm -f $(wildcard *.o *.cmo *.cmi *.cmx *.so *.jar javacaml/test/*.class)
	make -C $(JAVACAML_DIR) clean

re: clean
	make run

.PHONY: all run libs clean re
