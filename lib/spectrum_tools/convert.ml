open Utils

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
          let rdiff, gdiff, bdiff = map_color' diffc c in
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
module Improved : Converter = struct
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
  The [Improved] converter above should return numerically closest match.

  However when researching palette quantization we find that there are
  some algorithms that aim to provide 'perceptually' closest matches.

  The key one is to compare colours via their Euclidian distance in the
  LAB colour space. So for this converter we first find all the likely
  target candidates in the ANSI palette, then return the closest measured
  via that method.
*)
module Perceptual : Converter = struct
  (*
    See https://stackoverflow.com/a/1678481/202168
    This is the Euclidian distance in LAB space
  *)
  let perceptual_distance rgb_a rgb_b =
    Gg.V4.sub (Gg.Color.to_lab rgb_a) (Gg.Color.to_lab rgb_b)
    |> Gg.V4.norm

  (*
    TODO: this hack doesn't work with custom palettes as there is no guarantee
    the RGB components are all quantized to the same, or any, set of values

    The downward quantizations for every color could be statially calculated
    as a big switch in the generated palette module
  *)
  let ansi256_colour_values = IntAdjacencySet.of_list [
      0; 95; 135; 175; 215; 255
    ]

  (*
    TODO: these are found at the end of 256-colors.json, with names
    approximately their luminance value (i.e. "Grey46" is l:46, though
    there are some discrepancies)

    One idea would be to extract all the true greys from the custom palette
    and build this list from their values.
  *)
  let ansi256_grey_values = IntAdjacencySet.of_list [
      0; 8; 18; 28; 38; 48; 58; 68; 78; 88; 98;
      108; 118; 128; 138; 148; 158; 168; 178; 188; 198;
      208; 218; 228; 238; 255
    ]

  let adjacent = IntAdjacencySet.adjacent_values_exn

  (*
    a perceptual color -> greyscale conversion
    a.k.a. the "weighted" or "luminosity" method
    https://www.dynamsoft.com/blog/insights/image-processing/image-processing-101-color-space-conversion/
    https://www.tutorialspoint.com/dip/grayscale_to_rgb_conversion.htm
  *)
  let to_greyscale (color: Color.Rgba.t) =
    let r, g, b = map_color float_of_int color in
    (0.299 *. r) +. (0.587 *. g) +. (0.114 *. b)
    |> int_round
    |> clamp 0 255

  type candidate =
    | ANSI256Color of Gg.v4
    | ANSI256Grey of Gg.v4
    | ANSI16 of Gg.v4

  let v4_of_candidate = function
    | ANSI256Color x -> x
    | ANSI256Grey x -> x
    | ANSI16 x -> x

  (* generate every combination of the above/below adjacent RGB values *)
  let adjacent_colors values_f color_v4 =
    let color = Color.to_rgba color_v4 in
    let r', g', b' = map_color values_f color in
    let rgb_tuples = product3 r' g' b' in
    List.map (fun (r, g, b) -> ANSI256Color (Color.of_rgb r g b)) rgb_tuples

  let adjacent_greys values_f color_v4 =
    let color = Color.to_rgba color_v4 in
    let l' = values_f (to_greyscale color) in
    List.map (fun (l) -> ANSI256Grey (Color.of_rgb l l l)) l'

  (*
    TODO: these values are configurable in most terminals, for defaults see
    see https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
    ...according to that these are actually the Windows basic palette
    (which also corresponds to 1-16 of the Xterm-256 palette, but not the
    default Xterm basic palette according to above)
    ...we should allow specifying different palettes?

    TODO: these are also defined in parser.ml & spectrum_palette/16-colors.json
    we should derive these function from the 
  *)
  let ansi16_colors = [
    ANSI16 (Color.of_rgb   0   0   0);
    ANSI16 (Color.of_rgb 128   0   0);
    ANSI16 (Color.of_rgb   0 128   0);
    ANSI16 (Color.of_rgb 128 128   0);
    ANSI16 (Color.of_rgb   0   0 128);
    ANSI16 (Color.of_rgb 128   0 128);
    ANSI16 (Color.of_rgb   0 128 128);
    ANSI16 (Color.of_rgb 192 192 192);
    ANSI16 (Color.of_rgb 128 128 128);
    ANSI16 (Color.of_rgb 255   0   0);
    ANSI16 (Color.of_rgb   0 255   0);
    ANSI16 (Color.of_rgb 255 255   0);
    ANSI16 (Color.of_rgb   0   0 255);
    ANSI16 (Color.of_rgb 255   0 255);
    ANSI16 (Color.of_rgb   0 255 255);
    ANSI16 (Color.of_rgb 255 255 255);
  ]

  let rgb_to_ansi16_code = function
    |   0,   0,   0 -> 30
    | 128,   0,   0 -> 31
    |   0, 128,   0 -> 32
    | 128, 128,   0 -> 33
    |   0,   0, 128 -> 34
    | 128,   0, 128 -> 35
    |   0, 128, 128 -> 36
    | 192, 192, 192 -> 37
    | 128, 128, 128 -> 90
    | 255,   0,   0 -> 91
    |   0, 255,   0 -> 92
    | 255, 255,   0 -> 93
    |   0,   0, 255 -> 94
    | 255,   0, 255 -> 95
    |   0, 255, 255 -> 96
    | 255, 255, 255 -> 97
    | _ -> invalid_arg "Not in ANSI 16-color palette"


  (*
    for RGB color values 0..255 -> 'column' index in the ANSI colours set
    (exact match only - values must be already quantized)
  *)
  let ansi256_component_to_column = function
    | 0 -> 0
    | 95 -> 1
    | 135 -> 2
    | 175 -> 3
    | 215 -> 4
    | 255 -> 5
    | i -> raise @@ Failure (Printf.sprintf "Invalid value: %d" i)

  let nearest_candidate color_v4 candidates =
    (* find candidate with the closest perceptual distance *)
    let candidate_distances = List.map (fun candidate ->
        let distance = perceptual_distance color_v4 (v4_of_candidate candidate) in
        (distance, candidate)
      ) @@ candidates
    and init = (255., ANSI16 Color.black) in
    let (_, candidate) = List.fold_left min init candidate_distances in
    candidate

  let code_of_candidate candidate =
    let color = Color.to_rgba (v4_of_candidate candidate) in
    match candidate with
    | ANSI256Color _ ->
      let r, g, b = map_color ansi256_component_to_column color in
      ansi256_columns_to_code r g b
    | ANSI256Grey _ -> ansi256_grey_to_code color.r
    | ANSI16 _ -> rgb_to_ansi16_code @@ (color.r, color.g, color.b)

  (* NOTE: does not target the 1-16 basic colours either *)
  let rgb_to_ansi256 ?(grey_threshold=64) color_v4 =
    (* if the colour is close to grey, include greyscale candidates too *)
    let candidates = match rgb_component_range (Color.to_rgba color_v4) < grey_threshold with
      | true ->
        adjacent_colors (adjacent ansi256_colour_values) color_v4
        @ adjacent_greys (adjacent ansi256_grey_values) color_v4
      | false -> adjacent_colors (adjacent ansi256_colour_values) color_v4
    in
    nearest_candidate color_v4 candidates
    |> code_of_candidate

  let rgb_to_ansi16 color_v4 =
    nearest_candidate color_v4 ansi16_colors
    |> code_of_candidate

end