(** Terminal color capability detection.

    Detects terminal color support using environment variables and system
    information. Supports detection for various terminals, CI systems, and
    operating systems. *)

(** Color support level of a terminal. *)
type color_level =
  | Unsupported  (** No color support (or FORCE_COLOR=0). Colors quantized to Basic. *)
  | Basic        (** 16 colors via ANSI codes 30-37, 90-97 (or FORCE_COLOR=1). *)
  | Eight_bit    (** 256 colors from xterm palette (or FORCE_COLOR=2). *)
  | True_color   (** 24-bit RGB true color support (or FORCE_COLOR=3). *)
[@@deriving show, eq]

(** Color level information for stdout and stderr streams. *)
type color_level_info = {
  stdout : color_level;  (** Color support level for stdout *)
  stderr : color_level;  (** Color support level for stderr *)
}

(** Detect color support level for a file descriptor.

    Checks environment variables (FORCE_COLOR, COLORTERM, TERM, CI variables)
    and system information to determine terminal capabilities. Uses heuristics
    adapted from the Chalk JavaScript library.

    {[
      (* Check if stdout supports colors *)
      let is_tty = Unix.isatty Unix.stdout in
      let level = Spectrum.Capabilities.supported_color_level is_tty in
      match level with
      | True_color -> Printf.printf "24-bit RGB supported\n"
      | Eight_bit -> Printf.printf "256 colors supported\n"
      | Basic -> Printf.printf "16 colors supported\n"
      | Unsupported -> Printf.printf "No color support\n"
    ]}

    {[
      (* Check a specific file descriptor *)
      let fd = Unix.openfile "/dev/tty" [Unix.O_RDWR] 0o666 in
      let is_tty = Unix.isatty fd in
      let level = Spectrum.Capabilities.supported_color_level is_tty in
      Unix.close fd
    ]}

    @param is_tty Whether the file descriptor is a TTY
    @return Detected color support level *)
val supported_color_level : bool -> color_level

(** Detect color support for stdout and stderr.

    Convenience function that checks [Unix.isatty] for both stdout and stderr
    and returns their respective color support levels.

    {[
      let info = Spectrum.Capabilities.supported_color_levels () in
      match info.stdout with
      | True_color -> print_endline "24-bit color supported"
      | Eight_bit -> print_endline "256 colors supported"
      | Basic -> print_endline "16 colors supported"
      | Unsupported -> print_endline "No color support"
    ]}

    Override detection using the [FORCE_COLOR] environment variable:
    - [FORCE_COLOR=0] or [FORCE_COLOR=false]: Force Unsupported/Basic
    - [FORCE_COLOR=1] or [FORCE_COLOR=true]: Force Basic (16 colors)
    - [FORCE_COLOR=2]: Force Eight_bit (256 colors)
    - [FORCE_COLOR=3]: Force True_color (24-bit RGB)

    @return Color level info for stdout and stderr *)
val supported_color_levels : unit -> color_level_info

(** {1 Testing Utilities}

    The following types and functions are exposed for testing purposes.
    They allow mocking environment variables and OS information in tests. *)

(** String map type for building fake environments. *)
module StrMap : Map.S with type key = string

(** Environment provider interface for dependency injection. *)
module type EnvProvider = sig
  val getenv_opt : string -> string option
  val getenv : string -> string
end

(** OS information provider interface for dependency injection. *)
module type OsInfoProvider = sig
  val is_windows : unit -> bool
  val os_version : unit -> string option
end

(** Capability detection functor parameterized by environment and OS providers. *)
module type CapabilitiesProvider = sig
  val supported_color_level : bool -> color_level
end

(** Create capabilities module with custom providers. *)
module Make : functor (Env : EnvProvider) (OsInfo : OsInfoProvider) -> CapabilitiesProvider

(** Create an environment provider from a string map (for testing).

    {[
      let env_map = Spectrum.Capabilities.StrMap.(
          empty
          |> add "FORCE_COLOR" "3"
          |> add "TERM" "xterm-256color"
        ) in
      let module Env = (val Spectrum.Capabilities.env_provider_of_map env_map) in
      (* Use Env in tests *)
    ]} *)
val env_provider_of_map : string StrMap.t -> (module EnvProvider)

(** Create an OS info provider with fixed values (for testing).

    {[
      let module OsInfo = (val Spectrum.Capabilities.os_info_provider false (Some "10.0.19041")) in
      (* Use OsInfo in tests *)
    ]} *)
val os_info_provider : bool -> string option -> (module OsInfoProvider)
