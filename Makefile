.PHONY: setup, publish, tag, version

setup:
	opam install utop ocp-indent ocaml-lsp-server opam-format opam-publish

VERSION = $$(opam info -f version --color=never .)

version:
	@echo ${VERSION}

publish: tag
	opam-publish

tag:
	git tag ${VERSION}
	git push --tags
