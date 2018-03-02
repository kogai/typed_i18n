NAME := typed_i18n
OCB := jbuilder
DIST := _build/default/src
SRC_FILES := $(shell find ./src -type f -name '*.ml')
SRC_FILES += package.json
SRC_DIRS := "src"
OPAM_VER := 4.03.0
ARGS := -i fixture/locale.json -o fixture -p ja -l flow -l typescript

all:$(NAME).native $(NAME).js

$(NAME).native: $(SRC_FILES)
	$(OCB) build src/typed_i18n.exe

$(NAME).js: $(SRC_FILES)
	$(OCB) build src/typed_i18n.bc.js
	mv _build/default/src/typed_i18n.bc.js typed_i18n.bc.js
	chmod 777 typed_i18n.bc.js

.PHONY: native
native: $(NAME).native
	@./$(DIST)/$(NAME).exe $(ARGS)

.PHONY: js
js: $(NAME).js
	node ./index.js $(ARGS)

.PHONY: test
test:
	cd example && \
	yarn test

publish: $(NAME).js
	npm version patch
	git commit -a -m "bump bin"
	git push
	npm publish --access public

.PHONY: install
install:
	opam init -ya --comp=$(OPAM_VER) && \
	opam switch $(OPAM_VER) && \
	eval `opam config env` && \
	opam update && \
	opam install -y \
		yojson \
		easy-format \
		cmdliner \
		ppx_blob \
		js_of_ocaml \
		js_of_ocaml-lwt
	opam user-setup install

.PHONY: clean
clean:
	$(OCB) clean
