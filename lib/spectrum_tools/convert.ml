open Utils

(*
  the xterm 256 color palette is organised such that:

    0-15: the basic 'system' colours, RGB values of 0, 128, 255
      plus an extra grey of 192,192,192
    16-231: non-grey colours, RGB values of 0, 95, 135, 175, 215, 255
      so intervals of 40 with darkest interval missing and all offset +15
    232-255: greys in intervals of 10, offset and truncated to 8..238

  the non-grey colours are organised into 'rows', with the six values of
  the B component as columns - the rows start with R:0 and G:0,
  incrementing G for the current R before incrementing R.
  starting at 16: 0,0,0

  the 16 basic colours are organised as:
    0: 0,0,0
    1-6: combinations of 0,128
    7: 192,192,192
    8: 128,128,128
    9-14: combinations of 0,255 (symmetrical to 1-6)
    15: 255,255,255
*)

module type Converter = sig
  val rgb_to_ansi256 : Gg.v4 -> int
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


module Chalk : Converter = struct
  (*
    returns ANSI code of approximate nearest xterm 256 palette color
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

  (* returns the ansi code 'column' index of an ansi256 color value *)
  let quantize_256 i = int_round (i // 255 *. 5.)

  let rgb_to_ansi256 color_v4 =
    let color = Color.to_rgba color_v4 in
    (*
      The `>> 4` rshift sorts values into buckets of 16 width...
      but of course some values which are adjacent will sort into
      different buckets and won't be recognised as grey-like
      ...this probably doesn't matter much since there are also
      some pure greys in the general colours range
    *)
    if (
      (Int.shift_right color.r 4) == (Int.shift_right color.g 4) &&
      (Int.shift_right color.g 4) == (Int.shift_right color.b 4)
    ) then
      (*
        special case for grey-like colours
        the 232-255 code range is a 24 grey scale so we can get a closer match
      *)
      ansi256_grey_to_code color.r
    else
      (* general colours *)
      let r, g, b = map_color quantize_256 color in
      ansi256_columns_to_code r g b
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

let make_improved grey_threshold =
  let module M = struct
    (*
      Numerically we should sort into buckets of the half-way points, i.e.
      0-47    (0)
      48-114  (95)
      115-154 (135)
      155-194 (175)
      195-234 (215)
      235-255 (255)

      TODO: in theory binary search is faster, not really worth it for 6 values

      returns the ansi code 'column' index of an ansi256 color value
    *)
    let quantize_256 i =
      if i < 48 then 0
      else if i < 115 then 1
      else if i < 155 then 2
      else if i < 195 then 3
      else if i < 235 then 4
      else 5

    (*
      Attempts to fix the problems with the JS algorithm and
      give a more accurate mapping, but is it slower maybe?
    *)
    let rgb_to_ansi256 color_v4  =
      let color = Color.to_rgba color_v4 in
      if rgb_component_range color < grey_threshold then
        (*
          special case for grey-like colours
          the 232-255 code range is a 24 grey scale so we can get a closer match
        *)
        let avg = int_round ((color.r + color.g + color.b) // 3) in
        ansi256_grey_to_code avg
      else
        (* general colours *)
        let r, g, b = map_color quantize_256 color in
        ansi256_columns_to_code r g b
  end in
  (module M : Converter)

module Improved = (val (make_improved 32) : Converter)


let make_perceptual grey_threshold =
  let module M = struct

    (*
      See https://stackoverflow.com/a/1678481/202168
      This is the euclidian distance in LAB space
    *)
    let perceptual_distance rgb_a rgb_b =
      Gg.V4.sub (Gg.Color.to_lab rgb_a) (Gg.Color.to_lab rgb_b)
      |> Gg.V4.norm

    let ansi256_colour_values = IntAdjacencySet.of_list [
        0; 95; 135; 175; 215; 255
      ]
    let ansi256_grey_values = IntAdjacencySet.of_list [
        0; 8; 18; 28; 38; 48; 58; 68; 78; 88; 98;
        108; 118; 128; 138; 148; 158; 168; 178; 188; 198;
        208; 218; 228; 238; 255
      ]
    (*
      takes a component intensity 0..255 and returns the two adjacent values
      above+below from the ANSI palette base values 0, 95, 135, 175, 215, 255
    *)
    let adjacent_ansi256_components = IntAdjacencySet.adjacent_values_exn ansi256_colour_values
    (* same but for the ANSI greyscale palette *)
    let adjacent_ansi256_grey_values = IntAdjacencySet.adjacent_values_exn ansi256_grey_values

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

    type candidate = ANSIColor of Gg.v4 | ANSIGrey of Gg.v4
    let v4_of_candidate = function
      | ANSIColor x -> x
      | ANSIGrey x -> x

    (* generate every combination of the above/below adjacent RGB values *)
    let adjacent_ansi256_colors color_v4 =
      let color = Color.to_rgba color_v4 in
      let r', g', b' = map_color adjacent_ansi256_components color in
      let rgb_tuples = product3 r' g' b' in
      List.map (fun (r, g, b) -> ANSIColor (Color.of_rgb r g b)) rgb_tuples

    let adjacent_ansi256_greys color_v4 =
      let color = Color.to_rgba color_v4 in
      let l' = adjacent_ansi256_grey_values (to_greyscale color) in
      List.map (fun (l) -> ANSIGrey (Color.of_rgb l l l)) l'

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
      | i -> raise (Failure (Printf.sprintf "Invalid value: %d" i))

    let rgb_to_ansi256 color_v4 =
      (* if the colour is close to grey, include greyscale candidates too *)
      let candidates = match rgb_component_range (Color.to_rgba color_v4) < grey_threshold with
        | true -> adjacent_ansi256_colors color_v4 @ adjacent_ansi256_greys color_v4
        | false -> adjacent_ansi256_colors color_v4
      in
      (* find candidate with the closest perceptual distance *)
      let candidate_distances = List.map (fun candidate ->
          let distance = perceptual_distance color_v4 (v4_of_candidate candidate) in
          (distance, candidate)
        ) @@ candidates
      and init = (255., ANSIColor Color.black) in
      let (_, candidate) = List.fold_left min init candidate_distances in
      let color = Color.to_rgba (v4_of_candidate candidate) in
      match candidate with
      | ANSIColor _ ->
        let r, g, b = map_color ansi256_component_to_column color in
        ansi256_columns_to_code r g b
      | ANSIGrey _ -> ansi256_grey_to_code color.r
  end in
  (module M : Converter)

module Perceptual = (val (make_perceptual 32) : Converter)
