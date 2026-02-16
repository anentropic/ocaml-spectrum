(** Module type signatures for Spectrum library.

    This module contains shared type definitions used by both the implementation
    and interface files, following the "intf trick" pattern to eliminate duplication
    and provide a single source of truth for module signatures. *)

(** Printer module type - provides formatted printing with ANSI color codes. *)
module type Printer = sig
  (** Prepare a formatter to handle color tags. Returns a reset function to
      restore original formatter state. *)
  val prepare_ppf : Format.formatter -> unit -> unit

  (** Simple one-shot printing interface that handles formatter setup/teardown. *)
  module Simple : sig
    (** Equivalent to [Format.printf] with color tag support. *)
    val printf : ('a, Format.formatter, unit, unit) format4 -> 'a

    (** Equivalent to [Format.eprintf] with color tag support. *)
    val eprintf : ('a, Format.formatter, unit, unit) format4 -> 'a

    (** Equivalent to [Format.sprintf] with color tag support. *)
    val sprintf : ('a, Format.formatter, unit, string) format4 -> 'a
  end
end

(** Serializer module type - converts parsed tokens to ANSI escape codes. *)
module type Serializer = sig
  (** Convert a list of parsed style tokens into an ANSI escape code string. *)
  val to_code : Parser.token list -> string
end
