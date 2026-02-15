(lang dune 2.8)
(name spectrum)
(version 0.7.0)

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
  (ocaml (>= 4.14))
  (color (>= 0.3.0))
  (re (>= 1.11.0))
  (opam-state (>= 2.5.0))
  (ppx_deriving (>= 5.2))
  (spectrum_tools (= :version))
  (spectrum_palette (= :version))

  ; test deps
  (alcotest (and :with-test (>= 1.4)))
  (junit_alcotest (and :with-test (>= 2.0)))

  ; dev deps
  ; opam install . --deps-only --with-dev-setup
  (ocamlformat :with-dev-setup)
  (ocp-indent :with-dev-setup)
  (opam-publish :with-dev-setup)
  (ocaml-lsp-server :with-dev-setup)
  (utop :with-dev-setup)

  ; docs deps
  (odoc :with-doc)
 ))

(package
 (name spectrum_tools)
 (synopsis "Color conversion and terminal color utilities for Spectrum")
 (description "Utilities for RGB/HSL conversion, ANSI quantization, and terminal color mapping used by Spectrum.")
 (depends
  (ocaml (>= 4.14))
  (color (>= 0.3.0))
  (gg (>= 1.0.0))
  (re (>= 1.11.0))
  (ppx_deriving (>= 5.2))
  (spectrum_palette (= :version))
  ; test deps
  (alcotest (and :with-test (>= 1.4)))
  (junit_alcotest (and :with-test (>= 2.0)))
 ))

(package
 (name spectrum_palette)
 (synopsis "PPX rewriter for generating color palette modules from JSON")
 (description "Provides the [%palette] PPX extension used to generate strongly-typed OCaml palette modules from JSON color definitions.")
 (depends
  (ocaml (>= 4.14))
  (color (>= 0.3.0))
  (re (>= 1.11.0))
  (ppxlib (>= 0.22.0))
  (yojson (>= 1.7))
 ))
