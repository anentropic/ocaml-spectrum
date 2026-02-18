(** Module type signatures for Spectrum library.

    This module contains shared type definitions used by both the implementation
    and interface files, following the "intf trick" pattern to eliminate duplication
    and provide a single source of truth for module signatures. *)

(** Printer module type - provides formatted printing with ANSI color codes. *)
module type Printer = sig
  (** Prepare a formatter to handle color tags. Returns a reset function to
      restore original formatter state.

      This enables Spectrum's tag processing on a Format.formatter, allowing
      you to use [@{<tag>content@}] syntax in your format strings. The returned
      function restores the formatter to its original state.

      {[
        (* Basic usage with stdout *)
        let reset = Spectrum.prepare_ppf Format.std_formatter in
        Format.printf "@{<green>Success:@} Operation completed@.";
        Format.printf "@{<bold>%d@} items processed@." 42;
        reset ()
      ]}

      {[
        (* Using with a custom formatter *)
        let buffer = Buffer.create 256 in
        let fmt = Format.formatter_of_buffer buffer in
        let reset = Spectrum.prepare_ppf fmt in
        Format.fprintf fmt "@{<red>Error:@} Something went wrong@.";
        Format.pp_print_flush fmt ();
        reset ();
        let result = Buffer.contents buffer in
        Printf.printf "Captured: %s\n" result
      ]}

      {[
        (* Multiple formatters simultaneously *)
        let reset_out = Spectrum.prepare_ppf Format.std_formatter in
        let reset_err = Spectrum.prepare_ppf Format.err_formatter in
        Format.printf "@{<green>Info:@} Starting process@.";
        Format.eprintf "@{<yellow>Warning:@} Low memory@.";
        reset_out ();
        reset_err ()
      ]}

      @return Function to restore the formatter's original state *)
  val prepare_ppf : Format.formatter -> unit -> unit

  (** Simple one-shot printing interface that handles formatter setup/teardown.

      These functions automatically prepare and reset the formatter for each call,
      making them convenient for one-off printing. For repeated printing to the
      same formatter, use {!prepare_ppf} directly for better performance. *)
  module Simple : sig
    (** Equivalent to [Format.printf] with color tag support.

        Automatically prepares stdout formatter, prints with color tags, and
        resets the formatter after printing.

        {[
          (* Basic colored output *)
          Spectrum.Simple.printf "@{<green>Hello@} @{<bold>world@}!@."
        ]}

        {[
          (* Multiple colors and styles *)
          Spectrum.Simple.printf
            "@{<bg:blue,white,bold> INFO @} %s@."
            "Server started"
        ]}

        {[
          (* Format string with values *)
          let count = 42 in
          let status = "ready" in
          Spectrum.Simple.printf
            "@{<cyan>Status:@} %s, @{<yellow>Count:@} %d@."
            status count
        ]}

        {[
          (* Nested tags *)
          Spectrum.Simple.printf
            "@{<green>Success: @{<bold>%d@} items processed@}@."
            100
        ]} *)
    val printf : ('a, Format.formatter, unit, unit) format4 -> 'a

    (** Equivalent to [Format.eprintf] with color tag support.

        Prints to stderr with automatic formatter setup/teardown.

        {[
          (* Error message *)
          Spectrum.Simple.eprintf "@{<red>Error:@} File not found@."
        ]}

        {[
          (* Warning message *)
          Spectrum.Simple.eprintf
            "@{<yellow>Warning:@} @{<italic>%s@} is deprecated@."
            "old_function"
        ]}

        {[
          (* Debug output *)
          Spectrum.Simple.eprintf
            "@{<dim>Debug:@} Value = @{<cyan>%d@}@."
            42
        ]} *)
    val eprintf : ('a, Format.formatter, unit, unit) format4 -> 'a

    (** Equivalent to [Format.sprintf] with color tag support.

        Returns a formatted string with ANSI color codes. The returned string
        can be printed later or used in other contexts.

        {[
          (* Create colored string *)
          let msg = Spectrum.Simple.sprintf
              "@{<green>Success:@} %s" "Done" in
          print_endline msg
        ]}

        {[
          (* Build complex message *)
          let error_msg = Spectrum.Simple.sprintf
              "@{<red,bold>ERROR@} [@{<yellow>%s@}]: %s"
              "file.ml" "Syntax error" in
          prerr_endline error_msg
        ]}

        {[
          (* Compose messages *)
          let status = Spectrum.Simple.sprintf "@{<cyan>%d@}" 42 in
          let msg = Spectrum.Simple.sprintf
              "Items: %s @{<dim>(updated)@}" status in
          Printf.printf "%s\n" msg
        ]}

        {[
          (* Format for logging *)
          let log_message level msg =
            let colored = match level with
              | "ERROR" -> Spectrum.Simple.sprintf "@{<red>%s@}" msg
              | "WARN" -> Spectrum.Simple.sprintf "@{<yellow>%s@}" msg
              | "INFO" -> Spectrum.Simple.sprintf "@{<green>%s@}" msg
              | _ -> msg
            in
            Printf.printf "[%s] %s\n" level colored
          in
          log_message "ERROR" "Connection failed";
          log_message "INFO" "Server started"
        ]} *)
    val sprintf : ('a, Format.formatter, unit, string) format4 -> 'a
  end
end

(** Serializer module type - converts parsed tokens to ANSI escape codes. *)
module type Serializer = sig
  (** Convert a list of parsed style tokens into an ANSI escape code string. *)
  val to_code : Parser.token list -> string
end
