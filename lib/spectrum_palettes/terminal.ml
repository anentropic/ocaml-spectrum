(** Canonical terminal palette definitions for Spectrum.

    Provides the standard ANSI-16 (Basic) and ANSI-256 (Xterm256) color palettes
    used by terminal emulators. Palettes are generated from JSON definitions using
    the [%palette] PPX extension. *)

(** Reference to the Palette module providing the palette signature. *)
module Palette = Spectrum_palette_ppx.Palette

(** Exception raised when an invalid color name is used. *)
exception InvalidColorName = Spectrum_palette_ppx.Palette.InvalidColorName

(** ANSI-16 basic color palette (codes 30-37, 90-97).

    Standard 16-color palette with basic colors (black, red, green, yellow, blue,
    magenta, cyan, white) and their bright variants. Color names are prefixed with
    "basic-" to disambiguate from xterm-256 colors of the same name.

    See {{:https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit} ANSI 3-bit and 4-bit colors}

    Full color reference: {{!page-basic_palette} Basic Palette table} *)
module Basic : Palette.M = [%palette "lib/spectrum_palettes/16-colors.json"]

(** ANSI-256 extended color palette (codes 0-255).

    Extended 256-color palette including the 16 basic colors, a 216-color cube
    (6×6×6 RGB), and 24 grayscale shades.

    - Codes 0-15: Basic system colors (same as ANSI-16)
    - Codes 16-231: 6×6×6 RGB color cube with values [0, 95, 135, 175, 215, 255]
    - Codes 232-255: 24 grayscale shades from dark to light

    Color names follow the xterm convention with hyphenation:
    - Single names: [red], [green], [blue]
    - Compound names: [dark-orange], [light-blue], [medium-purple]
    - Duplicates with suffixes: [spring-green-3a], [spring-green-3b]

    See {{:https://www.ditig.com/256-colors-cheat-sheet} 256 colors cheat sheet}

    Full color reference: {{!page-xterm256_palette} Xterm256 Palette table} *)
module Xterm256 : Palette.M = [%palette "lib/spectrum_palettes/256-colors.json"]
