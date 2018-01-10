# -

CAMLJAVA_DIR = ..

run: all
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(JAVA_HOME)/jre/lib/amd64/server \
	./a.out test.jar

all: | libs
	make a.out test.jar

a.out: $(wildcard *.ml)
	ocamlopt \
		-I $(CAMLJAVA_DIR) camljava.cmxa \
		$^ -o $@

test.jar: $(wildcard test/*.java)
	javac $^
	jar cf $@ test/*.class

libs:
	make -C $(CAMLJAVA_DIR)

clean:
	make -C $(CAMLJAVA_DIR) clean
	rm -f $(wildcard *.o *.cmi *.cmo *.cmx *.jar test/*.class)
	rm -f a.out test.jar

re: clean
	make run

.PHONY: run all clean re
