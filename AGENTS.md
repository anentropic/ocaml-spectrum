# AGENTS.md

When managing dependencies use an opam switch.

When completing a task that touched OCaml or Dune code, first do `dune clean && dune test --force` (always run tests with the `--force` option). Use builtin tools to restart the OCaml language server. Then use builtin tools to check for issues in project files and fix them.

Ignore errors in files under `_scratchpad` or `_notes`.

After modifying Odoc docs under `docs/` (or in `.mli` files) do a `dune build @doc` and update source file mapping details in `docs/DEVELOP.md`.

The `<pkg>.opam` files are auto-generated when running `dune build`, don't edit them.
