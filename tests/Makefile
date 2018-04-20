test_javacaml.jar: $(wildcard ocamljava/test/*.java)
	javac -encoding UTF8 -cp "$(CLASS_PATH)" $^
	jar cf $@ ocamljava/test/*.class
