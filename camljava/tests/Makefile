CAMLJAVA_DIR = ..

JAVA_LIBS_PATH = $(JAVA_HOME)/jre/lib/amd64/server
JAVA_INCLUDE_FLAGS = -I $(JAVA_HOME)/include -I $(JAVA_HOME)/include/linux
JAVA_LINK_FLAGS = $(addprefix -L,$(JAVA_LIBS_PATH))

run: all
	$(addprefix LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:,$(JAVA_LIBS_PATH)) \
	./a.out test.jar

all: a.out test.jar

a.out: $(wildcard $(CAMLJAVA_DIR)/*.ml $(CAMLJAVA_DIR)/*.c *.ml)
	ocamlopt \
		-ccopt "$(JAVA_INCLUDE_FLAGS)" \
		-ccopt "$(JAVA_LINK_FLAGS)" \
		-cclib "-ljvm" \
		-I $(CAMLJAVA_DIR) \
		$^ -o $@

test.jar: $(wildcard test/*.java)
	javac $^
	jar cf $@ test/*.class

clean:
	rm -f $(wildcard *.o *.cmi *.cmo *.cmx *.jar test/*.class)
	rm -f $(wildcard $(CAMLJAVA_DIR)/*.o $(CAMLJAVA_DIR)/*.cmi $(CAMLJAVA_DIR)/*.cmx)
	rm -f a.out test.jar

re: clean
	make run

.PHONY: run all clean re
