# -

OCAMLOPT = ocamlfind ocamlopt

CCINCLUDES = -I $(JAVA_HOME)/include \
	-I $(JAVA_HOME)/include/linux

CCFLAGS = -Wall -Wextra -O2 $(CCINCLUDES)

CCLIBS = -L $(JAVA_HOME)/jre/lib/amd64/server -ljvm

OCAMLCFLAGS = -I $(T) -I $(B)

JAVACAML_DIR = ../javacaml

BUILD_DIR = bin
TARGET_DIR = bin
B = $(BUILD_DIR)
T = $(TARGET_DIR)
DIR_RULES = $(B) $(T)

all: $(T)/camljava.cmxa $(T)/java.cmi

CMX_FILES = $(B)/java.cmx

$(T)/camljava.cmxa: $(CMX_FILES) | $(T)/libcamljava.a
	$(OCAMLOPT) $(OCAMLCFLAGS) -linkall -a \
		-cclib "$(CCLIBS) -lcamljava" \
		-o $@ $^

$(B)/java.cmx: $(T)/java.cmi

OBJ_FILES = $(B)/java_stubs.o $(B)/javacaml/caml.o

$(T)/libcamljava.a: $(OBJ_FILES)
	ar rcs $@ $^

$(B)/javacaml/%.o: | $(B)/javacaml
	make -C $(JAVACAML_DIR) \
		BUILD_DIR="$${PWD}/$(@D)" \
		EXTRA_CCFLAGS="-DTARGET_CAMLJAVA=" \
		"$${PWD}/$@"

$(B)/javacaml: | $(B)
DIR_RULES += $(B)/javacaml

$(B)/%.o: %.c | $(B)
	$(OCAMLOPT) $(OCAMLCFLAGS) -c -ccopt "$(CCFLAGS) -o $@" $<

$(T)/%.cmi: %.mli | $(T)
	$(OCAMLOPT) $(OCAMLCFLAGS) -c -o $@ $<

$(B)/%.o $(B)/%.cmx: %.ml | $(B)
	$(OCAMLOPT) $(OCAMLCFLAGS) -c -o $@ $<

$(sort $(DIR_RULES)):
	mkdir -p $@

clean:
	rm -f $(OBJ_FILES) $(T)/libcamljava.a
	rm -f $(CMX_FILES) $(T)/camljava.cmxa $(T)/java.cmi

re: clean
	make all

.PHONY: all clean re
