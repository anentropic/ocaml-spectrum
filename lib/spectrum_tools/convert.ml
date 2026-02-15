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

let map_color f (color : Color.Rgba.t) = (f color.r), (f color.g), (f color.b)
let map_color' f (color : Color.Rgba'.t) = (f color.r), (f color.g), (f color.b)


(* takes R,G,B 'column' values for one of the ANSI colours
   and returns the corresponding ANSI code point *)
let ansi256_columns_to_code r g b = 16 + (r * 36) + (g * 6) + b

(* takes 0..255 luminance value and returns nearest ANSI grey code *)
let ansi256_grey_to_code l =
  if l < 8 then
    16  (* black *)
  else if l > 248 then
    231 (* white *)
  else
    int_round ((l - 8) // 247 *. 24.) + 232

(*
  takes float RGB 0..1 color and returns 0..7 index
  can be transformed to one of the base 16 colour codes:
  30..37 regular intensity (fg)
  40..47 regular (bg)
  90..97 bright (fg)
  100..107 bright (bg)
*)
let to_ansi16_row (color : Color.Rgba'.t) =
  Int.shift_left (int_round color.b) 2
  lor
  Int.shift_left (int_round color.g) 1
  lor
  int_round color.r

(*
  A close translation of the algorithms used by Chalk.js, which comes from:
  https://github.com/Qix-/color-convert/blob/master/conversions.js

  It is computationally simplest of the three converters, however it has
  some inaccuracies in how colours are downsampled.
*)
module Chalk : Converter = struct
  (*
    Returns ANSI code of approximate nearest xterm 256 palette color
    for the given RGB color value.

    This is a port of the algorithm used by Chalk.js, coming from:
    https://github.com/Qix-/color-convert/blob/master/conversions.js#L546

    Problem:
      (color.r // 255 *. 5.)

    ...this treats the colour range as if it is evenly divided, but the
    target values 0,95,135,175,215,255 are skewed towards the bright end

    this explains why it gives:
        rgb_to_ansi256([80, 80, 200]) -> 104  // rgb(135, 135, 215)
    despite the original R value 80 is closer to a target of 95

    Also note that in some cases there may be one of the 16 basic colors
    that is a closer match, but this will never return them.
  *)
  let rgb_to_ansi256 ?(grey_threshold=16) color_v4 =
    let color = Color.to_rgba color_v4 in
    let shift cval = Int.shift_right cval (nearest_sqrt grey_threshold) in
    (*
      The `>> 4` rshift sorts values into buckets of 16 width...
      So this identifies 'grey-like' colours where r,g,b are all in the same
      bucket. But of course some values which are adjacent will sort into
      different buckets and then it won't be recognised as grey-like.
      ...this probably doesn't matter too much in practice since there are
      also some pure greys in the general colours range
    *)
    if (
      (shift color.r) == (shift color.g) &&
      (shift color.g) == (shift color.b)
    ) then
      (*
        special case for grey-like colours
        the 232-255 code range is a 24 tone greyscale so we can get a closer
        match than with the greys in the general colour range
      *)
      ansi256_grey_to_code color.r
    else
      (* general colours *)
      let r, g, b = map_color (fun i ->
          int_round (i // 255 *. 5.)
        ) color in
      ansi256_columns_to_code r g b

  (*
    their method uses HSV, which is similar to HSL
    in HSL, L is "lightness" and max L means white
    in HSV, V is "value" and it interacts with saturation so that:
    - max S, max V == max S, 0.5 L (in HSL) i.e. fully saturated bright colour
    - min S, max V == white
    - min V == black

    so `let value = saturation` is a bit odd, but in the usual case they
    will rgb -> hsv and take the V

    V is a 0..100 scale

    NOTE:
    this is using a different escape code to the xterm256 ones:
    https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
    but the colours are the same as codes 0..15 in the 256 palette

    there are two ranges 30..37 and 90..97
    being the std and bright colours respectively
    code 30 == black

    and if V >= 75% (i.e. squashed value == 2) then shift into the 'bright' range

    NOTE:
    these are 'foreground' codes
  *)
  let rgb_to_ansi16 color_v4 =
    let rgb' = Color.to_rgba' color_v4
    and hsv = Color.to_hsva color_v4 in
    let value = Float.round @@ hsv.v /. 50. in
    match value with
    | 0. -> 30  (* if V < 25%, squash to black *)
    | 2. -> 90 + (to_ansi16_row rgb')  (* if V >= 75%, shift to bright *)
    | _  -> 30 + (to_ansi16_row rgb')  (* regular *)
end

(*
  a measure of the "un-grey-ness" of [colour]
  returns a value in range 0..255, where 0 is pure grey

  measures overall colour channel dissimilarity rather than
  sorting into buckets
*)
let rgb_component_range (color : Color.Rgba.t) =
  max3
    (abs (color.r - color.g))
    (abs (color.r - color.b))
    (abs (color.g - color.b))

(*
  This sticks closely to the Chalk.js algorithm but has a more accurate
  mapping to the ANSI palette by:
  - grey-like colour detection by avg intensity rather than bit shift buckets
  - non-grey-like colours quantized to their actual nearest ANSI target
    (though again colours in the 1-16 basic range are not used as targets)

  This may be marginally slower than the original but is still pretty simple.
*)
module ImprovedChalk : Converter = struct
  (*
    Numerically we should sort into buckets of built around the half-way points
    between each target value, i.e.
      0-47    (0)
      48-114  (95)
      115-154 (135)
      155-194 (175)
      195-234 (215)
      235-255 (255)
    from the bucket index for each component we can derive the ansi code
  *)
  let quantized_bucket i =
    if i < 48 then 0
    else if i < 115 then 1
    else if i < 155 then 2
    else if i < 195 then 3
    else if i < 235 then 4
    else 5

  let rgb_to_ansi256 ?(grey_threshold=32) color_v4  =
    let color = Color.to_rgba color_v4 in
    if rgb_component_range color < grey_threshold then
      (*
        special case for grey-like colours
        the 232-255 code range is a 24 tone greyscale so we can get a closer
        match than with the greys in the general colour range
      *)
      let avg = int_round ((color.r + color.g + color.b) // 3) in
      ansi256_grey_to_code avg
    else
      (* general colours *)
      let r, g, b = map_color quantized_bucket color in
      ansi256_columns_to_code r g b

  let rgb_to_ansi16 = Chalk.rgb_to_ansi16
end

(*
  The [ImprovedChalk] converter above should return numerically closest match.

  For perceptual matching we delegate nearest-colour search to the shared
  `spectrum_palettes` modules, which expose [nearest] backed by an octree
  built in LAB space (see spectrum_palette_ppx/palette.ml).

  For ANSI-16 we search the full 16-colour palette.
  For ANSI-256 we preserve historical behaviour by searching only xterm
  codes 16..255 (colour cube + greys), excluding basic codes 0..15.

  TODO:
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