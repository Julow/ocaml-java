# -
# Required variables:
#  BUILD_DIR
#  TARGET_DIR
#  JAVA_INCLUDES

B = $(BUILD_DIR)
T = $(TARGET_DIR)

OCAMLFIND = ocamlfind
OCAMLOPT = $(OCAMLFIND) ocamlopt

CCINCLUDES = \
	$(JAVA_INCLUDES) \
	-I javacaml \
	-I camljava

CCFLAGS = -Wall -Wextra -O2 -fPIC $(CCINCLUDES) $(EXTRA_CCFLAGS)
OCAMLOPTFLAGS = -I $(B) -I $(T)

all: $(T)/camljava.cmxa $(T)/javacaml.cmxa

# -

CMX_FILES = $(T)/java.cmx $(T)/jarray.cmx $(T)/jclass.cmx $(T)/jthrowable.cmx

$(B)/java.o $(T)/java.cmx: camljava/java.ml $(T)/java.cmi | $(B) $(T)
$(T)/java.cmi: camljava/java.mli | $(T)

$(B)/jarray.o $(T)/jarray.cmx: camljava/jarray.ml $(T)/jarray.cmi $(T)/java.cmi | $(B) $(T)
$(T)/jarray.cmi: camljava/jarray.mli | $(T)

$(B)/jclass.o $(T)/jclass.cmx: camljava/jclass.ml $(T)/jclass.cmi $(T)/java.cmi | $(B) $(T)
$(T)/jclass.cmi: camljava/jclass.mli | $(T)

$(B)/jthrowable.o $(T)/jthrowable.cmx: camljava/jthrowable.ml $(T)/jthrowable.cmi $(T)/java.cmi | $(B) $(T)
$(T)/jthrowable.cmi: camljava/jthrowable.mli | $(T)

clean::
	rm -f $(B)/java.o $(T)/java.cmx $(T)/java.cmi
	rm -f $(B)/jarray.o $(T)/jarray.cmx $(T)/jarray.cmi
	rm -f $(B)/jclass.o $(T)/jclass.cmx $(T)/jclass.cmi
	rm -f $(B)/jthrowable.o $(T)/jthrowable.cmx $(T)/jthrowable.cmi

OBJ_FILES = $(B)/java_stubs.o $(B)/caml.o

$(B)/java_stubs.o: camljava/java_stubs.c | $(B)
$(B)/caml.o: javacaml/caml.c | $(B)

clean::
	rm -f $(B)/java_stubs.o $(B)/caml.o

$(T)/camljava.a $(T)/camljava.cmxa: $(T)/libcamljava.a
$(T)/javacaml.a $(T)/javacaml.cmxa: $(T)/libjavacaml.a

$(T)/camljava.cmxa: LINK = -lcamljava -ljvm
$(T)/javacaml.cmxa: LINK = -ljavacaml
#

$(T)/camljava.cmxa $(T)/javacaml.cmxa: $(CMX_FILES) | $(T)
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -linkall -a \
		-cclib "$(CCLIBS) $(LINK)" \
		-o $@ $(CMX_FILES)

$(T)/libcamljava.a $(T)/libjavacaml.a: $(OBJ_FILES) | $(T)
	ar rcs $@ $^

clean::
	rm -f $(T)/camljava.cmxa $(T)/javacaml.cmxa
	rm -f $(T)/camljava.a $(T)/javacaml.a
	rm -f $(T)/libcamljava.a $(T)/libjavacaml.a

# -

%.o:
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c -ccopt "$(CCFLAGS) -o $@" $<

%.cmi:
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c -o $@ $<

%.cmx:
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c -o $@ $<

# -

$(sort $(B) $(T)):
	mkdir -p $@

.PHONY: all clean
