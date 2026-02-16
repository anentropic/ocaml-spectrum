(** OCaml library for colorful terminal output with format tags.

    Spectrum provides ANSI color/style formatting integrated with OCaml's Format module,
    allowing styled output using semantic tags like [@{<bold;red>text@}]. *)

(** Terminal capability detection for color support. *)
module Capabilities : module type of Capabilities

(** Lexer for parsing color/style tags and ANSI escape sequences. *)
module Lexer : module type of Lexer

(** Parser for converting lexer output into structured tokens. *)
module Parser : module type of Parser

(** Printer module type - provides formatted printing with ANSI color codes.

    See {!Spectrum_intf.Printer} for the full signature. *)
module type Printer = Spectrum_intf.Printer

(** Serializer module type - converts parsed tokens to ANSI escape codes.

    See {!Spectrum_intf.Serializer} for the full signature. *)
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
end
