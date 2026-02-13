# AGENTS.md

When managing dependencies use an opam switch.

When completing a task, use `get_errors` tool to check for issues and then fix them. You may have to do a `dune clean && dune build` or even restart the OCaml LSP in some cases.

If you made any changes to the code then run tests with `dune test`.
