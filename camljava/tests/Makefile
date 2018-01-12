# -

CAMLJAVA_DIR = ..
JAVACAML_DIR = ../../javacaml
JAVACAML_TESTS_DIR = ../../javacaml/tests

run: all
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(JAVA_HOME)/jre/lib/amd64/server \
	./a.out

all: | camljava javacaml javacaml_tests
	make a.out test.jar

a.out: $(wildcard *.ml)
	ocamlopt -g \
		-I $(CAMLJAVA_DIR)/bin camljava.cmxa \
		$(JAVACAML_TESTS_DIR)/javacaml_test.ml \
		$^ -o $@

test.jar: $(wildcard camljava/test/*.java)
	javac -cp $(JAVACAML_DIR)/bin/javacaml.jar $^
	jar cf $@ camljava/test/*.class

camljava:
	make -C $(CAMLJAVA_DIR)

javacaml:
	make -C $(JAVACAML_DIR)

javacaml_tests:
	make -C $(JAVACAML_TESTS_DIR) all

clean:
	make -C $(CAMLJAVA_DIR) clean
	make -C $(JAVACAML_DIR) clean
	make -C $(JAVACAML_TESTS_DIR) clean
	rm -f $(wildcard *.o *.cmi *.cmo *.cmx *.jar test/*.class)
	rm -f a.out test.jar

re: clean
	make run

.PHONY: run all camljava javacaml javacaml_tests clean re
