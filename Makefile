NAME := typed_i18n
TEST_NAME := $(NAME)_test
PKGS := ounit,core,ppx_deriving.show,yojson,cmdliner,easy-format,js_of_ocaml
SRC_FILES := $(shell find ./src -type f -name '*.ml')
SRC_DIRS := "src"

OCB_FLAGS := -use-ocamlfind -Is $(SRC_DIRS) -pkgs $(PKGS) -lib str
OCB := ocamlbuild $(OCB_FLAGS)
OPAM_VER := 4.03.0

all:$(NAME).native $(NAME).byte $(NAME).js

$(NAME).native: $(SRC_FILES)
	$(OCB) $(NAME).native

$(NAME).byte: $(SRC_FILES)
	$(OCB) $(NAME).byte

$(NAME).js: $(NAME).byte
	js_of_ocaml $(NAME).byte

.PHONY: native
native: $(NAME).native
	@./$(NAME).native $(ARGS)

.PHONY: byte
byte: $(NAME).byte
	@./$(NAME).byte $(ARGS)

# Execute like `make ARGS=subcommand run` equivalent as `main.(native|byte) subcommand`
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

.PHONY: init
init:
	opam init -ya --comp=$(OPAM_VER)
	opam switch $(OPAM_VER)
	eval `opam config env`

.PHONY: install
install: init
	opam update
	opam install -y \
		ocamlfind \
		merlin \
		core \
		yojson \
		js_of_ocaml \
		ppx_deriving \
		easy-format \
		cmdliner \
		ounit

.PHONY: setup
setup: install
	opam user-setup install

.PHONY: clean
clean:
	$(OCB) -clean
	@cd flow/src/parser \
	make clean
