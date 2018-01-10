# -

JAVACAML_DIR = ..

JAVACAML_JAR = $(JAVACAML_DIR)/javacaml.jar
JAVACAML_A = $(JAVACAML_DIR)/libjavacaml.a

run: all
	LD_LIBRARY_PATH=. java -ea -cp test.jar:$(JAVACAML_JAR) test.Test

all: | libs
	make libtest.so test.jar

libtest.so: $(wildcard *.ml *.c)
	ocamlfind ocamlopt -linkpkg -output-obj \
		-runtime-variant _pic \
		-ccopt "-shared" \
		-cclib "-Wl,--whole-archive $(JAVACAML_A) -Wl,--no-whole-archive" \
		$^ -o $@

test.jar: $(wildcard test/*.java)
	javac -cp $(JAVACAML_JAR) $^
	jar cf $@ test/*.class

libs:
	make -C $(JAVACAML_DIR)

clean:
	rm -f $(wildcard *.o *.cmo *.cmi *.cmx *.so *.jar test/*.class)
	make -C $(JAVACAML_DIR) clean

re: clean
	make run

.PHONY: all run libs clean re
