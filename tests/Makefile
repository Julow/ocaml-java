# -

OCAMLJAVA_DIR = ..

OCAMLJAVA_JAR = $(OCAMLJAVA_DIR)/bin/ocaml-java.jar

ML_FILES := test_caml.ml test_java.ml test_ppx.ml test.ml

run: camljava javacaml

camljava: test_camljava test_javacaml.jar
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(JAVA_HOME)/jre/lib/amd64/server \
	OCAMLRUNPARAM=b \
	./test_camljava

test_camljava: $(ML_FILES) | libs
	ocamlopt \
		-ppx $(OCAMLJAVA_DIR)/bin/ocaml-java-ppx \
		-I $(OCAMLJAVA_DIR)/bin/camljava camljava.cmxa \
		unix.cmxa -g -o $@ $^

javacaml: libtest_javacaml.so test_javacaml.jar
	CP=test_javacaml.jar:$(OCAMLJAVA_JAR); \
	LD_LIBRARY_PATH=. java -ea -cp "$$CP" ocamljava.test.TestJava

libtest_javacaml.so: $(ML_FILES) | libs
	ocamlfind ocamlopt -linkpkg -output-obj \
		-ppx $(OCAMLJAVA_DIR)/bin/ocaml-java-ppx \
		-runtime-variant _pic \
		-ccopt "-shared" \
		-I $(OCAMLJAVA_DIR)/bin/javacaml javacaml.cmxa \
		unix.cmxa -I . -g -o $@ $^

test_javacaml.jar: $(wildcard ocamljava/test/*.java)
	javac -encoding UTF8 -cp $(OCAMLJAVA_JAR) $^
	jar cf $@ ocamljava/test/*.class

libs:
	make -C $(OCAMLJAVA_DIR)

clean:
	rm -f $(wildcard *.o *.cmo *.cmi *.cmx ocamljava/test/*.class)
	rm -f test_camljava libtest_javacaml.so test_javacaml.jar
	make -C $(OCAMLJAVA_DIR) clean

re: clean
	make run

.PHONY: run camljava javacaml libs clean re
