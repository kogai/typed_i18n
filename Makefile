NAME := typed_i18n
TEST_NAME := $(NAME)_test
PKGS := core,yojson,cmdliner,easy-format,ppx_blob
SRC_FILES := $(shell find ./src -type f -name '*.ml')
SRC_FILES += package.json
SRC_DIRS := "src"

OCB_FLAGS := -use-ocamlfind -Is $(SRC_DIRS) -pkgs $(PKGS)
OCB := ocamlbuild $(OCB_FLAGS)
OPAM_VER := 4.03.0
ARGS := -i fixture/locale.json -o fixture -p ja
OS := $(shell uname -s)

all:$(NAME).native $(NAME).byte bin/$(NAME).$(OS)

$(NAME).native: $(SRC_FILES)
	eval `opam config env` && \
	$(OCB) -verbose 2 $(NAME).native

$(NAME).byte: $(SRC_FILES)
	eval `opam config env` && \
	$(OCB) $(NAME).byte

bin/$(NAME).$(OS): $(NAME).native
	mkdir -p bin
	cp _build/src/$(NAME).native bin/$(NAME).$(OS)

.PHONY: mk
mk:
	mkdir _foo
	ls -l

.PHONY: docker
docker:
	# docker run -ti $(NAME):latest . bash
	docker build -t $(NAME) .

.PHONY: native
native: $(NAME).native
	@./$(NAME).native $(ARGS)

.PHONY: byte
byte: $(NAME).byte
	@./$(NAME).byte $(ARGS)

.PHONY: run
run: native byte

$(TEST_NAME).native: $(SRC_FILES)
	$(OCB) $(TEST_NAME).native

$(TEST_NAME).byte: $(SRC_FILES)
	$(OCB) $(TEST_NAME).byte

.PHONY: test
test: test-native test-byte

.PHONY: test-native
test-native: $(TEST_NAME).native
	@./$(TEST_NAME).native

.PHONY: test-byte
test-byte: $(TEST_NAME).byte
	@./$(TEST_NAME).byte

.PHONY: test-ci
test-ci: install
	make test

.PHONY: publish
publish: clean
	npm version patch
	make
	git commit -a --amend --no-edit
	npm publish --access public

.PHONY: install
install:
	opam init -ya --comp=$(OPAM_VER) && \
	opam switch $(OPAM_VER) && \
	eval `opam config env` && \
	opam update && \
	opam install -y \
		ocamlfind \
		core \
		yojson \
		easy-format \
		cmdliner \
		ppx_blob

.PHONY: setup
setup: install
	opam user-setup install

.PHONY: clean
clean:
	$(OCB) -clean
