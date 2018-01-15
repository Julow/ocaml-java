# -
# Required variables:
#  BUILD_DIR
#  TARGET_DIR

B = $(BUILD_DIR)
T = $(TARGET_DIR)

JAVA_FILES = $(wildcard javacaml/juloo/javacaml/*.java)
CLASS_FILES = $(patsubst javacaml/%.java,$(B)/%.class,$(JAVA_FILES))

ifneq ($(B),$(T))

$(T)/ocaml-java.jar: $(B)/ocaml-java.jar | $(T)
	cp $< $@

clean::
	rm -f $(T)/ocaml-java.jar

endif

$(B)/ocaml-java.jar: $(CLASS_FILES) | $(B)
	cd $(B); jar cf $(@F) $(subst $(B)/,,$^)

clean::
	rm -f $(B)/ocaml-java.jar
	rm -f $(CLASS_FILES)

$(B)/%.class: javacaml/%.java | $(B)
	javac -sourcepath javacaml -d $(B) $<

$(sort $(B) $(T)):
	mkdir -p $@

.PHONY: clean
