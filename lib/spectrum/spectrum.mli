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
    - Styles: [@{<bold>text@}], [@{<underline>text@}], [@{<italic>text@}], [@{<overline>text@}]
    - Qualifiers: [@{<bg:red>text@}], [@{<fg:blue>text@}]
    - Compound: [@{<bold,bg:red,yellow>text@}]

    {2 Interface}

    Spectrum provides two module variants:

    - {!Exn} raises exceptions on invalid color/style tags
    - {!Noexn} silently ignores invalid tags (default)

    The default top-level interface (just [Spectrum.xyz]) is equivalent
    to {!Noexn}. Both expose {!Printer}, which includes {!prepare_ppf}
    and the {!Printer.Simple} convenience module.

    Note: [Format.sprintf] uses its own buffer, so you must use
    {!Simple.sprintf} for styled sprintf, or create your own
    buffer with [Format.fprintf].

    {2 See Also}

    - {{:https://github.com/anentropic/ocaml-spectrum} GitHub repository}
    - {!Spectrum_tools} for color conversion utilities
    - {!Spectrum_palettes} for pre-generated palette modules *)

(** Terminal capability detection for color support. *)
module Capabilities : module type of Spectrum_capabilities.Capabilities

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

(** Type-safe semantic tags for programmatic use with
    {{:https://ocaml.org/api/Format.html}Format}.

    The {!Stag} module provides an alternative to string-based
    [@{<tag>...@}] syntax, allowing you to construct formatting tags
    as OCaml values. This gives you compile-time safety, avoids
    runtime string parsing, and makes it easy to compute styles
    dynamically.

    {2 Quick Start}

    Use with [Format.pp_open_stag] and [Format.pp_close_stag] on a
    formatter that has been prepared with {!prepare_ppf}:

    {[
      let reset = Spectrum.prepare_ppf Format.std_formatter in
      let open Spectrum.Stag in
      Format.pp_open_stag Format.std_formatter (stag [Bold; Fg (Named "red")]);
      Format.pp_print_string Format.std_formatter "hello";
      Format.pp_close_stag Format.std_formatter ();
      Format.pp_print_newline Format.std_formatter ();
      reset ()
    ]}

    {2 Specifying Colors}

    Colors can be specified in several ways:

    {[
      (* Named xterm-256 color *)
      stag [Fg (Named "dark-orange")]

        (* Hex digits (without '#') — 3 or 6 chars *)
        stag [Fg (Hex "ff5733")]
        stag [Fg (Hex "F00")]

        (* RGB components, each 0-255 *)
        stag [Fg (Rgb (255, 87, 51))]

        (* HSL: hue 0-360, saturation 0-100, lightness 0-100 *)
        stag [Fg (Hsl (14.3, 100., 60.))]
    ]}

    {2 Compound Tags}

    Combine multiple styles and colors in a single tag:

    {[
      (* Bold red text on a blue background *)
      stag [Bold; Fg (Rgb (255, 0, 0)); Bg (Named "blue")]

        (* Dim italic text *)
        stag [Dim; Italic; Fg (Named "gray")]
    ]}

    {2 Nested Tags}

    Tags nest naturally — inner tags add to the style stack and
    closing them restores the previous style:

    {[
      let ppf = Format.std_formatter in
      let reset = Spectrum.prepare_ppf ppf in
      let open Spectrum.Stag in
      Format.pp_open_stag ppf (stag [Fg (Named "green")]);
      Format.pp_print_string ppf "green ";
      Format.pp_open_stag ppf (stag [Bold]);
      Format.pp_print_string ppf "green+bold ";
      Format.pp_close_stag ppf ();
      Format.pp_print_string ppf "green again";
      Format.pp_close_stag ppf ();
      Format.pp_print_newline ppf ();
      reset ()
    ]}

    {2 Comparison with String Tags}

    Stag variants are especially useful when styles are computed at
    runtime, e.g. from configuration or user input:

    {[
      (* With string tags, you'd need to format a string: *)
      let tag_str = Printf.sprintf "rgb(%d %d %d)" r g b in
      Format.fprintf ppf "@{<%s>%s@}" tag_str text

        (* With Stag, values are passed directly: *)
        Format.pp_open_stag ppf (Spectrum.Stag.stag [Fg (Rgb (r, g, b))]);
      Format.pp_print_string ppf text;
      Format.pp_close_stag ppf ()
    ]}

    String-based tags and variant-based stags can be freely mixed on
    the same formatter — both are handled by {!prepare_ppf}. *)
module Stag : sig
  (** Color specification.

      Colors can be given as named xterm-256 palette entries, hex strings,
      RGB component triples, or HSL triples. *)
  type color =
    | Named of string
    (** A named color from the xterm-256 palette.
        Examples: ["red"], ["green"], ["dark-orange"], ["light-steel-blue"].
        Case-insensitive. *)
    | Hex of string
    (** Hex color digits {b without} the [#] prefix.
        Accepts 3-char shorthand or 6-char full form.
        Examples: ["F00"] (red), ["ff5733"], ["0CF"]. *)
    | Rgb of int * int * int
    (** RGB components, each in the range 0-255.
        Example: [Rgb (255, 87, 51)] for a warm orange. *)
    | Hsl of float * float * float
    (** HSL color: hue in degrees (0-360), saturation (0-100),
        lightness (0-100).
        Example: [Hsl (14.3, 100., 60.)] for a warm orange. *)

  (** A single style or color directive. *)
  type t =
    | Bold          (** Bold / increased intensity *)
    | Dim           (** Faint / decreased intensity *)
    | Italic        (** Italic text *)
    | Underline     (** Underlined text *)
    | Blink         (** Slow blink *)
    | RapidBlink    (** Rapid blink *)
    | Inverse       (** Swap foreground and background *)
    | Hidden        (** Hidden / conceal *)
    | Strikethru    (** Struck-through text *)
    | Overline      (** Overlined text *)
    | Fg of color   (** Set foreground color *)
    | Bg of color   (** Set background color *)

  (** Construct a [Format.stag] from a list of directives.

      The returned stag can be used with [Format.pp_open_stag] on a
      formatter prepared via {!Spectrum.prepare_ppf}.

      {[
        let tag = Spectrum.Stag.stag [Bold; Fg (Hex "00FF00")] in
        Format.pp_open_stag ppf tag;
        Format.pp_print_string ppf "styled";
        Format.pp_close_stag ppf ()
      ]}

      @raise Spectrum_palette_ppx.Palette.InvalidColorName
        if a {!Named} color is not in the xterm-256 or basic palette
      @raise Parser.InvalidHexColor
        if a {!Hex} string cannot be parsed as a hex color
      @raise Parser.InvalidRgbColor
        if {!Rgb} values are outside the 0-255 range
      @raise Parser.InvalidPercentage
        if {!Hsl} saturation or lightness are outside 0-100 *)
  val stag : t list -> Format.stag
end

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
