# -

OCAMLJAVA_DIR = ../..

JAVACAML_TESTS_DIR = ../../javacaml/tests

run: all
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(JAVA_HOME)/jre/lib/amd64/server \
	OCAMLRUNPARAM=b \
	./a.out

all: | libs
	make a.out test.jar

ML_FILES = $(JAVACAML_TESTS_DIR)/javacaml_test.ml $(wildcard *.ml)

a.out: $(ML_FILES) $(OCAMLJAVA_DIR)/bin/camljava.cmxa
	ocamlopt \
		-ppx $(OCAMLJAVA_DIR)/bin/ocaml-java-ppx \
		-I $(OCAMLJAVA_DIR)/bin camljava.cmxa \
		unix.cmxa \
		-g \
		$(ML_FILES) -o $@

test.jar: $(wildcard camljava/test/*.java)
	javac -cp $(OCAMLJAVA_DIR)/bin/ocaml-java.jar $^
	jar cf $@ camljava/test/*.class

libs:
	make -C $(OCAMLJAVA_DIR)

clean:
	make -C $(OCAMLJAVA_DIR) clean
	rm -f $(wildcard *.o *.cmi *.cmo *.cmx *.jar camljava/test/*.class)
	rm -f a.out test.jar

re: clean
	make run

.PHONY: run all libs clean re
