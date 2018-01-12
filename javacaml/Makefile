# -

OCAML_WHERE := $(shell ocamlc -where)
CCINCLUDES = -I "$(JAVA_HOME)/include" \
	-I "$(JAVA_HOME)/include/linux" \
	-I "$(OCAML_WHERE)"
CCFLAGS = -Wall -Wextra -O2 -fPIC $(CCINCLUDES) $(EXTRA_CCFLAGS)

BUILD_DIR = bin
TARGET_DIR = bin
B = $(BUILD_DIR)
T = $(TARGET_DIR)
DIR_RULES = $(B) $(T)

all: $(T)/libjavacaml.a $(T)/javacaml.jar

# javacaml.jar

JAVA_FILES = $(wildcard juloo/javacaml/*.java)
CLASS_FILES = $(patsubst %.java,$(B)/%.class,$(JAVA_FILES))

ifneq ($(B),$(T))

$(T)/javacaml.jar: $(B)/javacaml.jar | $(T)
	cp $< $@

endif

$(B)/javacaml.jar: $(CLASS_FILES) | $(B)
	cd $(B); jar cf $(@F) $(subst $(B)/,,$^)

$(B)/%.class: %.java | $(B)
	javac -d $(B) $<

# libjavacaml.a

OBJ_FILES = $(B)/caml.o

$(T)/libjavacaml.a: $(OBJ_FILES) | $(T)
	ar rcs $@ $^

$(B)/%.o: %.c | $(B)
	gcc $(CCFLAGS) -c -o $@ $<

#

$(sort $(DIR_RULES)):
	mkdir -p $@

clean:
	rm -f $(OBJ_FILES) $(T)/libjavacaml.a
	rm -f $(CLASS_FILES) $(T)/javacaml.jar

re: clean
	make all

.PHONY: all clean re
