# -

OCAMLOPT = ocamlfind ocamlopt

CCINCLUDES = -I "$(JAVA_HOME)/include" \
	-I "$(JAVA_HOME)/include/linux" \
	-I "$(OCAML_WHERE)"

CCFLAGS = -Wall -Wextra -O2 $(CCINCLUDES)

CCLIBS = -L $(JAVA_HOME)/jre/lib/amd64/server -ljvm

all: camljava.cmxa java.cmi

camljava.cmxa: java.cmx | libcamljava.a
	$(OCAMLOPT) -linkall -a -cclib "$(CCLIBS) -lcamljava" -o $@ $^

libcamljava.a: java_stubs.o
	ar rcs $@ $^

%.o: %.c
	$(OCAMLOPT) -c -ccopt "$(CCFLAGS)" -o $@ $<

%.cmi: %.mli
	$(OCAMLOPT) -c -o $@ $<

%.cmx: %.ml %.cmi
	$(OCAMLOPT) -c -o $@ $<

clean:
	rm -f $(wildcard *.a *.cmi *.o *.cmx *.cmxa)

re: clean
	make all

.PHONY: all clean re
