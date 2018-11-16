BUILD_DIR = bin

JAVAC = javac

JAVA_FILES = $(wildcard juloo/javacaml/*.java)
CLASS_FILES_REL = $(JAVA_FILES:%.java=%.class)
CLASS_FILES = $(addprefix $(BUILD_DIR)/,$(CLASS_FILES_REL))

all: $(BUILD_DIR)/ocaml-java.jar

$(BUILD_DIR)/ocaml-java.jar: $(CLASS_FILES) | $(BUILD_DIR)
	cd $(@D); jar cf $(@F) $(CLASS_FILES_REL)

$(BUILD_DIR)/%.class: %.java | $(BUILD_DIR)
	$(JAVAC) -source 1.7 -target 1.7 -sourcepath . -d $(BUILD_DIR) $<

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -f $(BUILD_DIR)/ocaml-java.jar
	rm -f $(CLASS_FILES)

.PHONY: all clean
