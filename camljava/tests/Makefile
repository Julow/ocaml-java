# -

CAMLJAVA_DIR = ..
JAVACAML_DIR = ../../javacaml
JAVACAML_TESTS_DIR = ../../javacaml/tests

run: all
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(JAVA_HOME)/jre/lib/amd64/server \
	./a.out

all: | camljava javacaml
	make a.out test.jar

a.out: $(JAVACAML_TESTS_DIR)/javacaml_test.ml $(wildcard *.ml)
	ocamlopt \
		-I $(CAMLJAVA_DIR)/bin camljava.cmxa \
		$^ -o $@

test.jar: $(wildcard camljava/test/*.java)
	javac -cp $(JAVACAML_DIR)/bin/javacaml.jar $^
	jar cf $@ camljava/test/*.class

camljava:
	make -C $(CAMLJAVA_DIR)

javacaml:
	make -C $(JAVACAML_DIR)

clean:
	make -C $(CAMLJAVA_DIR) clean
	make -C $(JAVACAML_DIR) clean
	rm -f $(wildcard *.o *.cmi *.cmo *.cmx *.jar camljava/test/*.class)
	rm -f a.out test.jar

re: clean
	make run

.PHONY: run all camljava javacaml clean re
