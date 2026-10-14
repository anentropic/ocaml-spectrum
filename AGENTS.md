# AGENTS.md

When managing dependencies use an opam switch.

When completing a task that touched OCaml or Dune code, first do `dune clean && dune test --force` (always run tests with the `--force` option). Use builtin tools to restart the OCaml language server. Then use builtin tools to check for issues in project files and fix them.

Ignore errors in files under `_scratchpad` or `_notes`.

After modifying Odoc docs under `docs/` (or in `.mli` files) do a `dune build @doc` and update source file mapping details in `docs/DEVELOP.md`.

The `<pkg>.opam` files are auto-generated when running `dune build`, don't edit them.

## Opening pull requests

When you open a pull request, ask the user whether it needs a review. If they say yes:

1. Mark the PR ready for review, since the review bot skips drafts.
2. Request a review from `anentropic-reviewbot`. Claude then posts inline comments and a summary on the PR.
3. Watch the PR and address the review comments and any CI failures as they come in, until CI is green and no blocking comments are left open.

To get another review after pushing fixes, request one from `anentropic-reviewbot` again.
