(** Color conversion utilities for terminal output.

    Provides functions to convert RGB colors to ANSI color codes using
    different quantization strategies. *)

(** Reference to the Palette module from spectrum_palette_ppx. *)
module Palette = Spectrum_palette_ppx.Palette

(** Extended Color module with additional types and conversion functions. *)
module Color : sig
  include module type of Color

  (** RGBA color type with integer components (0-255) and float alpha (0.0-1.0). *)
  module Rgba : sig
    type t = { r : int; g : int; b : int; a : float }
  end

  (** RGBA color type with float components (0.0-1.0). *)
  module Rgba' : sig
    type t = { r : float; g : float; b : float; a : float }
  end

  (** HSVA color type (Hue, Saturation, Value, Alpha). *)
  module Hsva : sig
    type t = { h : float; s : float; v : float; a : float }
  end

  (** Create a color from RGB integer values (0-255).

      {[
        let red = Color.of_rgb 255 0 0
      ]}

      @param r Red component (0-255)
      @param g Green component (0-255)
      @param b Blue component (0-255)
      @return Gg.v4 color *)
  val of_rgb : int -> int -> int -> Gg.v4

  (** Convert a color to RGBA with integer components (0-255).

      {[
        let color = Gg.Color.v_srgb 0.8 0.3 0.2 in
        let rgba = Spectrum_tools.Convert.Color.to_rgba color in
        Printf.printf "R:%d G:%d B:%d A:%.2f\n" rgba.r rgba.g rgba.b rgba.a
        (* Output: R:204 G:77 B:51 A:1.00 *)
      ]}

      @param color Color to convert
      @return RGBA record with integer components *)
  val to_rgba : Gg.v4 -> Rgba.t

  (** Convert a color to RGBA with float components (0.0-1.0).

      {[
        let color = Gg.Color.v_srgb 0.8 0.3 0.2 in
        let rgba' = Spectrum_tools.Convert.Color.to_rgba' color in
        Printf.printf "R:%.3f G:%.3f B:%.3f A:%.3f\n"
          rgba'.r rgba'.g rgba'.b rgba'.a
        (* Output: R:0.800 G:0.300 B:0.200 A:1.000 *)
      ]}

      @param color Color to convert
      @return RGBA record with float components *)
  val to_rgba' : Gg.v4 -> Rgba'.t

  (** Create a color from HSL values.

      {[
        (* Create yellow: hue=60°, full saturation, medium lightness *)
        let yellow = Spectrum_tools.Convert.Color.of_hsl 60. 100. 50. in
        let rgba = Spectrum_tools.Convert.Color.to_rgba yellow in
        Printf.printf "RGB(%d, %d, %d)\n" rgba.r rgba.g rgba.b
        (* Output: RGB(255, 255, 0) *)
      ]}

      {[
        (* Create a muted blue *)
        let muted_blue = Spectrum_tools.Convert.Color.of_hsl 210. 50. 60. in
        let rgba = Spectrum_tools.Convert.Color.to_rgba muted_blue in
        Printf.printf "RGB(%d, %d, %d)\n" rgba.r rgba.g rgba.b
      ]}

      @param h Hue in degrees (0-360)
      @param s Saturation (0-100)
      @param l Lightness (0-100)
      @return Gg.v4 color *)
  val of_hsl : float -> float -> float -> Gg.v4

  (** Convert a color to HSVA representation.

      {[
        let red = Gg.Color.v_srgb 1.0 0.0 0.0 in
        let hsva = Spectrum_tools.Convert.Color.to_hsva red in
        Printf.printf "H:%.1f S:%.1f V:%.1f A:%.2f\n"
          hsva.h hsva.s hsva.v hsva.a
        (* Output: H:0.0 S:100.0 V:100.0 A:1.00 *)
      ]}

      {[
        (* Convert an arbitrary color *)
        let color = Gg.Color.v_srgb 0.6 0.8 0.4 in
        let hsva = Spectrum_tools.Convert.Color.to_hsva color in
        Printf.printf "Hue: %.1f°\n" hsva.h
      ]}

      @param color Color to convert
      @return HSVA record with h (0-360), s (0-100), v (0-100), a (0.0-1.0) *)
  val to_hsva : Gg.v4 -> Hsva.t
