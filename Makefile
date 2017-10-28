NAME := typed_i18n
TEST_NAME := $(NAME)_test
PKGS := core,yojson,cmdliner,easy-format,ppx_blob,textutils
SRC_FILES := $(shell find ./src -type f -name '*.ml')
SRC_FILES += package.json
SRC_DIRS := "src"

OCB_FLAGS := -use-ocamlfind -Is $(SRC_DIRS) -pkgs $(PKGS)
OCB := ocamlbuild $(OCB_FLAGS)
OPAM_VER := 4.03.0
ARGS := -i fixture/locale.json -o fixture -p ja -l flow -l typescript
OS := $(shell uname -s)

all:$(NAME).native $(NAME).byte bin/$(NAME).$(OS)

$(NAME).native: $(SRC_FILES)
	eval `opam config env` && \
	$(OCB) $(NAME).native

$(NAME).byte: $(SRC_FILES)
	eval `opam config env` && \
	$(OCB) $(NAME).byte

bin/$(NAME).$(OS): $(NAME).native
	mkdir -p bin
	cp _build/src/$(NAME).native bin/$(NAME).$(OS)

.PHONY: docker
docker:
	docker build -t $(NAME) . && \
	docker run -t $(NAME) && \
	docker cp $(shell docker ps -alq):/typed_i18n/bin/typed_i18n.Linux ./bin

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
test-ci:
	cd example && \
	yarn test

.PHONY: publish
publish: clean
	npm version patch && \
	make && \
	make docker && \
	git commit -a -m "bump binary" && \
	npm publish --access public && \
	git push

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
		textutils \
		ppx_blob

.PHONY: setup
setup: install
	opam user-setup install

.PHONY: clean
clean:
	$(OCB) -clean
