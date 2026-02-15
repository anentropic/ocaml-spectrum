# AGENTS.md

When managing dependencies use an opam switch.

When completing a task, use `get_errors` tool to check for issues and then fix them. You may have to do a `dune clean && dune build` or even restart the OCaml LSP in some cases.

Ignore errors in files under `_scratchpad` or `_notes`.

If you made any changes to the OCaml or Dune code then run tests with `dune test`. Not needed for other file types.

The `<pkg>.opam` files are auto-generated when running `dune build`, don't edit them.
