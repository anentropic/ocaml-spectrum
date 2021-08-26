(lang dune 2.8)
(name spectrum)
(version 0.1.0)

(generate_opam_files true)

(source (github anentropic/ocaml-spectrum))
(license MIT)
(authors "Anentropic")
(maintainers "ego@anentropic")

(package
 (name spectrum)
 (synopsis "Library for color and formatting in terminal")
 (description "Collection of color codes and names for 256 color terminal setups")
 (depends
  (dune (and (>= 2.8) (< 2.9)))
  (dune-build-info (and (>= 2.8) (< 2.9)))
  (color (and (>= 0.2) (< 0.3)))
 ))
