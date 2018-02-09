# -
# Required variables:
# 	BUILD_DIR
# 	TARGET_DIR

B = $(BUILD_DIR)
T = $(TARGET_DIR)

PACKAGES = -package ppx_tools.metaquot

OCAMLFIND = ocamlfind
OCAMLC = $(OCAMLFIND) ocamlc $(PACKAGES) -linkall

OCAMLCFLAGS = -I +compiler-libs ocamlcommon.cma

# -

CMO_FILES = $(B)/ppx.cmo

$(B)/ppx.cmo: ppx/ppx.ml | $(B)

clean::
	rm -f $(CMO_FILES)

$(T)/ocaml-java-ppx: $(CMO_FILES)
	$(OCAMLC) $(OCAMLCFLAGS) $^ -o $@

%.cmo:
	$(OCAMLC) $(OCAMLCFLAGS) -c $< -o $@

$(sort $(B) $(T)):
	mkdir -p $@

.PHONY: clean
