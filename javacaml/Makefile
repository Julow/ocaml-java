# -

OCAML_WHERE := $(shell ocamlc -where)
CCINCLUDES = -I "$(JAVA_HOME)/include" \
	-I "$(JAVA_HOME)/include/linux" \
	-I "$(OCAML_WHERE)"
CCFLAGS = -Wall -Wextra -O2 -fPIC $(CCINCLUDES)

JAVAC = javac

all: libjavacaml.a javacaml.jar

# javacaml.jar

JAVA_FILES = $(wildcard juloo/javacaml/*.java)
CLASS_FILES = $(JAVA_FILES:.java=.class)

javacaml.jar: $(CLASS_FILES)
	jar cf $@ juloo/javacaml/*.class

$(CLASS_FILES): $(JAVA_FILES)
	$(JAVAC) $^

# libjavacaml.a

OBJ_FILES = caml.o

libjavacaml.a: $(OBJ_FILES)
	ar rcs $@ $^

%.o: %.c
	$(CC) $(CCFLAGS) -c -o $@ $<

clean:
	CLEAN='$(wildcard *.o *.a *.jar juloo/javacaml/*.class)'; \
	rm -f $$CLEAN

re: clean
	make all

.PHONY: all clean re
