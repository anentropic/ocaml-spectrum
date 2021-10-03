(lang dune 2.8)
(name spectrum)
(version 0.1.1)

(generate_opam_files true)

(source (github anentropic/ocaml-spectrum))
(license MIT)
(authors "Anentropic")
(maintainers "ego@anentropic.com")

(package
 (name spectrum)
 (synopsis "Library for colour and formatting in the terminal")
 (description "Using OCaml Format module's 'semantic tags' with named colours and CSS-style hex colours.")
 (depends
  (dune (and (>= 2.8) (< 2.9)))
  (color (and (>= 0.2) (< 0.3)))
  ; test deps
  (alcotest (and :with-test (>= 1.4) (< 1.5)))
  (junit_alcotest (and :with-test (>= 2.0) (< 2.1)))
  ; dev deps
  (utop :dev)
  (ocp-indent :dev)
  (ocaml-lsp-server :dev)
  (opam-format :dev)
  (opam-publish :dev)
  (dune-release :dev)
 ))
