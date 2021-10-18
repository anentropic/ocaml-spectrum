.PHONY: publish, tag

publish:
	make tag
	opam-publish

tag:
	git tag $$(opam info -f version --color=never .)
	git push --tags
