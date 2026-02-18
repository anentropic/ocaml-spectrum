(** OCaml library for color conversion and terminal querying.

    Provides utilities for converting RGB colors to ANSI color codes
    using perceptual matching in LAB color space, and functions to
    query xterm-compatible terminals for their current colors. *)

(** Color conversion functions for terminal colors.

    Provides utilities for converting RGB colors to ANSI color codes
    using perceptual matching in LAB color space. *)
module Convert = Convert

(** Terminal query functions for detecting current colors.

    Provides functions to query xterm-compatible terminals for their
    current foreground and background colors. *)
module Query = Query

(** Internal modules exposed for testing purposes.

    {b Warning:} These modules are not part of the stable public API and may
    change without notice. They are exposed only for testing and should not be
    used in application code. *)
module Private = struct
  module Utils = Utils
end
