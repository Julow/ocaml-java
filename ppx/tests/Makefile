# -

OCAMLJAVA_DIR = ../..
OCAMLJAVA_TARGET_DIR = $(OCAMLJAVA_DIR)/bin

PPX = $(OCAMLJAVA_TARGET_DIR)/ocaml-java-ppx

run: libs
	for f in `ls inp/`; do \
		echo \# $$f; \
		ocamlfind ppx_tools/rewriter $(PPX) inp/$$f; \
	done > regr_out
	diff regr_ref regr_out > regr_diff

libs:
	make -C $(OCAMLJAVA_DIR)

clean:
	make -C $(OCAMLJAVA_DIR) clean
	rm -f $(wildcard *.o *.cmi *.cmo *.cmx)
	rm -f a.out

re: clean
	make run

.PHONY: run libs clean re
