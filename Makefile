NAME := typed_i18n
EXT := bs.js
OCB := jbuilder
DIST := _build/default/src
SRC_FILES := $(shell find ./src -type f -name '*.re')
SRC_FILES += package.json
SRC_DIRS := "src"
OPAM_VER := 4.03.0
ARGS := -i fixture/locale.json -o fixture -p ja -l flow -l typescript
NPM_BIN := $(shell npm bin)

src/$(NAME).$(EXT): $(SRC_FILES)
	$(NPM_BIN)/bsb -make-world

lib/bundle.$(EXT): src/$(NAME).$(EXT)
	$(NPM_BIN)/webpack src/$(NAME).$(EXT) -p -o lib/bundle.$(EXT) --target=node

.PHONY: run
run:
	yarn start -- $(ARGS)

.PHONY: test
test:
	cd example && \
	yarn test

.PHONY: publish
publish:
	npm version patch
	make $(NAME).js
	git commit -a -m "bump bin"
	git push
	npm publish --access public
