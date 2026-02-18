(** Terminal color capability detection.

    {!Spectrum_capabilities} detects what level of color support a
    terminal provides, based on environment variables ([FORCE_COLOR],
    [COLORTERM], [TERM], [TERM_PROGRAM]), CI provider detection, and
    OS version information.

    {1 Quick Start}

    {[
      let levels = Spectrum_capabilities.Capabilities.supported_color_levels () in
      match levels.stdout with
      | True_color -> print_endline "Full 24-bit RGB"
      | Eight_bit -> print_endline "256-color xterm palette"
      | Basic -> print_endline "16-color ANSI"
      | Unsupported -> print_endline "No color support detected"
    ]}

    {1 Overriding Detection}

    Set the [FORCE_COLOR] environment variable to override auto-detection:

    - [FORCE_COLOR=0] or [false]: Unsupported
    - [FORCE_COLOR=1] or [true]: Basic (16 colors)
    - [FORCE_COLOR=2]: Eight_bit (256 colors)
    - [FORCE_COLOR=3]: True_color (24-bit RGB)

    {1 Standalone Usage}

    This package has no dependency on the rest of Spectrum. Use it
    independently when you only need to query terminal capabilities:

    {[
      let supports_color () =
        let levels = Spectrum_capabilities.Capabilities.supported_color_levels () in
        levels.stdout <> Unsupported
    ]}

    {1 Attribution}

    The detection heuristics are adapted from the
    {{:https://github.com/chalk/supports-color/} supports-color} library
    used by {{:https://github.com/chalk/chalk} Chalk} (JavaScript).

    {1 See Also}

    - {!Capabilities} for the full API
    - {{:https://github.com/anentropic/ocaml-spectrum} GitHub repository} *)

module Capabilities = Capabilities