end

(** Converter module type for RGB to ANSI color code conversion. *)
module type Converter = sig
  (** Convert RGB color to ANSI-256 color code (0-255).

      Uses perceptual color matching in LAB space to find the nearest
      xterm-256 palette color (codes 16-255, excluding basic 16 colors).

      {[
        (* Convert orange to nearest xterm-256 color *)
        let orange = Gg.Color.v_srgb 1.0 0.5 0.0 in
        let code = Perceptual.rgb_to_ansi256 orange in
        Printf.printf "\027[38;5;%dm■\027[0m Orange is code %d\n" code code
      ]}

      {[
        (* Find nearest color for a purple shade *)
        let purple = Gg.Color.v_srgb 0.6 0.2 0.8 in
        let code = Perceptual.rgb_to_ansi256 purple in
        Printf.printf "Purple maps to xterm-256 code: %d\n" code
      ]}

      {[
        (* Convert multiple colors *)
        let colors = [
          ("red", Gg.Color.v_srgb 0.9 0.1 0.1);
          ("green", Gg.Color.v_srgb 0.1 0.9 0.1);
          ("blue", Gg.Color.v_srgb 0.1 0.1 0.9);
        ] in
        List.iter (fun (name, color) ->
            let code = Perceptual.rgb_to_ansi256 color in
            Printf.printf "%s -> %d\n" name code
          ) colors
      ]}

      @param grey_threshold Optional threshold for grey detection (currently unused)
      @param color RGB color to convert
      @return ANSI-256 color code (16-255) *)
  val rgb_to_ansi256 : ?grey_threshold:int -> Gg.v4 -> int

  (** Convert RGB color to ANSI-16 basic color code (30-37, 90-97).

      Uses perceptual color matching in LAB space to find the nearest
      of the 16 basic ANSI colors.

      {[
        (* Convert red to nearest basic color *)
        let red = Gg.Color.v_srgb 0.9 0.1 0.1 in
        let code = Perceptual.rgb_to_ansi16 red in
        Printf.printf "\027[%dm■\027[0m Red is code %d\n" code code
        (* Likely maps to bright red: code 91 *)
      ]}

      {[
        (* Test basic vs bright color mapping *)
        let dark_green = Gg.Color.v_srgb 0.0 0.5 0.0 in
        let bright_green = Gg.Color.v_srgb 0.0 1.0 0.0 in

        let dark_code = Perceptual.rgb_to_ansi16 dark_green in
        let bright_code = Perceptual.rgb_to_ansi16 bright_green in

        Printf.printf "Dark green: %d, Bright green: %d\n"
          dark_code bright_code
        (* Dark: 32, Bright: 92 *)
      ]}

      {[
        (* Quantize a gradient to basic colors *)
        for i = 0 to 10 do
          let intensity = float_of_int i /. 10. in
          let color = Gg.Color.v_srgb intensity 0.0 0.0 in
          let code = Perceptual.rgb_to_ansi16 color in
          Printf.printf "\027[%dm■\027[0m " code
        done;
        print_newline ()
      ]}

      @param color RGB color to convert
      @return ANSI-16 color code (30-37, 90-97) *)
  val rgb_to_ansi16 : Gg.v4 -> int
end

(** Perceptual color converter using LAB color space for nearest-neighbor matching.

    This converter uses the CIE LAB color space to find the nearest terminal color,
    which provides better perceptual accuracy than Euclidean RGB distance. Colors
    that appear similar to humans will be numerically close in LAB space.

    The implementation delegates nearest-color search to the palette modules
    ({!Spectrum_palettes.Terminal.Basic} and {!Spectrum_palettes.Terminal.Xterm256}),
    which use octree-based spatial indexing in LAB space for efficient lookup.

    For ANSI-16 quantization, searches the full 16-color palette.
    For ANSI-256 quantization, searches only xterm codes 16-255 (color cube + greys),
    excluding basic codes 0-15. *)
module Perceptual : Converter
