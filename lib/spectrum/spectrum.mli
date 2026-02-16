(** Colour and formatting for terminal output.

    Spectrum integrates ANSI color and style formatting with OCaml's
    {{:https://ocaml.org/api/Format.html#tags}Format semantic tags}.
    String tags are defined for ANSI styles (bold, underline, etc.) and
    named colours from the xterm 256-color palette, plus 24-bit colours
    via CSS-style hex codes and RGB or HSL values.

    Terminal capabilities are detected automatically and colours are
    quantized to match what the terminal supports, using perceptually
    accurate LAB color space distance calculations.

    {1 Basic Usage}

    {[
      (* Prepare a formatter to handle color tags *)
      let reset = Spectrum.prepare_ppf Format.std_formatter in
      let () = Format.printf "@{<green>Hello@} @{<bold>world@}@." in
      reset ()

      (* Or use the Simple API for one-off printing *)
      let () = Spectrum.Simple.printf "@{<green>Hello@} @{<bold>world@}@."
    ]}

    Tag syntax: [@{<TAG>content@}]

    - Named colors: [@{<green>text@}], [@{<dark-orange>text@}]
    - Hex colors: [@{<#ff5733>text@}], [@{<#f00>text@}]
    - RGB: [@{<rgb(255 87 51)>text@}]
    - HSL: [@{<hsl(60 100 50)>text@}]
    - Styles: [@{<bold>text@}], [@{<underline>text@}], [@{<italic>text@}]
    - Qualifiers: [@{<bg:red>text@}], [@{<fg:blue>text@}]
    - Compound: [@{<bold,bg:red,yellow>text@}]

    {2 Interface}

    Spectrum provides two module variants:

    - {!Exn} raises exceptions on invalid color/style tags
    - {!Noexn} silently ignores invalid tags (default)

    The default top-level interface (just [Spectrum.xyz]) is equivalent
    to {!Noexn}. Both expose {!Printer}, which includes [prepare_ppf]
    and the {!Printer.Simple} convenience module.

    Note: [Format.sprintf] uses its own buffer, so you must use
    [Spectrum.Simple.sprintf] for styled sprintf, or create your own
    buffer with [Format.fprintf].

    {2 See Also}

    - {{:https://github.com/anentropic/ocaml-spectrum} GitHub repository}
    - {!Spectrum_tools} for color conversion utilities
    - {!Spectrum_palettes} for pre-generated palette modules *)

(** Terminal capability detection for color support. *)
module Capabilities : module type of Capabilities

(** Lexer for parsing color/style tags and ANSI escape sequences. *)
module Lexer : module type of Lexer

(** Parser for converting lexer output into structured tokens. *)
module Parser : module type of Parser

(** Printer module type - provides formatted printing with ANSI color codes.

    See {!Printer} for the full signature. *)
module type Printer = Spectrum_intf.Printer

(** Serializer module type - converts parsed tokens to ANSI escape codes.

    See {!Serializer} for the full signature. *)
module type Serializer = Spectrum_intf.Serializer

(** Printer that raises exceptions on invalid color/style tags. *)
module Exn : Printer

(** Printer that silently ignores invalid color/style tags (default). *)
module Noexn : Printer

(** Default printer behavior (equivalent to Noexn).

    Includes all functions from {!Noexn} at the top level for convenient access. *)
include Printer

(** Internal modules exposed for testing purposes.

    {b Warning:} These modules are not part of the stable public API and may
    change without notice. They are exposed only for testing and should not be
    used in application code. *)
module Private : sig
  (** True color (24-bit RGB) serializer - preserves exact RGB values. *)
  module True_color_Serializer : Serializer

  (** ANSI-256 color serializer - quantizes RGB to xterm256 palette. *)
  module Xterm256_Serializer : Serializer

  (** ANSI-16 basic color serializer - quantizes to 16-color palette. *)
  module Basic_Serializer : Serializer

  (** Create a printer with a specific serializer, bypassing environment detection.
      [make_printer raise_errors to_code] creates a printer that uses [to_code]
      for serialization. If [raise_errors] is true, invalid tags raise exceptions. *)
  val make_printer : bool -> (Parser.token list -> string) -> (module Printer)
end
