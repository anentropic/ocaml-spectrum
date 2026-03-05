(** PPX extension for generating color palettes from JSON.

    This library provides:
    - A PPX extension [%palette "path/to/palette.json"] that generates palette modules
    - Runtime types and utilities for working with generated palettes

    The PPX extension reads JSON palette definitions and generates OCaml modules
    implementing the {!Palette.M} signature with efficient nearest-color lookup
    using octree-based spatial indexing in LAB color space.

    {2 Example Usage}

    {[
      (* Define a palette from JSON *)
      module MyPalette : Palette.M = [%palette "colors.json"]

      (* Use the generated palette *)
      let red = MyPalette.of_string "red"
      let code = MyPalette.to_code red
      let nearest = MyPalette.nearest (Gg.Color.v 0.5 0.3 0.7 1.0)
    ]} *)

(** Palette module type and runtime utilities. *)
module Palette = Palette

(* PPX implementation modules (expander, loader, utils) are intentionally
   NOT re-exported - they remain private internal modules. The PPX extension
   point is automatically registered by ppxlib. *)

(** Internal modules exposed for testing purposes.

    {b Warning:} These modules are not part of the stable public API and may
    change without notice. They are exposed only for testing and should not be
    used in application code. *)
module Private = struct
  module Loader = Loader
  module Expander = Expander
  module Utils = Utils
end
