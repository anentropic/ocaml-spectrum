.PHONY: setup, release-check, dry-run-release, publish, tag, version

setup:
	opam install . --deps-only --with-test --with-dev-setup -y

VERSION = $$(opam info -f version --color=never .)

version:
	@echo ${VERSION}

dry-run-release:
	@echo "Release dry run (no changes made):"
	@echo "  VERSION=${VERSION}"
	@echo "  make release-check"
	@echo "  git ls-remote --exit-code --tags --refs origin refs/tags/${VERSION}"
	@echo "  git rev-parse -q --verify refs/tags/${VERSION}"
	@echo "  git tag ${VERSION}"
	@echo "  git push origin ${VERSION}"
	@echo "  opam-publish"

publish: release-check tag
	opam-publish

release-check:
	@echo "Checking git working tree is clean..."
	@git diff --quiet && git diff --cached --quiet || (echo "Working tree is not clean" && exit 1)
	@echo "Running test suite..."
	dune test

tag:
	@if git remote get-url origin >/dev/null 2>&1; then \
		if git ls-remote --exit-code --tags --refs origin "refs/tags/${VERSION}" >/dev/null; then \
			echo "Tag ${VERSION} already exists on origin; bump version before publishing"; \
			exit 1; \
		fi; \
	else \
		echo "Remote 'origin' not configured; skipping remote tag check"; \
	fi
	@if git rev-parse -q --verify "refs/tags/${VERSION}" >/dev/null; then \
		echo "Tag ${VERSION} already exists; delete or bump version before publishing"; \
		exit 1; \
	fi
	git tag ${VERSION}
	git push origin ${VERSION}
