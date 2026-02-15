# AGENTS.md

When managing dependencies use an opam switch.

When completing a task that touched OCaml or Dune code, first do ``dune clean && dune test --force`. The use VSCode tools to "OCaml: Restart Language Server". The use `get_errors` tool to check for issues and then fix them.

Ignore errors in files under `_scratchpad` or `_notes`.

The `<pkg>.opam` files are auto-generated when running `dune build`, don't edit them.
