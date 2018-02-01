# -
# Required variables:
#  JAVA_HOME
#
# Configs:
#  BUILD_DIR
#  TARGET_DIR
#  OCAMLFIND
#  JAVA_INCLUDES
#  JAVACFLAGS

BUILD_DIR = bin
TARGET_DIR = bin

T = $(TARGET_DIR)

all: $(T)/camljava.cmxa $(T)/javacaml.cmxa $(T)/ocaml-java.jar

export JAVA_INCLUDES = \
	-I $(JAVA_HOME)/include \
	-I $(JAVA_HOME)/include/linux

export CCLIBS = \
	-L $(JAVA_HOME)/jre/lib/amd64/server

MAKE_CAMLJAVA = make -f cmxa.Makefile \
		BUILD_DIR=$(BUILD_DIR)/camljava \
		TARGET_DIR=$(TARGET_DIR) \
		EXTRA_CCFLAGS="-DTARGET_CAMLJAVA"

MAKE_JAVACAML = make -f cmxa.Makefile \
		BUILD_DIR=$(BUILD_DIR)/javacaml \
		TARGET_DIR=$(TARGET_DIR) \
		EXTRA_CCFLAGS="-DTARGET_JAVACAML -fPIC"

$(T)/camljava.cmxa:
	$(MAKE_CAMLJAVA) $@

$(T)/javacaml.cmxa:
	$(MAKE_JAVACAML) $@

MAKE_JAR = make -f jar.Makefile \
		BUILD_DIR=$(BUILD_DIR) \
		TARGET_DIR=$(TARGET_DIR) \

$(T)/ocaml-java.jar:
	$(MAKE_JAR) $@

container:
	docker build -t ocaml-java - < Dockerfile
	docker run -it --rm -v"`pwd`:/app" ocaml-java bash

clean:
	$(MAKE_CAMLJAVA) clean
	$(MAKE_JAVACAML) clean
	$(MAKE_JAR) clean

re: clean
	make all

.PHONY: all container clean re
.PHONY: $(T)/camljava.cmxa $(T)/javacaml.cmxa $(T)/ocaml-java.jar
