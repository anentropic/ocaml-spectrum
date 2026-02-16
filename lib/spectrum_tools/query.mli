(** Terminal color querying utilities.

    Provides functions to query xterm-compatible terminals for their current
    foreground and background colors using xterm control sequences. *)

(** Terminal foreground and background colors. *)
type terminal_colours = {
  fg : (Gg.v4, string) result;  (** Foreground color or error message *)
  bg : (Gg.v4, string) result;  (** Background color or error message *)
}

(** Xterm-compatible terminal query functions. *)
module Xterm : sig
  (** Set terminal to raw mode for direct input/output.

      Configures the terminal for raw mode where input is not line-buffered
      and special characters are not processed. This is necessary for reading
      terminal query responses.

      {b Warning:} This modifies terminal settings. Always restore original
      settings using {!Unix.tcsetattr} or use the {!query} function which
      handles this automatically.

      @param set_when When to apply the settings (default: TCSAFLUSH)
      @param fd File descriptor to configure *)
  val set_raw : ?set_when:Unix.setattr_when -> Unix.file_descr -> unit

  (** Query terminal using xterm control codes.

      Sends an xterm OSC (Operating System Command) query to the terminal
      and reads the response. The terminal must support xterm control sequences.

      Common control codes:
      - "10" - Query foreground color
      - "11" - Query background color

      {[
        (* Query foreground color *)
        match Spectrum_tools.Query.Xterm.query Unix.stdin "10" with
        | Ok response ->
          Printf.printf "Foreground color response: %s\n" response
        (* Example: "rgb:ffff/ffff/ffff" for white *)
        | Error msg ->
          Printf.printf "Query failed: %s\n" msg
      ]}

      {[
        (* Query background color *)
        match Spectrum_tools.Query.Xterm.query Unix.stdin "11" with
        | Ok response -> Printf.printf "Background: %s\n" response
        | Error msg -> Printf.eprintf "Error: %s\n" msg
      ]}

      {[
        (* Query both colors in sequence *)
        let query_colors () =
          match Spectrum_tools.Query.Xterm.query Unix.stdin "10" with
          | Ok fg_response ->
            Printf.printf "FG: %s\n" fg_response;
            (match Spectrum_tools.Query.Xterm.query Unix.stdin "11" with
             | Ok bg_response -> Printf.printf "BG: %s\n" bg_response
             | Error e -> Printf.eprintf "BG error: %s\n" e)
          | Error e -> Printf.eprintf "FG error: %s\n" e
      ]}

      @param fd File descriptor to query (must be a TTY)
      @param code Control code to query
      @return Result with terminal response string or error message *)
  val query : Unix.file_descr -> string -> (string, string) result

  (** Convert hexadecimal string to 8-bit integer (0-255) with scaling.

      Translates a hexadecimal string of any width to an 8-bit int.
      The value is scaled according to the number of hex characters,
      where each character represents 4 bits.

      {[
        (* Single hex digit scales to 8-bit *)
        let result = Spectrum_tools.Query.Xterm.hex_to_8bit "C" in
        Printf.printf "C -> %d\n" result
        (* Output: C -> 204 *)
      ]}

      {[
        (* Two hex digits *)
        let result = Spectrum_tools.Query.Xterm.hex_to_8bit "C3" in
        Printf.printf "C3 -> %d\n" result
        (* Output: C3 -> 195 *)
      ]}

      {[
        (* Four hex digits (16-bit terminal response) *)
        let result = Spectrum_tools.Query.Xterm.hex_to_8bit "CCCC" in
        Printf.printf "CCCC -> %d\n" result
        (* Output: CCCC -> 204 *)
      ]}

      {[
        (* Parse all components from terminal response *)
        let parse_rgb_components r g b =
          let r8 = Spectrum_tools.Query.Xterm.hex_to_8bit r in
          let g8 = Spectrum_tools.Query.Xterm.hex_to_8bit g in
          let b8 = Spectrum_tools.Query.Xterm.hex_to_8bit b in
          Printf.printf "RGB(%d, %d, %d)\n" r8 g8 b8
        in
        parse_rgb_components "FFFF" "8080" "4040"
        (* Output: RGB(255, 128, 64) *)
      ]}

      @param s Hexadecimal string (without "0x" prefix)
      @return Scaled 8-bit integer (0-255) *)
  val hex_to_8bit : string -> int

  (** Parse xterm RGB color string.

      Parses terminal query responses in xterm's 48-bit RGB format:
      "rgb:RRRR/GGGG/BBBB" where each component is 1-4 hex digits.

      {[
        (* Parse a typical terminal response *)
        match Spectrum_tools.Query.Xterm.parse_colour "rgb:c3c3/b0b0/9090" with
        | Ok color ->
          let rgba = Spectrum_tools.Convert.Color.to_rgba color in
          Printf.printf "Parsed: RGB(%d, %d, %d)\n" rgba.r rgba.g rgba.b
        (* Output: Parsed: RGB(195, 176, 144) *)
        | Error msg ->
          Printf.printf "Parse error: %s\n" msg
      ]}

      {[
        (* Parse white *)
        match Spectrum_tools.Query.Xterm.parse_colour "rgb:ffff/ffff/ffff" with
        | Ok color ->
          let rgba = Spectrum_tools.Convert.Color.to_rgba color in
          Printf.printf "White: RGB(%d, %d, %d)\n" rgba.r rgba.g rgba.b
        (* Output: White: RGB(255, 255, 255) *)
        | Error _ -> ()
      ]}

      {[
        (* Handle parse errors *)
        let test_strings = [
          "rgb:ffff/ffff/ffff";  (* valid *)
          "rgb:ff/ff/ff";        (* valid, shorter format *)
          "not a color";         (* invalid *)
        ] in
        List.iter (fun s ->
            match Spectrum_tools.Query.Xterm.parse_colour s with
            | Ok _ -> Printf.printf "%s: valid\n" s
            | Error msg -> Printf.printf "%s: %s\n" s msg
          ) test_strings
      ]}

      {[
        (* Extract from terminal response *)
        let response = "\027]10;rgb:d0d0/d0d0/d0d0\007" in
        (* Extract just the RGB part *)
        let rgb_part = "rgb:d0d0/d0d0/d0d0" in
        match Spectrum_tools.Query.Xterm.parse_colour rgb_part with
        | Ok color -> Printf.printf "Foreground color parsed\n"
        | Error e -> Printf.eprintf "Error: %s\n" e
      ]}

      @param s Color string from terminal query response
      @return Result with parsed color or error message *)
  val parse_colour : string -> (Gg.v4, string) result

  (** Get current terminal foreground and background colors.

      Queries the terminal for both foreground (OSC 10) and background (OSC 11)
      colors and parses the responses.

      {[
        (* Query terminal colors *)
        let colours = Spectrum_tools.Query.Xterm.get_colours Unix.stdin in

        match colours.fg with
        | Ok fg_color ->
          let rgba = Spectrum_tools.Convert.Color.to_rgba fg_color in
          Printf.printf "Foreground: RGB(%d, %d, %d)\n" rgba.r rgba.g rgba.b
        | Error msg ->
          Printf.printf "Failed to detect foreground: %s\n" msg;

          match colours.bg with
          | Ok bg_color ->
            let rgba = Spectrum_tools.Convert.Color.to_rgba bg_color in
            Printf.printf "Background: RGB(%d, %d, %d)\n" rgba.r rgba.g rgba.b
          | Error msg ->
            Printf.printf "Failed to detect background: %s\n" msg
      ]}

      {[
        (* Check if terminal has dark or light background *)
        let colours = Spectrum_tools.Query.Xterm.get_colours Unix.stdin in
        match colours.bg with
        | Ok bg_color ->
          let rgba' = Spectrum_tools.Convert.Color.to_rgba' bg_color in
          let brightness = (rgba'.r +. rgba'.g +. rgba'.b) /. 3. in
          if brightness < 0.5 then
            Printf.printf "Dark background detected\n"
          else
            Printf.printf "Light background detected\n"
        | Error _ ->
          Printf.printf "Could not determine background\n"
      ]}

      {[
        (* Calculate contrast ratio *)
        let colours = Spectrum_tools.Query.Xterm.get_colours Unix.stdin in
        match colours.fg, colours.bg with
        | Ok fg, Ok bg ->
          let fg_rgba = Spectrum_tools.Convert.Color.to_rgba' fg in
          let bg_rgba = Spectrum_tools.Convert.Color.to_rgba' bg in
          let fg_luma = 0.299 *. fg_rgba.r +. 0.587 *. fg_rgba.g +. 0.114 *. fg_rgba.b in
          let bg_luma = 0.299 *. bg_rgba.r +. 0.587 *. bg_rgba.g +. 0.114 *. bg_rgba.b in
          let contrast = abs_float (fg_luma -. bg_luma) in
          Printf.printf "Contrast: %.2f\n" contrast
        | _ ->
          Printf.printf "Could not calculate contrast\n"
      ]}

      @param fd File descriptor to query (typically Unix.stdin)
      @return Record with fg and bg colors (or error messages) *)
  val get_colours : Unix.file_descr -> terminal_colours
end
