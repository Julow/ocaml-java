# -

BUILD_DIR = bin
TARGET_DIR = .
T = $(TARGET_DIR)

all: camljava javacaml

MAKE_CAMLJAVA = make -C camljava \
	BUILD_DIR=../$(BUILD_DIR)/camljava \
	TARGET_DIR=../$(T)

MAKE_JAVACAML = make -C javacaml \
	BUILD_DIR=../$(BUILD_DIR)/javacaml \
	TARGET_DIR=../$(T)

camljava:
	$(MAKE_CAMLJAVA) all

javacaml:
	$(MAKE_JAVACAML) all

clean:
	$(MAKE_CAMLJAVA) clean
	$(MAKE_JAVACAML) clean

re: clean
	make all

container:
	docker build -t ocaml-java - < Dockerfile
	docker run -it --rm -v"`pwd`:/app" ocaml-java bash

.PHONY: all camljava javacaml clean re container
