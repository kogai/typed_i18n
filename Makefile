NAME := typed_i18n
OCB := jbuilder
DIST := _build/default/src
SRC_FILES := $(shell find ./src -type f -name '*.ml')
SRC_FILES += package.json
SRC_DIRS := "src"
OPAM_VER := 4.03.0
ARGS := -i fixture/locale.json -o fixture -p ja -l flow -l typescript

.PHONY: js
js:
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
