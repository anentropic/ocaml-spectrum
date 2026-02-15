(*
  Canonical terminal palette definitions for Spectrum.

  These modules are generated from JSON using the `[%palette ...]` extension
  provided by the `spectrum_palette.ppx` rewriter.
*)
module Palette = Spectrum_palette_ppx.Palette

exception InvalidColorName = Spectrum_palette_ppx.Palette.InvalidColorName

(*
  see: https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
  the non-bright color names have been prefixed with "basic-" to
  disambiguate from xterm-256 colors of the same name
*)
module Basic : Palette.M = [%palette "lib/spectrum/16-colors.json"]

(*
  see: https://www.ditig.com/256-colors-cheat-sheet
  duplicate names have been disambiguated via suffix like -1, -2, -3a, -3b
*)
module Xterm256 : Palette.M = [%palette "lib/spectrum/256-colors.json"]
