# -
# Required variables:
# 	BUILD_DIR
# 	TARGET_DIR

B = $(BUILD_DIR)
T = $(TARGET_DIR)

PACKAGES = -package ppx_tools.metaquot

OCAMLFIND = ocamlfind
OCAMLC = $(OCAMLFIND) ocamlc $(PACKAGES) -linkall

OCAMLCFLAGS = -I +compiler-libs ocamlcommon.cma -I $(B)

all: $(T)/ocaml-java-ppx

CMO_FILES = \
	$(B)/ast_tools.cmo \
	$(B)/type_info.cmo \
	$(B)/gen.cmo \
	$(B)/unwrap.cmo \
	$(B)/mapper.cmo

$(T)/ocaml-java-ppx: $(CMO_FILES)
	$(OCAMLC) $(OCAMLCFLAGS) $^ -o $@

$(B)/%.cmo: ppx/%.ml | $(B)
	$(OCAMLC) $(OCAMLCFLAGS) -c $< -o $@

clean::
	rm -f $(CMO_FILES)

$(sort $(B) $(T)):
	mkdir -p $@

.PHONY: all clean
