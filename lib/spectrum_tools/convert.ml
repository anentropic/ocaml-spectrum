open Utils

module Palette = Spectrum_palette_ppx.Palette

(*
  What we call "ansi256" here are the xterm 256 color palette
  i.e. colours set by using the ESC[38;5;<code>m sequence

  The palette is organised such that:

    0-15: the basic 'system' colours, RGB values of 0, 128, 255
      plus an extra grey of 192,192,192
    16-231: non-grey colours, RGB values of 0, 95, 135, 175, 215, 255
      so intervals of 40 with darkest interval missing and all offset +15
    232-255: greys in intervals of 10, offset and truncated to 8..238

  The non-grey colours are organised into 'rows', with the six values of
  the B component as columns - the rows start with R:0 and G:0,
  incrementing G for the current R before incrementing R.
  starting at 16: 0,0,0

  The 16 basic colours are organised as:
    0: 0,0,0
    1-6: combinations of 0,128
    7: 192,192,192
    8: 128,128,128
    9-14: combinations of 0,255 (symmetrical to 1-6)
    15: 255,255,255

  NOTE: there are no 128+255 combinations, only 0+128 and 0+255

  (RGB values according to https://www.ditig.com/256-colors-cheat-sheet)

  but terminals are configurable and Wikipedia shows different apps
  choose different defaults for the 16 colour base palette:
  https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
*)

(* extend Color *)
module Color = struct
  include Color

  module Rgba = struct
    type t = { r : int; g : int; b : int; a : float }
  end

  module Rgba' = struct
    type t = { r : float; g : float; b : float; a : float }
  end

  let of_rgb r g b = Rgb.(v r g b |> to_gg)

  let to_rgba color =
    let c = Gg.Color.to_srgb color in
    {
      Rgba.r = int_of_float (Float.round (255. *. Gg.Color.r c));
      g = int_of_float (Float.round (255. *. Gg.Color.g c));
      b = int_of_float (Float.round (255. *. Gg.Color.b c));
      a = Gg.Color.a c;
    }

  let to_rgba' color =
    let c = Gg.Color.to_srgb color in
    {
      Rgba'.r = Gg.Color.r c;
      g = Gg.Color.g c;
      b = Gg.Color.b c;
      a = Gg.Color.a c;
    }

  let of_hsl h s l = Hsl.(v h s l |> to_gg)

  module Hsva = struct
    type t = {h: float; s: float; v: float; a: float}
  end

  (*
    https://github.com/Qix-/color-convert/blob/master/conversions.js#L94
  *)
  let to_hsva color_v4 : Hsva.t =
    let c = to_rgba' color_v4 in
    let v = max3 c.r c.g c.b in
    let diff = v -. (min3 c.r c.g c.b) in
    let diffc c' = (v -. c') /. 6. /. (diff +. 1.) /. 2. in
    let h, s = match diff with
      | 0. -> 0., 0.
      | _ -> begin
          let rdiff = diffc c.r
          and gdiff = diffc c.g
          and bdiff = diffc c.b in
          let s = diff /. v in
          let h =
            if c.r == v then
              bdiff -. gdiff
            else if c.g == v then
              (1. /. 3.) +. rdiff -. bdiff
            else
              (2. /. 3.) +. gdiff -. rdiff
          in
          let h =
            if h < 0. then
              h +. 1.
            else if h > 1. then
              h -. 1.
            else
              h
          in
          h, s
        end
    in
    {
      h = h *. 360.;
      s = s *. 100.;
      v = v *. 100.;
      a = 1.;
    }
end

module type Converter = sig
  val rgb_to_ansi256 : ?grey_threshold:int -> Gg.v4 -> int
  val rgb_to_ansi16 : Gg.v4 -> int
end


(*
  For perceptual matching we delegate nearest-colour search to the shared
  `spectrum_palettes` modules, which expose [nearest] backed by an octree
  built in LAB space (see spectrum_palette_ppx/palette.ml).

  For ANSI-16 we search the full 16-colour palette.
  For ANSI-256 we preserve historical behaviour by searching only xterm
  codes 16..255 (colour cube + greys), excluding basic codes 0..15.

  Idea:
  Possibly the 'OKLab' colourspace is even better for perceptual matching
  See: https://meat.io/oksolar
  https://bottosson.github.io/posts/oklab/
  ...but for now it's convenient that Gg already provides LAB conversion
*)
module Perceptual : Converter = struct
  module Ansi16_palette = Spectrum_palettes.Terminal.Basic

  module Ansi256_palette = Spectrum_palettes.Terminal.Xterm256

  (* Match historical behaviour: ansi256 conversion targets xterm codes 16-255
     (colour cube + greys), not the basic 0-15 ANSI colours. *)
  let ansi256_target_colors =
    List.filteri (fun i _ -> i >= 16) Ansi256_palette.color_list

  let ansi256_nearest = Palette.nearest_of_list ansi256_target_colors

  let index_of_color_exn colors target ~msg =
    let rec find_index i = function
      | [] -> invalid_arg msg
      | c :: rest ->
        if c = target then i else find_index (i + 1) rest
    in
    find_index 0 colors

  let rgb_to_ansi16_code (r, g, b) =
    (* Find the matching color in the palette and return its code *)
    let target = Color.of_rgb r g b in
    let i =
      index_of_color_exn
        Ansi16_palette.color_list
        target
        ~msg:"Not in ANSI 16-color palette"
    in
    if i < 8 then 30 + i else 90 + (i - 8)

  let rgb_to_ansi256 ?grey_threshold:_ color_v4 =
    let i =
      ansi256_nearest color_v4
      |> index_of_color_exn
        ansi256_target_colors
        ~msg:"Not in ANSI 256-color target palette"
    in
    i + 16

  let rgb_to_ansi16 color_v4 =
    Ansi16_palette.nearest color_v4
    |> Color.to_rgba
    |> fun c -> rgb_to_ansi16_code (c.r, c.g, c.b)

end